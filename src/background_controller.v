/*
 *	Background renderer
 *
 *  Fixed tile size 16x16 - 256 16x16x4bpp tiles will fit in a 32kB SPRAM
 *
 */

module background_controller
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

// Render process

reg [3:0] r_state;
reg [3:0] r_state_next;

localparam r_idle 	  	= 4'd0;
localparam r_begin 	  	= 4'd1;
localparam r_loadmap 	= 4'd2;
localparam r_waitmem_map  = 4'd3;
localparam r_waitmem_map2  = 4'd4;
localparam r_load_tile 	  = 4'd5;
localparam r_waitmem_tile = 4'd6;
localparam r_waitmem_tile2 = 4'd7;
localparam r_blit0 		= 4'd8;
localparam r_blit1 		= 4'd9;
localparam r_blit2 		= 4'd10;
localparam r_blit3 		= 4'd11;
localparam r_finish 	= 4'd12;

reg [9:0] cur_render_x;
reg [9:0] cur_render_x_next; 

reg [20:0] tilemap_index_r;
reg [20:0] tilemap_index_r_next;

reg [15:0] memory_address_r;
reg [15:0] memory_address_r_next;
reg rvalid_r;

assign memory_address = memory_address_r;
assign rvalid = rvalid_r;

wire [15:0] tilemap_y_disp = tile_map_y + {6'd0, display_y - 10'd33};

reg [7:0] cur_tile;
reg [7:0] cur_tile_next;

reg [17:0] tile_lookup;

reg [15:0] tile_data;
reg [15:0] tile_data_next;


always @(*)
begin
	tile_lookup = 18'd0;
//	case (tile_set_stride)
		// Nibble address
	//	1'b0:	/*  128 nibbles  = 8 tiles */			
	//		tile_lookup = /*{11'd0, cur_tile[2:0], 4'd0}	+ 
	//					  {2'd0,  cur_tile[7:3], 7'd0}  +*/
	//					  {14'd0, tilemap_index_r[3:0]} + {2'd0, tile_set_address};
	//	1'b1:   /* 256 nibble = 16 tiles */
			tile_lookup = {10'd0, cur_tile[3:0], 4'd0}	+ 
						  {2'd0, cur_tile[7:4], 12'd0}   +
						{tilemap_y_disp[3:0], 8'd0} +  
						{14'd0, tilemap_index_r[3:0]} + {tile_set_address, 2'd0};
//	endcase
end
 

always @(*)
begin
	r_state_next = r_state;
	cur_render_x_next = cur_render_x;
	tilemap_index_r_next = tilemap_index_r;
	rvalid_r = 0;
	memory_address_r_next = memory_address_r;
	cur_tile_next = cur_tile;
	tile_data_next = tile_data;

	scanline_wr_addr[0] = 10'd0;
	scanline_wr_addr[1] = 10'd0;

	scanline_wr[0] 		= 1'b0;
	scanline_wr[1] 		= 1'b0;

	scanline_wr_data[0] = 8'h00;	
	scanline_wr_data[1] = 8'h00;	



	scanline_wr_addr[active_buffer] = cur_render_x;
	scanline_wr[active_buffer] 		= 1'b0;
	scanline_wr_data[active_buffer] = 4'h00;	

	// Clear display buffer as it is read		
	scanline_wr[display_buffer] 	= 1'b1;
	scanline_wr_addr[display_buffer] = display_x == 10'd0 ? 10'd799 : display_x - 1;
	scanline_wr_data[display_buffer] = 4'd0;	

	active_buffer_next = active_buffer;

	if (H_tick == 1'b1) begin
		if (bg_enable == 1'b1) begin	// Background layer enabled?
			active_buffer_next = display_buffer;
			r_state_next = r_begin;
		end
		else
			r_state_next = r_idle;
	end 
	else begin
		case (r_state)
			r_idle: ;
			r_begin: begin

				if (display_x == H_START && display_y >= V_START && display_y <= V_END) // todo: replace with render enable 
					r_state_next = r_loadmap;
	
				//case (tilemap_stride)
				//	2'd0:	/*  32 bytes */				
				//		tilemap_index_r_next = {tile_map_address, 5'd0} + {tilemap_y_disp[15:4],tile_map_x[8:0]};
				//	2'd1:   /* 64 bytes */
				//		tilemap_index_r_next = {tile_map_address, 5'd0} + {tilemap_y_disp[14:4],tile_map_x[9:0]}; 
				//	2'd2:   /* 128 bytes */
						tilemap_index_r_next = {tile_map_address, 5'd0} + {1'd0, tilemap_y_disp[12:4], 11'd0} + {11'd0, tile_map_x[9:0]} + {11'd0, H_START}; 
				//	2'd3:   /* 256 bytes */	
				//		tilemap_index_r_next = {tile_map_address, 5'd0} + {tilemap_y_disp[12:4],tile_map_x[11:0]};
				//endcase

				cur_render_x_next = H_START;
			end
			r_loadmap: begin
				r_state_next 			= r_waitmem_map;
				memory_address_r_next   = tilemap_index_r[20:5]; // word address
			end
			r_waitmem_map: begin
				rvalid_r = 1'b1;
				r_state_next = r_waitmem_map2;
			end
			r_waitmem_map2: begin
				rvalid_r = 1'b1;

				if (rready == 1'b1) begin
					r_state_next = r_load_tile;
					if (tilemap_index_r[4] == 1'b0)
						cur_tile_next = memory_data[7:0];
					else
						cur_tile_next = memory_data[15:8];
				end
			end
			r_load_tile: begin
				if (cur_tile == 8'hff) begin
					r_state_next = r_finish;
					cur_render_x_next = cur_render_x + {5'd0, (5'd16 - {1'd0,tilemap_index_r[3:0]})};
					tilemap_index_r_next = tilemap_index_r_next + {15'd0, (5'd16 - {1'd0, tilemap_index_r[3:0]})};
				end
				else begin
					memory_address_r_next = tile_lookup[17:2];
					r_state_next = r_waitmem_tile;
				end
			end
			r_waitmem_tile: begin
				rvalid_r = 1'b1;
				r_state_next = r_waitmem_tile2;
			end
			r_waitmem_tile2: begin
				rvalid_r = 1'b1;

				if (rready == 1'b1) begin
					tile_data_next = memory_data;

					case (tilemap_index_r[1:0])
						2'b00:
							r_state_next = r_blit0;
						2'b01:
							r_state_next = r_blit1;
						2'b10:
							r_state_next = r_blit2;
						2'b11:
							r_state_next = r_blit3;
					endcase
				end
			end
			r_blit0: begin
				scanline_wr[active_buffer] = 1'b1;
 				r_state_next = r_blit1;
				scanline_wr_data[active_buffer] = tile_data[3:0];
				
				cur_render_x_next 	 = cur_render_x + 1;
				tilemap_index_r_next = tilemap_index_r + 1; 
			end
			r_blit1: begin
				scanline_wr[active_buffer] = 1'b1;
 				r_state_next = r_blit2;
				scanline_wr_data[active_buffer] = tile_data[7:4];
				
				cur_render_x_next 	 = cur_render_x + 1;
				tilemap_index_r_next = tilemap_index_r + 1; 
			end
			r_blit2: begin
				scanline_wr[active_buffer] = 1'b1;
 				r_state_next = r_blit3;
				scanline_wr_data[active_buffer] = tile_data[11:8];
				
				cur_render_x_next 	 = cur_render_x + 1;
				tilemap_index_r_next = tilemap_index_r + 1; 
			end
			r_blit3: begin
				scanline_wr[active_buffer] = 1'b1;
 			
				if (tilemap_index_r[3:0] == 4'd15)
					r_state_next = r_finish;
				else
					r_state_next = r_load_tile;

				scanline_wr_data[active_buffer] = tile_data[15:12];
				
				cur_render_x_next 	 = cur_render_x + 1;
				tilemap_index_r_next = tilemap_index_r + 1; 
			end
			r_finish: begin
				if (cur_render_x >= H_END)
					r_state_next = r_idle;
				else
					r_state_next = r_loadmap; 
			end
			default:
				r_state_next = r_idle;
		endcase
	end
end

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
		active_buffer <= 1'b0;
		r_state 	  <= r_idle;
		tilemap_index_r <= 21'd0;
		cur_render_x  <= 10'd0;
		memory_address_r <= 16'd0;
		cur_tile	  <= 8'd0;
		tile_data 	  <= 16'd0;
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
		r_state 	  	 <= r_state_next;
		cur_render_x 	 <= cur_render_x_next;
		memory_address_r <= memory_address_r_next;
		tilemap_index_r <= tilemap_index_r_next;
		cur_tile   <= cur_tile_next;
		tile_data <= tile_data_next;
	end
end

endmodule
