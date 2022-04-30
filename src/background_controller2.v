/*
 *	Background renderer
 *
 *  Fixed tile size 16x16 - 256 16x16x4bpp tiles will fit in a 32kB SPRAM
 *
 */

module background_controller2 (
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
	input [9:0]   display_x_,
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

reg bg_tile_size;
reg bg_tile_size_next;

reg [1:0] bg_tile_stride;
reg [1:0] bg_tile_stride_next;

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

reg bg_enable2;
reg bg_enable2_next;

reg bg_tile_size2;
reg bg_tile_size2_next;

reg [1:0] bg_tile_stride2;
reg [1:0] bg_tile_stride2_next;

reg [15:0] tile_map_x2;
reg [15:0] tile_map_x2_next;

reg [15:0] tile_map_y2;
reg [15:0] tile_map_y2_next;

reg [15:0] tile_map_address2;
reg [15:0] tile_map_address2_next;

reg [15:0] tile_set_address2;
reg [15:0] tile_set_address2_next;

reg [3:0] pal_hi2;
reg [3:0] pal_hi2_next;

reg layer;
reg layer_next;

wire [9:0] display_x1 = (bg_tile_size == 1'b0) ?  display_x_ + {6'd0, tile_map_x[3:0]} : display_x_ + {7'd0, tile_map_x[2:0]};
wire [9:0] display_x2 = display_x_ + {6'd0, tile_map_x2[3:0]};

// Scanline buffers
// 4 buffers :
// buffer 0 / 1 : layer 1
// buffer 2 / 3 : layer 2

genvar j;

reg [7:0]   scanline_rd_addr[3:0];
reg [7:0]   scanline_wr_addr[3:0];
wire [15:0] scanline_rd_data[3:0];
reg [15:0]  scanline_wr_data[3:0];

reg scanline_wr[3:0];
reg active_buffer;	
reg active_buffer_next;

wire display_buffer = ! active_buffer;

wire [1:0] active_buffer_idx  = {layer, active_buffer};

wire [1:0] display_buffer_idx1 = {1'b0, display_buffer}; 
wire [1:0] display_buffer_idx2 = {1'b1, display_buffer}; 

generate 
for (j = 0; j < 4; j = j + 1)
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

reg [16:0] tilemap_index_r;
reg [16:0] tilemap_index_r_next;

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
localparam f_begin2			 = 4'd7;

reg [3:0] f_state_r;
reg [3:0] f_state_r_next;

reg [7:0] cur_tile;
reg [7:0] cur_tile_next;

wire [15:0] tilemap_y_disp = (layer == 1'b0 ? tile_map_y : tile_map_y2) + {6'd0, display_y} ;

reg [1:0] fetch_count;
reg [1:0] fetch_count_next;

reg [17:0] tile_lookup;

always @(*)
begin
	if (layer == 1'b0) begin
		if (bg_tile_size == 1'b0) // 16x16
			tile_lookup = {10'd0, cur_tile[3:0], 4'd0}	+ 
					  	  {2'd0, cur_tile[7:4], 12'd0}   +
						  {6'd0, tilemap_y_disp[3:0], 8'd0} +  
						  {14'd0, cur_render_x[3:0]} + {tile_set_address, 2'd0};
		else // 8x8
			tile_lookup = {10'd0, cur_tile[4:0], 3'd0}	+ 
					  	  {3'd0, cur_tile[7:5], 11'd0}   +
						  {7'd0, tilemap_y_disp[2:0], 8'd0} +  
						  {15'd0, cur_render_x[2:0]} + {tile_set_address, 2'd0};
		
	end
	else begin
		if (bg_tile_size2 == 1'b0) // 16x16
			tile_lookup = {10'd0, cur_tile[3:0], 4'd0}	+ 
					  	  {2'd0, cur_tile[7:4], 12'd0}   +
						  {6'd0, tilemap_y_disp[3:0], 8'd0} +  
						  {14'd0, cur_render_x[3:0]} + {tile_set_address2, 2'd0};
		else // 8x8
			tile_lookup = {10'd0, cur_tile[4:0], 3'd0}	+ 
					  	  {3'd0, cur_tile[7:5], 11'd0}   +
						  {7'd0, tilemap_y_disp[2:0], 8'd0} +  
						  {15'd0, cur_render_x[2:0]} + {tile_set_address2, 2'd0};
	
	end

end


reg [1:0] terminal_tile_count;

always @(*)
begin

	if (layer == 1'b0) begin

		if (bg_tile_size == 1'b1) 
			terminal_tile_count = 2'd1;
		else
			terminal_tile_count = 2'd3;

	end else begin

		if (bg_tile_size2 == 1'b1) 
			terminal_tile_count = 2'd1;
		else
			terminal_tile_count = 2'd3;
	end

end

always @(CLK)
begin

	f_state_r_next 			= f_state_r;
	tilemap_index_r_next 	= tilemap_index_r;
	memory_address_r_next 	= memory_address_r;
	cur_tile_next 			= cur_tile;
	fetch_count_next		= fetch_count;

	rvalid_r = 1'b0;

	scanline_wr_addr[0] = 8'd0;
	scanline_wr_addr[1] = 8'd0;
	scanline_wr_addr[2] = 8'd0;
	scanline_wr_addr[3] = 8'd0;

	scanline_wr[0] 		= 1'b0;
	scanline_wr[1] 		= 1'b0;
	scanline_wr[2] 		= 1'b0;
	scanline_wr[3] 		= 1'b0;

	scanline_wr_data[0] = 16'h0000;	
	scanline_wr_data[1] = 16'h0000;	
	scanline_wr_data[2] = 16'h0000;	
	scanline_wr_data[3] = 16'h0000;	

	scanline_wr_addr[active_buffer_idx] = cur_render_x[9:2];
	scanline_wr[active_buffer_idx] 		= 1'b0;
	scanline_wr_data[active_buffer_idx] = 16'h0000;	

	// Clear display buffers as they are read		
	scanline_wr[display_buffer_idx1] 	 = 1'b1;
	scanline_wr_addr[display_buffer_idx1] = display_x_[9:2] - 8'd1;
	scanline_wr_data[display_buffer_idx1] = 16'h0000;	

	scanline_wr[display_buffer_idx2] 	 = 1'b1;
	scanline_wr_addr[display_buffer_idx2] = display_x_[9:2] - 8'd1;
	scanline_wr_data[display_buffer_idx2] = 16'h0000;	



	active_buffer_next = active_buffer;


	cur_render_x_next = cur_render_x;

	layer_next = layer;

	if (H_tick == 1'b1 && bg_enable == 1'b1)
	begin
		f_state_r_next = f_begin;
		fetch_count_next = 2'd0;
		active_buffer_next = display_buffer;
		layer_next = 1'b0;
	end
	else begin
		case (f_state_r)
			f_idle:	;
			f_begin: begin

				if (bg_tile_size == 1'b0) begin // 16x16
					case (bg_tile_stride)
						2'b00: /* stride 256 */
							tilemap_index_r_next = {tile_map_address, 1'd0} + {      tilemap_y_disp[12:4], tile_map_x[11:4]}; 
						2'b01: /* stride 128 */
							tilemap_index_r_next = {tile_map_address, 1'd0} + {      tilemap_y_disp[13:4], tile_map_x[10:4]}; 
						2'b10: /* stride 64 */
							tilemap_index_r_next = {tile_map_address, 1'd0} + {      tilemap_y_disp[14:4], tile_map_x[9:4]}; 
						2'b11: /* stride 32 */
							tilemap_index_r_next = {tile_map_address, 1'd0} + {      tilemap_y_disp[15:4], tile_map_x[8:4]}; 
					endcase
				end else begin // 8x8
					case (bg_tile_stride)
						2'b00: /* stride 256 */
							tilemap_index_r_next = {tile_map_address, 1'd0} + {tilemap_y_disp[11:3], tile_map_x[10:3]}; 
						2'b01: /* stride 128 */
							tilemap_index_r_next = {tile_map_address, 1'd0} + {tilemap_y_disp[12:3], tile_map_x[9:3]}; 
						2'b10: /* stride 64 */
							tilemap_index_r_next = {tile_map_address, 1'd0} + {tilemap_y_disp[13:3], tile_map_x[8:3]}; 
						2'b11: /* stride 32 */
							tilemap_index_r_next = {tile_map_address, 1'd0} + {tilemap_y_disp[14:3], tile_map_x[7:3]}; 
					endcase
				end

				f_state_r_next 		 = f_fetch_tile;
				cur_render_x_next    = 10'd16; 
			end
			f_begin2: begin
				
				if (bg_tile_size2 == 1'b0) begin // 16x16
					case (bg_tile_stride2)
						2'b00: /* stride 256 */
							tilemap_index_r_next = {tile_map_address2, 1'd0} + {      tilemap_y_disp[12:4], tile_map_x2[11:4]}; 
						2'b01: /* stride 128 */
							tilemap_index_r_next = {tile_map_address2, 1'd0} + {      tilemap_y_disp[13:4], tile_map_x2[10:4]}; 
						2'b10: /* stride 64 */
							tilemap_index_r_next = {tile_map_address2, 1'd0} + {      tilemap_y_disp[14:4], tile_map_x2[9:4]}; 
						2'b11: /* stride 32 */
							tilemap_index_r_next = {tile_map_address2, 1'd0} + {      tilemap_y_disp[15:4], tile_map_x2[8:4]}; 
					endcase
				end else begin // 8x8
					case (bg_tile_stride)
						2'b00: /* stride 256 */
							tilemap_index_r_next = {tile_map_address2, 1'd0} + {tilemap_y_disp[11:3], tile_map_x2[10:3]}; 
						2'b01: /* stride 128 */
							tilemap_index_r_next = {tile_map_address2, 1'd0} + {tilemap_y_disp[12:3], tile_map_x2[9:3]}; 
						2'b10: /* stride 64 */
							tilemap_index_r_next = {tile_map_address2, 1'd0} + {tilemap_y_disp[13:3], tile_map_x2[8:3]}; 
						2'b11: /* stride 32 */
							tilemap_index_r_next = {tile_map_address2, 1'd0} + {tilemap_y_disp[14:3], tile_map_x2[7:3]}; 
					endcase
				end
	
				f_state_r_next 		 = f_fetch_tile;
				cur_render_x_next    = 10'd16;
			end
			f_fetch_tile: begin
				if (cur_render_x == 10'd720)
					if (layer == 1'b0 && bg_enable2 == 1'b1) begin
						f_state_r_next = f_begin2;
						layer_next = 1'b1; 
					end
					else 
						f_state_r_next = f_idle;
				else
					f_state_r_next 			= f_wait_tile_mem;
				memory_address_r_next   = tilemap_index_r[16:1]; // word address
			end
			f_wait_tile_mem: begin
				rvalid_r = 1'b1;
				if (rready == 1'b1) begin
					if (tilemap_index_r[0] == 1'b0)
						cur_tile_next = memory_data[7:0];
					else
						cur_tile_next = memory_data[15:8];
					f_state_r_next = f_fetch_tile_data; 
				end
			end
			f_fetch_tile_data: begin
			
				if (cur_tile == 8'hff) begin
					
					if (layer == 1'b0 && bg_tile_size == 1'b0)  // 16x16
						cur_render_x_next = cur_render_x + 16;
					else if (layer == 1'b0 && bg_tile_size == 1'b1)
						cur_render_x_next = cur_render_x + 8;
					if (layer == 1'b1 && bg_tile_size2 == 1'b0)  // 16x16
						cur_render_x_next = cur_render_x + 16;
					else if (layer == 1'b1 && bg_tile_size2 == 1'b1)
						cur_render_x_next = cur_render_x + 8;

					tilemap_index_r_next = tilemap_index_r + 1;
					f_state_r_next = f_fetch_tile;
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
				scanline_wr[active_buffer_idx] 		= 1'b1;
				scanline_wr_data[active_buffer_idx] = memory_data;
				cur_render_x_next = cur_render_x + 4;
				fetch_count_next = fetch_count + 1;
				if (fetch_count == terminal_tile_count) begin
					fetch_count_next = 2'd0;
					f_state_r_next = f_fetch_tile;	
					tilemap_index_r_next = tilemap_index_r + 1;	
				end
			end			
			default:
				f_state_r_next = f_idle;
		endcase
	end


end



// Read out scanline buffer

reg [7:0] color_index_r;
reg [7:0] color_index_r_next;

reg [7:0] color_index2_r;
reg [7:0] color_index2_r_next;

assign color_index = (color_index_r[3:0] == 4'd0) ? color_index2_r : color_index_r;

reg [9:0] display_x_reg1;
reg [9:0] display_x_reg2;


always @(posedge CLK)
begin
	display_x_reg1 <= display_x1;
	display_x_reg2 <= display_x2;
end

always @(*)
begin
	scanline_rd_addr[0]  = 8'd0;
 	scanline_rd_addr[1]  = 8'd0;
 	scanline_rd_addr[2]  = 8'd0;
 	scanline_rd_addr[3]  = 8'd0;
  	
  	scanline_rd_addr[display_buffer_idx1] = display_x1[9:2];
  	scanline_rd_addr[display_buffer_idx2] = display_x2[9:2];

	case (display_x_reg1[1:0])
		2'b00:
			color_index_r_next = {pal_hi, scanline_rd_data[display_buffer_idx1][3:0]};
		2'b01:
			color_index_r_next = {pal_hi, scanline_rd_data[display_buffer_idx1][7:4]};
		2'b10:
			color_index_r_next = {pal_hi, scanline_rd_data[display_buffer_idx1][11:8]};
		2'b11:
			color_index_r_next = {pal_hi, scanline_rd_data[display_buffer_idx1][15:12]};
	endcase

	case (display_x_reg2[1:0])
		2'b00:
			color_index2_r_next = {pal_hi2, scanline_rd_data[display_buffer_idx2][3:0]};
		2'b01:
			color_index2_r_next = {pal_hi2, scanline_rd_data[display_buffer_idx2][7:4]};
		2'b10:
			color_index2_r_next = {pal_hi2, scanline_rd_data[display_buffer_idx2][11:8]};
		2'b11:
			color_index2_r_next = {pal_hi2, scanline_rd_data[display_buffer_idx2][15:12]};
	endcase

end

// Register interface to CPU

always @(*)
begin

	bg_enable_next 		  = bg_enable;
	tile_map_x_next 	  = tile_map_x;
	tile_map_y_next 	  = tile_map_y;
	tile_map_address_next = tile_map_address;
	tile_set_address_next = tile_set_address;
	pal_hi_next 		  = pal_hi;	

	bg_tile_size_next	 = bg_tile_size;
	bg_tile_stride_next	 = bg_tile_stride;

	bg_enable2_next 		  = bg_enable2;
	tile_map_x2_next 	  = tile_map_x2;
	tile_map_y2_next 	  = tile_map_y2;
	tile_map_address2_next = tile_map_address2;
	tile_set_address2_next = tile_set_address2;
	pal_hi2_next 		  = pal_hi2;	

	bg_tile_size2_next	 = bg_tile_size2;
	bg_tile_stride2_next = bg_tile_stride2;

	if (WR == 1'b1)
	begin
		case (ADDRESS)
			4'd0: begin /* control reg */
				/* bit 0: enable (1 = enable)
				   bit 7-4: palette hi
				*/
				bg_enable_next 		 = DATA_IN[0];
				pal_hi_next 		 = DATA_IN[7:4];
				bg_tile_size_next 		 = DATA_IN[15];
				bg_tile_stride_next 		 = DATA_IN[9:8];
			end
			4'd1: /* tile map x register */
				tile_map_x_next = DATA_IN;
			4'd2: /* tile map y register */
				tile_map_y_next = DATA_IN;
			4'd3: /* tile map address */
				tile_map_address_next = DATA_IN;
			4'd4: /* tile set address */	
				tile_set_address_next = DATA_IN;
			4'd5: begin /* control reg 2 */
				/* bit 0: enable (1 = enable)
				   bit 7-4: palette hi
				*/
				bg_enable2_next = DATA_IN[0];
				pal_hi2_next 	= DATA_IN[7:4];
				bg_tile_size2_next 		 = DATA_IN[15];
				bg_tile_stride2_next 	 = DATA_IN[9:8];
			end
			4'd6: /* tile map x register 2 */
				tile_map_x2_next = DATA_IN;
			4'd7: /* tile map y register 2 */
				tile_map_y2_next = DATA_IN;
			4'd8: /* tile map address 2 */
				tile_map_address2_next = DATA_IN;
			4'd9: /* tile set address 2 */	
				tile_set_address2_next = DATA_IN;
			default: ;
		endcase
	end
end

// Sequential logic


always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		bg_enable 		 <= 1'b0;
		tile_map_x 		 <= 16'h0000;
		tile_map_y 		 <= 16'h0000;
		tile_map_address <= 16'h0000;
		tile_set_address <= 16'h0000;	
		pal_hi 			 <= 4'd0;
		bg_enable2 		 <= 1'b0;
		tile_map_x2 		 <= 16'h0000;
		tile_map_y2 		 <= 16'h0000;
		tile_map_address2 <= 16'h0000;
		tile_set_address2 <= 16'h0000;	
		pal_hi2 			 <= 4'd0;
		active_buffer 	 <= 1'b0;
		tilemap_index_r  <= 17'd0;
		memory_address_r <= 16'd0;
		f_state_r 		 <= f_idle;
		cur_render_x 	 <= 10'd0;
		cur_tile		 <= 8'd0;
		fetch_count		<= 2'd0;
		color_index_r   <= 8'd0;
		color_index2_r   <= 8'd0;
		layer 			<= 1'b0;
		bg_tile_stride		<= 2'b00;
		bg_tile_size		<= 1'b0;
		bg_tile_stride2		<= 2'b00;
		bg_tile_size2		<= 1'b0;
	end else begin
		bg_enable 		 <= bg_enable_next;
		tile_map_x 		 <= tile_map_x_next;
		tile_map_y 		 <= tile_map_y_next;
		tile_map_address <= tile_map_address_next;
		tile_set_address <= tile_set_address_next;	
		pal_hi 			 <= pal_hi_next;
		bg_enable2 		 <= bg_enable2_next;
		tile_map_x2 		 <= tile_map_x2_next;
		tile_map_y2 		 <= tile_map_y2_next;
		tile_map_address2 <= tile_map_address2_next;
		tile_set_address2 <= tile_set_address2_next;	
		pal_hi2 			 <= pal_hi2_next;
		active_buffer 	 <= active_buffer_next;
		tilemap_index_r  <= tilemap_index_r_next;
		memory_address_r <= memory_address_r_next;
		f_state_r 		 <= f_state_r_next;
		cur_render_x	 <= cur_render_x_next;
		cur_tile		 <= cur_tile_next;
		fetch_count		<= fetch_count_next;
		color_index_r <= color_index_r_next;
		color_index2_r <= color_index2_r_next;
		layer			<= layer_next;
		bg_tile_stride		<= bg_tile_stride_next;
		bg_tile_size		<= bg_tile_size_next;
		bg_tile_stride2		<= bg_tile_stride2_next;
		bg_tile_size2		<= bg_tile_size2_next;	
	end
end

endmodule
