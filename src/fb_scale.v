/*
 *
 *	fb_scale.v : draw a scaled framebuffer to area of screen
 *
 *	8-bit gfx, has custom palette
 *
 *  2-pixels per cycle blit
 *
 *  Can only scale up, cannot scale down
 *
 *  Can flip image vertically or horizontally, but no rotation or affine transformation
 */

module fb_scale
(
	input  CLK,
	input  RSTb,

	input  [8:0] ADDRESS,
	input  [15:0] DATA_IN,
	input  WR_reg,
	input  WR_pal,

	/* single cycle tick when vertical count is zero */
	input V_tick,
	/* single cycle tick horizontal count is zero */
	input H_tick,

	/* display uses this channel to read scanline block RAM */
	input [9:0]   display_x_,
	input [9:0]   display_y,
	input         re,	// render enable
	output [15:0] color,  // ARGB 4:4:4:4

	/* memory channel to memory arbiter */
	output [15:0] memory_address,
	input  [15:0] memory_data,
	output rvalid, // memory address valid
	input  rready  // memory data valid
);

// Registers

reg fb_enable;
reg fb_enable_next;

reg [9:0] x1, x1_next;
reg [9:0] x2, x2_next;
reg [9:0] y1, y1_next;
reg [9:0] y2, y2_next;

reg [9:0] u1, u1_next;
reg [9:0] u2, u2_next;
reg [9:0] v1, v1_next;
reg [9:0] v2, v2_next;

// Register interface to CPU

always @(*)
begin
	fb_enable_next = fb_enable;
	x1_next 	   = x1;
	x2_next		   = x2;
	y1_next 	   = y1;
	y2_next		   = y2;
	u1_next 	   = u1;
	u2_next		   = u2;
	v1_next 	   = v1;
	v2_next		   = v2;

	if (WR_reg == 1'b1)
	begin
		case (ADDRESS)
			4'd0: begin /* control reg */
				fb_enable_next = DATA_IN[0]; 
			end
			4'd1: /* x1 reg */
				x1_next = DATA_IN[9:0];
			4'd2: /* y1 reg */
				y1_next = DATA_IN[9:0];
			4'd3: /* x2 reg */
				x2_next = DATA_IN[9:0];
			4'd4: /* y2 reg */
				y2_next = DATA_IN[9:0];
			4'd5: /* u1 reg */
				u1_next = DATA_IN[9:0];
			4'd6: /* v1 reg */
				v1_next = DATA_IN[9:0];
			4'd7: /* u2 reg */
				u2_next = DATA_IN[9:0];
			4'd8: /* v2 reg */
				v2_next = DATA_IN[9:0];	
			default: ;
		endcase
	end
end

// Sequential logic

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		fb_enable <= 1'b0;
		x1 <= 10'd0;
		x2 <= 10'd0;
		y1 <= 10'd0;
		y2 <= 10'd0;
		u1 <= 10'd0;
		u2 <= 10'd0;
		v1 <= 10'd0;
		v2 <= 10'd0;
	end else begin
		fb_enable <= fb_enable_next;
		x1 		  <= x1_next;
		x2 		  <= x2_next;
		y1 		  <= y1_next;
		y2 		  <= y2_next;
		u1 		  <= u1_next;
		u2 		  <= u2_next;
		v1 		  <= v1_next;
		v2 		  <= v2_next;
	end
end

endmodule
