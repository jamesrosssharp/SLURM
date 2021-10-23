/*
 *	Background renderer
 *
 *  Fixed tile size 16x16 - 256 16x16x4bpp tiles will fit in a 32kB SPRAM
 *
 */

module background_controller2
 #(
	parameter H_START = 10'd48,
	parameter H_END   = 10'd320,
	parameter V_START = 10'd33,
	parameter V_END   = 10'd513

) (
	input  CLK,
	input  RSTb,

	input  [3:0] ADDRESS,
	input  [15:0] DATA_IN,
	input  WR,

	/* single cycle tick when vertical count is zero */
	input V_tick,
	/* single cycle tick horizontal count is zero */
	input H_tick,

	/* display uses this channel to read scanline block RAM */
	input [9:0]   display_x,
	input [9:0]   display_y,
	input         re,	// render enable
	output [7:0] color_index,

	/* memory channel to memory arbiter */
	output [15:0] memory_address,
	input  [15:0] memory_data,
	output rvalid, // memory address valid
	input  rready  // memory data valid

);

// Memory interface

reg bg_enable;
reg bg_enable_next;

reg [1:0] tilemap_stride;
reg [1:0] tilemap_stride_next;

reg tile_set_stride;
reg tile_set_stride_next;

reg [15:0] tile_map_x;
reg [15:0] tile_map_x_next;

reg [15:0] tile_map_y;
reg [15:0] tile_map_y_next;

reg [15:0] tile_map_address;
reg [15:0] tile_map_address_next;

reg [15:0] tile_set_address;
reg [15:0] tile_set_address_next;

reg [3:0] pal_hi;
reg [3:0] pal_hi_next;

// Scanline buffers

genvar j;

reg [9:0]  scanline_rd_addr[1:0];
reg [9:0]  scanline_wr_addr[1:0];
wire [3:0] scanline_rd_data[1:0];
reg [3:0]  scanline_wr_data[1:0];
reg scanline_wr[1:0];
reg active_buffer;
wire display_buffer = !active_buffer;
reg active_buffer_next;

assign color_index = {pal_hi, scanline_rd_data[display_buffer]};

generate 
for (j = 0; j < 2; j = j + 1)
begin:	scanline_buffers bram #(.BITS(4), .ADDRESS_BITS(10)) br_inst
(
	CLK,
	scanline_rd_addr[j],
	scanline_rd_data[j],
	scanline_wr_addr[j],
	scanline_wr_data[j],
	scanline_wr[j]
);
end
endgenerate


// Fetch / blit

reg cur_fetch_buffer; // we double buffer the shift register so we can be fetching 
reg cur_fetch_buffer_next;

wire cur_blit_buffer = ! cur_fetch_buffer;
reg [63:0] fetch_buffer[1:0]; // shift register
reg blit_go; // signal to blitter to start blitting

reg [20:0] tilemap_index_r;
reg [20:0] tilemap_index_r_next;

reg [15:0] memory_address_r;
reg [15:0] memory_address_r_next;
reg rvalid_r;

assign memory_address = memory_address_r;
assign rvalid = rvalid_r;

localparam f_idle 			 = 3'd0;
localparam f_begin			 = 3'd1;
localparam f_fetch_tile 	 = 3'd2;
localparam f_wait_tile_mem   = 3'd3;
localparam f_fetch_tile_data = 3'd4;
localparam f_wait_td_mem     = 3'd5;
localparam f_wait_blitter    = 3'd6;

reg [2:0] f_state_r;
reg [2:0] f_state_r_next;

// Fetcher process: fetch tile pixels into a 64 bit shift register


// Blitter process: blit from shift register to block RAM



// Read out scanline buffer

always @(*)
begin
	scanline_rd_addr[0]  = 10'd0;
 	scanline_rd_addr[1]  = 10'd0;
  	
	scanline_rd_addr[active_buffer]  = 10'd0;
  	scanline_rd_addr[display_buffer] = display_x;
end

// Register interface to CPU

always @(*)
begin

	bg_enable_next 		  = bg_enable;
	tilemap_stride_next   = tilemap_stride;
	tile_set_stride_next  = tile_set_stride;
	tile_map_x_next 	  = tile_map_x;
	tile_map_y_next 	  = tile_map_y;
	tile_map_address_next = tile_map_address;
	tile_set_address_next = tile_set_address;
	pal_hi_next 		  = pal_hi;	

	if (WR == 1'b1)
	begin
		case (ADDRESS)
			4'd0: begin /* control reg */
				/* bit 0: enable (1 = enable)
				   bit 1-2: tilemap stride (0 = 32 bytes, 1 = 64 bytes, 2 = 128 bytes, 3 = 256 bytes)
				   bit 3: tile set stride (0 = 128 nibbles, 1 = 256 nibbles) 
				   bit 7-4: palette hi
				*/
				bg_enable_next 		 = DATA_IN[0];
				tilemap_stride_next  = DATA_IN[2:1];
				tile_set_stride_next = DATA_IN[3];
				pal_hi_next 		 = DATA_IN[7:4];
			end
			4'd1: /* tile map x register */
				tile_map_x_next = DATA_IN;
			4'd2: /* tile map y register */
				tile_map_y_next = DATA_IN;
			4'd3: /* tile map address */
				tile_map_address_next = DATA_IN;
			4'd4: /* tile set address */	
				tile_set_address_next = DATA_IN;
			default: ;
		endcase
	end
end

// Sequential logic

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		bg_enable 		 <= 1'b0;
		tilemap_stride 	 <= 2'b00;
		tile_set_stride  <= 1'b0;
		tile_map_x 		 <= 16'h0000;
		tile_map_y 		 <= 16'h0000;
		tile_map_address <= 16'h0000;
		tile_set_address <= 16'h0000;	
		pal_hi 			 <= 4'd0;
		active_buffer 	 <= 1'b0;
		cur_fetch_buffer <= 1'b0;
		tilemap_index_r  <= 21'd0;
		memory_address_r <= 16'd0;
		f_state_r <= f_idle;
	end else begin
		bg_enable 		 <= bg_enable_next;
		tilemap_stride 	 <= tilemap_stride_next;
		tile_set_stride  <= tile_set_stride_next;
		tile_map_x 		 <= tile_map_x_next;
		tile_map_y 		 <= tile_map_y_next;
		tile_map_address <= tile_map_address_next;
		tile_set_address <= tile_set_address_next;	
		pal_hi 			 <= pal_hi_next;
		active_buffer 	 <= active_buffer_next;
		cur_fetch_buffer <= cur_fetch_buffer_next;
		tilemap_index_r  <= tilemap_index_r_next;
		memory_address_r <= memory_address_r_next;
		f_state_r <= f_state_r_next;
	end
end

endmodule
