/*
 *
 *	fb_doubler.v : draw a pixel-double framebuffer to area of screen
 *
 *	8-bit gfx, has custom palette
 *
 */

module fb_doubler
(
	input  CLK,
	input  RSTb,

	input  [7:0] ADDRESS,
	input  [15:0] DATA_IN,
	input  WR_reg,
	input  WR_pal,

	/* single cycle tick when vertical count is zero */
	input V_tick,
	/* single cycle tick horizontal count is zero */
	input H_tick,

	/* display uses this channel to read scanline block RAM */
	input [9:0]   display_x,
	input [9:0]   display_y,
	input         re,	// render enable
	output [15:0] color,  // ARGB 4:4:4:4

	/* memory channel to memory arbiter */
	output [15:0] memory_address,
	input  [15:0] memory_data,
	output rvalid, // memory address valid
	input  rready  // memory data valid
);

// Registers (from CPU)

reg fb_enable;
reg fb_enable_next;

reg [8:0] x1, x1_next;
reg [8:0] x2, x2_next;
reg [8:0] y1, y1_next;
reg [8:0] y2, y2_next;

reg [8:0] stride, stride_next; 

reg [15:0] fb_address, fb_address_next;

// Palette

reg [7:0] color_index;
wire [15:0] color_out;

assign color = 16'h0000; /*= color_out;*/

bram #(.BITS(16), .ADDRESS_BITS(8)) pal0
(
	CLK,
	color_index,
	color_out,
	ADDRESS,
	DATA_IN,
	WR_pal
);

// Scanline buffers

genvar j;

reg [8:0]  scanline_rd_addr[1:0];
reg [8:0]  scanline_wr_addr[1:0];
wire [7:0] scanline_rd_data[1:0];
reg [7:0]  scanline_wr_data[1:0];

reg scanline_wr[1:0];
reg active_buffer;
wire display_buffer = !active_buffer;
reg active_buffer_next;

generate 
for (j = 0; j < 2; j = j + 1)
begin:	scanline_buffers bram #(.BITS(8), .ADDRESS_BITS(9)) br_inst
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

// Internal registers

reg [2:0] r_state, r_state_next;

localparam r_idle  			  = 3'd0;
localparam r_begin 			  = 3'd1;
localparam r_fetch 			  = 3'd2;
localparam r_blit_and_update  = 3'd3;
localparam r_update_y		  = 3'd4;
localparam r_wait_next_scanline = 3'd5; // Wait for buffer flip before starting next blit

reg [16:0] cur_addr, cur_addr_next;
reg [16:0] prev_addr, prev_addr_next;

assign memory_address = cur_addr[16:1];

reg [16:0] x_mem_incr, x_mem_incr_next;
reg [16:0] y_mem_incr, y_mem_incr_next;

reg [7:0] cur_texel, cur_texel_next; 

reg rvalid_r;

reg [8:0] x, x_next;

assign rvalid = rvalid_r;

// Render state machine

always @(*)
begin
	r_state_next = r_state;
	
	cur_addr_next = cur_addr;
	prev_addr_next = prev_addr;
	x_mem_incr_next = x_mem_incr;
	y_mem_incr_next = y_mem_incr;
	cur_texel_next  = cur_texel;

	x_next = x;

	rvalid_r = 1'b0;

	scanline_wr_addr[0] = 9'd0;
	scanline_wr_addr[1] = 9'd0;

	scanline_wr[0] 		= 1'b0;
	scanline_wr[1] 		= 1'b0;

	scanline_wr_data[0] = 8'h00;	
	scanline_wr_data[1] = 8'h00;	

	scanline_wr_addr[active_buffer] = x;
	scanline_wr[active_buffer] = 1'b0;

	if (display_y[0] == 1'b1) begin
		scanline_wr_addr[display_buffer] = display_x[9:1] - 1;
		scanline_wr[display_buffer] = 1'b1;
	end

	active_buffer_next = active_buffer;

	if (H_tick == 1'b1) begin
		if (display_y[0] == 1'b0)
			active_buffer_next = display_buffer;	
	end

	case (r_state)
		r_idle: begin
			if (H_tick == 1'b1 && display_y[9:1] >= y1 && display_y[9:1] < y2)
				r_state_next = r_begin;
		end
		r_begin: begin

			// Set horizontal "gradients"
		
			x_mem_incr_next = {1'b0, 16'h0001};

			y_mem_incr_next = {8'd0, stride};
			cur_addr_next   = {fb_address, 1'b0};
			prev_addr_next  = {fb_address, 1'b0};

			x_next = x1;

	
			// Set starting memory offset
			r_state_next = r_fetch;
		end
		r_fetch: begin	// 2 cycles
			rvalid_r = 1'b1;
			if (rready == 1'b1) begin
				if (cur_addr[0] == 1'b1)
					cur_texel_next = memory_data[15:8];
				else
					cur_texel_next = memory_data[7:0];		
				r_state_next = r_blit_and_update;
			end
		end
		r_blit_and_update: begin // 1 cycle
			scanline_wr[active_buffer] 		= 1'b1;
			scanline_wr_data[active_buffer] = cur_texel;

			x_next = x + 1;
			if (x == x2) begin
				r_state_next = r_update_y;
				x_next = x1;
			end
			else
				r_state_next = r_fetch;
			cur_addr_next = cur_addr + x_mem_incr;
		end
		r_update_y: begin
			cur_addr_next = prev_addr + y_mem_incr;
			prev_addr_next = prev_addr + y_mem_incr;
			if (display_y[9:1] >= y2) begin
				r_state_next = r_idle;
			end
			else begin
				r_state_next = r_wait_next_scanline;
			end
		end
		r_wait_next_scanline: begin
			if (H_tick == 1'b1) begin
				r_state_next = r_fetch;
			end
		end
	endcase
end

// Buffer readout

always @(*)
begin
	scanline_rd_addr[0]  = 10'd0;
 	scanline_rd_addr[1]  = 10'd0;
  	
	scanline_rd_addr[active_buffer]  = 10'd0;
  	scanline_rd_addr[display_buffer] = display_x[9:1];
end

reg [9:0] display_x_reg;

always @(posedge CLK)
begin
	display_x_reg <= display_x;
	color_index <= scanline_rd_data[display_buffer];
end

// Register interface to CPU

always @(*)
begin
	fb_enable_next = fb_enable;
	x1_next 	   = x1;
	x2_next		   = x2;
	y1_next 	   = y1;
	y2_next		   = y2;
	
	stride_next    = stride;
	fb_address_next = fb_address;

	if (WR_reg == 1'b1)
	begin
		case (ADDRESS[3:0])
			4'd0: begin /* control reg */
				fb_enable_next = DATA_IN[0]; 
			end
			4'd1: /* x1 reg */
				x1_next = DATA_IN[8:0];
			4'd2: /* y1 reg */
				y1_next = DATA_IN[8:0];
			4'd3: /* x2 reg */
				x2_next = DATA_IN[8:0];
			4'd4: /* y2 reg */
				y2_next = DATA_IN[8:0];
			4'd9: /* stride */
				stride_next = DATA_IN[8:0];
			4'd10: /* address */
				fb_address_next = DATA_IN[15:0];
			default: ;
		endcase
	end
end

// Sequential logic

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		fb_enable <= 1'b0;
		x1 <= 9'd0;
		x2 <= 9'd0;
		y1 <= 9'd0;
		y2 <= 9'd0;
		stride <= 9'd0;
		r_state <= r_idle;
		fb_address <= 16'd0;
		cur_addr <= 17'd0;
		prev_addr <= 17'd0;
		x_mem_incr = 17'd0;
		y_mem_incr = 17'd0;
		cur_texel  = 8'd0;
		x = 9'd0;
		active_buffer = 1'b0;
	end else begin
		fb_enable <= fb_enable_next;
		x1 		  <= x1_next;
		x2 		  <= x2_next;
		y1 		  <= y1_next;
		y2 		  <= y2_next;
		r_state   <= r_state_next;
		fb_address <= fb_address_next;
		cur_addr <= cur_addr_next;
		prev_addr <= prev_addr_next;
		x_mem_incr <= x_mem_incr_next;
		y_mem_incr <= y_mem_incr_next;
		cur_texel  <= cur_texel_next;
		stride <= stride_next;
		x <= x_next;
		active_buffer <= active_buffer_next;
	end
end

endmodule
