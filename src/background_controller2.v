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

reg [7:0]  scanline_rd_addr[1:0];
reg [7:0]  scanline_wr_addr[1:0];
wire [15:0] scanline_rd_data[1:0];
reg [15:0]  scanline_wr_data[1:0];

reg scanline_wr[1:0];
reg active_buffer;
wire display_buffer = !active_buffer;
reg active_buffer_next;

generate 
for (j = 0; j < 2; j = j + 1)
begin:	scanline_buffers bram #(.BITS(16), .ADDRESS_BITS(8)) br_inst
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

localparam FETCH_BUFFER_BITS = 64;
localparam FETCH_BUFFER_BITS_DIV4 = FETCH_BUFFER_BITS / 4;

reg cur_fetchbuffer; // we double buffer the shift register so we can be fetching 
reg cur_fetchbuffer_next;

wire cur_blit_buffer = ! cur_fetchbuffer;
reg [FETCH_BUFFER_BITS - 1:0] fetchbuffer[1:0]; // shift register
reg [FETCH_BUFFER_BITS - 1:0] fetchbuffer_next[1:0]; // shift register
reg blit_go; // signal to blitter to start blitting

reg [20:0] tilemap_index_r;
reg [20:0] tilemap_index_r_next;

reg [15:0] memory_address_r;
reg [15:0] memory_address_r_next;
reg rvalid_r;

reg [9:0] cur_render_x;
reg [9:0] cur_render_x_next;

assign memory_address = memory_address_r;
assign rvalid = rvalid_r;

localparam f_idle 			 = 4'd0;
localparam f_begin			 = 4'd1;
localparam f_fetch_tile 	 = 4'd2;
localparam f_wait_tile_mem   = 4'd3;
localparam f_fetch_tile_data = 4'd4;
localparam f_wait_td_mem     = 4'd5;
localparam f_wait_td_mem2    = 4'd6;
localparam f_wait_blitter    = 4'd7;
localparam f_dummy_blitter   = 4'd8;

reg [3:0] f_state_r;
reg [3:0] f_state_r_next;

reg [7:0] cur_tile;
reg [7:0] cur_tile_next;

wire [15:0] tilemap_y_disp = tile_map_y + {6'd0, display_y};

reg [3:0] fetch_count;
reg [3:0] fetch_count_next;

localparam b_idle = 1'b0;
localparam b_blit = 1'b1;

reg blit_state_r;
reg blit_state_r_next;

reg [3:0] blit_count;
reg [3:0] blit_count_next;

reg [17:0] tile_lookup;

always @(*)
begin
	tile_lookup = {10'd0, cur_tile[3:0], 4'd0}	+ 
				  {2'd0, cur_tile[7:4], 12'd0}   +
				{tilemap_y_disp[3:0], 8'd0} +  
				{14'd0, tilemap_index_r[3:0]} + {tile_set_address, 2'd0};
end


task gen_shift (input [15:0] datin);
begin

		if (tilemap_index_r[1:0] == 2'b00 && fetch_count <= 4'd12)
				begin
						
					fetchbuffer_next[cur_fetchbuffer][FETCH_BUFFER_BITS - 17:0] = fetchbuffer[cur_fetchbuffer][FETCH_BUFFER_BITS - 1:16];
					fetchbuffer_next[cur_fetchbuffer][FETCH_BUFFER_BITS - 1 : FETCH_BUFFER_BITS - 16] = datin;
					tilemap_index_r_next = tilemap_index_r_next + 21'd4;
					fetch_count_next = fetch_count + 4;	
					if (tilemap_index_r[3:0] == 4'd12)
						f_state_r_next = f_fetch_tile;
					if (fetch_count == 4'd12)
						f_state_r_next = f_wait_blitter;
				end
				else if (tilemap_index_r[1:0] <= 2'b01 && fetch_count <= 4'd13)
				begin
					fetchbuffer_next[cur_fetchbuffer][FETCH_BUFFER_BITS - 13:0] = fetchbuffer[cur_fetchbuffer][FETCH_BUFFER_BITS - 1:12];
					fetchbuffer_next[cur_fetchbuffer][FETCH_BUFFER_BITS - 1: FETCH_BUFFER_BITS - 12]  = datin[15:4];
					tilemap_index_r_next = tilemap_index_r_next + 21'd3;
					fetch_count_next = fetch_count + 3;
					if (tilemap_index_r[3:0] == 4'd13)
						f_state_r_next = f_fetch_tile;
					if (fetch_count == 4'd13)
						f_state_r_next = f_wait_blitter;
				end
				else if (tilemap_index_r[1:0] <= 2'b10 && fetch_count <= 4'd14)
				begin
					fetchbuffer_next[cur_fetchbuffer][FETCH_BUFFER_BITS - 9:0] = fetchbuffer[cur_fetchbuffer][FETCH_BUFFER_BITS - 1:8];
					fetchbuffer_next[cur_fetchbuffer][FETCH_BUFFER_BITS - 1: FETCH_BUFFER_BITS - 8] = datin[15:8];
					tilemap_index_r_next = tilemap_index_r_next + 21'd2;
					fetch_count_next = fetch_count + 2;
					if (tilemap_index_r[3:0] == 4'd14)
						f_state_r_next = f_fetch_tile;
					if (fetch_count == 4'd14)
						f_state_r_next = f_wait_blitter;
				end
				else begin
					fetchbuffer_next[cur_fetchbuffer][FETCH_BUFFER_BITS - 5:0] = fetchbuffer[cur_fetchbuffer][FETCH_BUFFER_BITS - 1:4];
					fetchbuffer_next[cur_fetchbuffer][FETCH_BUFFER_BITS - 1: FETCH_BUFFER_BITS - 4] = datin[15:12];
					tilemap_index_r_next = tilemap_index_r_next + 21'd1;
					fetch_count_next = fetch_count + 1;
					if (tilemap_index_r[3:0] == 4'd15)
						f_state_r_next = f_fetch_tile;
					if (fetch_count == 4'd15)
						f_state_r_next = f_wait_blitter;
				end

end
endtask

 
integer i;

always @(*)
begin

	// Fetcher process: fetch tile pixels into a 64 bit shift register

	f_state_r_next 			= f_state_r;
	tilemap_index_r_next 	= tilemap_index_r;
	memory_address_r_next 	= memory_address_r;
	cur_tile_next 			= cur_tile;
	blit_go 				= 1'b0;
	fetch_count_next		= fetch_count;

	cur_fetchbuffer_next    = cur_fetchbuffer;

	for (i = 0; i < 2; i = i + 1)
		fetchbuffer_next[i] = fetchbuffer[i];
	
	rvalid_r = 1'b0;

	if (H_tick == 1'b1 && bg_enable == 1'b1)
	begin
		f_state_r_next = f_begin;
		fetch_count_next = 4'd0;
	end
	else begin
		case (f_state_r)
			f_idle:	;
			f_begin: begin
				tilemap_index_r_next = {tile_map_address, 5'd0} + {1'd0, tilemap_y_disp[12:4], 1'd0, tile_map_x[9:0]}; 
				f_state_r_next 		 = f_fetch_tile; 
			end
			f_fetch_tile: begin
				f_state_r_next 			= f_wait_tile_mem;
				memory_address_r_next   = tilemap_index_r[20:5]; // word address
			end
			f_wait_tile_mem: begin
				rvalid_r = 1'b1;
				if (rready == 1'b1) begin
					if (tilemap_index_r[4] == 1'b0)
						cur_tile_next = memory_data[7:0];
					else
						cur_tile_next = memory_data[15:8];
					f_state_r_next = f_fetch_tile_data; 
				end
			end
			f_fetch_tile_data: begin
				if (cur_tile == 8'hff) begin
					f_state_r_next = f_dummy_blitter;
				end else begin
					memory_address_r_next = tile_lookup[17:2];
					f_state_r_next = f_wait_td_mem;
				end
			end
			f_wait_td_mem: begin
				rvalid_r = 1'b1;
				
				if (rready == 1'b1) begin
					memory_address_r_next = memory_address_r + 1;
					f_state_r_next = f_wait_td_mem2;
				end
			end
			f_wait_td_mem2: begin
				rvalid_r = 1'b1;
				memory_address_r_next = memory_address_r + 1;
				gen_shift(memory_data);	
			end			
			f_wait_blitter: begin 
				cur_fetchbuffer_next = !cur_fetchbuffer;
				blit_go = 1'b1;
				//if (tilemap_index_r[3:0] == 4'd0)
				f_state_r_next = f_fetch_tile;
				//else begin
				//	rvalid_r = 1'b1;
				//	f_state_r_next = f_wait_td_mem2; 
				//end				
			end
			f_dummy_blitter: begin
				gen_shift(16'd0);
			end
			default:
				f_state_r_next = f_idle;
		endcase
	end

	// Blitter process: blit from shift register to block RAM

	blit_state_r_next = blit_state_r;

	scanline_wr_addr[0] = 8'd0;
	scanline_wr_addr[1] = 8'd0;

	scanline_wr[0] 		= 1'b0;
	scanline_wr[1] 		= 1'b0;

	scanline_wr_data[0] = 16'h0000;	
	scanline_wr_data[1] = 16'h0000;	

	scanline_wr_addr[active_buffer] = cur_render_x[9:2];
	scanline_wr[active_buffer] 		= 1'b0;
	scanline_wr_data[active_buffer] = 16'h0000;	

	// Clear display buffer as it is read		
	scanline_wr[display_buffer] 	= 1'b1;
	scanline_wr_addr[display_buffer] = display_x[9:2] - 8'd1;
	scanline_wr_data[display_buffer] = 16'h1234;	

	active_buffer_next = active_buffer;

	blit_count_next = blit_count;

	cur_render_x_next = cur_render_x;

	if (H_tick == 1'b1) begin
		if (bg_enable == 1'b1) begin	// Background layer enabled?
			active_buffer_next = display_buffer;
			blit_state_r_next = b_idle;
			cur_render_x_next = 10'd48;
		end
	end 
	else begin
		case (blit_state_r)
			b_idle:
				if (blit_go == 1'b1) begin
					blit_state_r_next = b_blit;
					blit_count_next = 4'd3;
				end
			b_blit: begin
				scanline_wr_data[active_buffer] = fetchbuffer[cur_blit_buffer][15:0];
				scanline_wr[active_buffer] 		= 1'b1;
				fetchbuffer_next[cur_blit_buffer][FETCH_BUFFER_BITS - 17 : 0] = fetchbuffer[cur_blit_buffer][FETCH_BUFFER_BITS - 1: 16];				
				fetchbuffer_next[cur_blit_buffer][FETCH_BUFFER_BITS - 1 : FETCH_BUFFER_BITS - 16] = 16'd0;
				blit_count_next = blit_count - 1;
				if (blit_count == 4'd0)
					blit_state_r_next = b_idle;
				cur_render_x_next = cur_render_x + 10'd4;
			end
		endcase
	end
end



// Read out scanline buffer

reg [7:0] color_index_r;
reg [7:0] color_index_r_next;
assign color_index = color_index_r;

reg [9:0] display_x_reg;

always @(posedge CLK)
begin
	display_x_reg <= display_x;
end

always @(*)
begin
	scanline_rd_addr[0]  = 10'd0;
 	scanline_rd_addr[1]  = 10'd0;
  	
	scanline_rd_addr[active_buffer]  = 10'd0;
  	scanline_rd_addr[display_buffer] = display_x[9:2];

	case (display_x_reg[1:0])
		2'b00:
			color_index_r_next = {pal_hi, scanline_rd_data[display_buffer][3:0]};
		2'b01:
			color_index_r_next = {pal_hi, scanline_rd_data[display_buffer][7:4]};
		2'b10:
			color_index_r_next = {pal_hi, scanline_rd_data[display_buffer][11:8]};
		2'b11:
			color_index_r_next = {pal_hi, scanline_rd_data[display_buffer][15:12]};
	endcase
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
		cur_fetchbuffer <= 1'b0;
		tilemap_index_r  <= 21'd0;
		memory_address_r <= 16'd0;
		f_state_r 		 <= f_idle;
		cur_render_x 	 <= 10'd0;
		cur_tile		 <= 8'd0;
		for (i = 0; i < 2; i = i + 1)
			fetchbuffer[i] = {FETCH_BUFFER_BITS{1'b0}};	
		fetch_count		<= 4'd0;
		blit_state_r	<= b_idle;
		blit_count		<= 4'd0;
		color_index_r   <= 8'd0;
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
		cur_fetchbuffer <= cur_fetchbuffer_next;
		tilemap_index_r  <= tilemap_index_r_next;
		memory_address_r <= memory_address_r_next;
		f_state_r 		 <= f_state_r_next;
		cur_render_x	 <= cur_render_x_next;
		cur_tile		 <= cur_tile_next;
		for (i = 0; i < 2; i = i + 1)
			fetchbuffer[i] = fetchbuffer_next[i];	
		fetch_count		<= fetch_count_next;
		blit_state_r	<= blit_state_r_next;
		blit_count		<= blit_count_next;
		color_index_r <= color_index_r_next;
	end
end

endmodule
