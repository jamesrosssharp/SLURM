/*
 *
 *	copper: gfx co-processor
 *
 *	can write any gfx core register, and perform jumps and loops
 *
 */

module copper (
	input  CLK,
	input  RSTb,

	input  [11:0] ADDRESS,
	input  [15:0] DATA_IN,
	input  WR,

	input V_tick,
	input H_tick,

	input [9:0]   display_x,
	input [9:0]   display_y,

	// Copper can override address and WR signal to write to gfx registers
	output [11:0] COPPER_ADDRESS,
	output COPPER_WR,
	output [15:0] COPPER_DATA_OUT,

	output [11:0] background_color,	

	// Copper can modulate x and y coordinates to e.g. flip or pan the whole display
	// Individual layers can be panned with each core's pan registers
	output [9:0]  display_x_out,
	output [9:0]  display_y_out

);

reg [11:0] background_color_r;
reg [11:0] background_color_r_next;

assign background_color = background_color_r;

// Copper list memory

reg [8:0] copper_list_pc;
reg [8:0] copper_list_pc_next;

wire [15:0] copper_list_ins;

reg copper_list_WR;

bram
#(.BITS(16), .ADDRESS_BITS(9))
coplist0
(
	CLK,
	copper_list_pc,
	copper_list_ins,
	
	ADDRESS[8:0],
	DATA_IN,
	copper_list_WR
);

// Copper execution

localparam c_state_begin   = 3'd0;
localparam c_state_execute = 3'd1;
localparam c_state_wait_v  = 3'd2;
localparam c_state_wait_h  = 3'd3;
localparam c_state_write_reg = 3'd4;

reg bg_wr;

reg [2:0] c_state_r;
reg [2:0] c_state_r_next;

reg [9:0] v_wait_cnt;
reg [9:0] v_wait_cnt_next;

reg [11:0] c_addr_r;
reg [11:0] c_addr_r_next;

reg [15:0] c_dat;
reg [15:0] c_dat_next;

reg copper_wr_r;
reg copper_wr_r_next;

assign COPPER_ADDRESS 	= c_addr_r;
assign COPPER_WR 		= copper_wr_r;
assign COPPER_DATA_OUT 	= c_dat;

reg cpr_en;
reg cpr_en_next;

reg [9:0] y_flip;
reg [9:0] y_flip_next;

reg y_flip_en;
reg y_flip_en_next;

reg [9:0] x_pan;
reg [9:0] x_pan_next;
reg x_pan_wr;

reg [9:0] display_y_out_r;
reg [9:0] display_y_out_r_next;

assign display_y_out = display_y_out_r;

reg [9:0] display_x_out_r;

assign display_x_out = display_x_out_r;

// Y flip

always @(*)
begin
	if (y_flip_en == 1'b1) begin
		if (display_y >= y_flip)
			display_y_out_r_next = y_flip + y_flip - display_y;
		else
			display_y_out_r_next = display_y;
	end else 
		display_y_out_r_next = display_y;
end

always @(posedge CLK)
begin
	display_y_out_r = display_y_out_r_next;
end

// X pan

always @(posedge CLK)
begin
	display_x_out_r_next <= display_x + x_pan; 
end

// Copper execution

always @(*)
begin
	bg_wr = 1'b0;
	c_state_r_next = c_state_r;
	v_wait_cnt_next = v_wait_cnt;
	copper_list_pc_next = copper_list_pc;
	copper_wr_r_next = 1'b0;
	c_addr_r_next = c_addr_r;
	c_dat_next = c_dat;

	if (V_tick == 1'b1) begin
		c_state_r_next = c_state_begin;
		copper_list_pc_next = 9'd0;		
	end else begin
		case (c_state_r)
			c_state_begin: 
				if (cpr_en == 1'b1)
					c_state_r_next = c_state_execute;
			c_state_execute: begin
				case (copper_list_ins[15:12]) 
					4'd1: begin /* jump */
						copper_list_pc_next = copper_list_ins[11:0];
						c_state_r_next = c_state_begin; // synchronize
					end
					4'd2: begin /* V wait */
						c_state_r_next = c_state_wait_v;
						v_wait_cnt_next = copper_list_ins[9:0];	
					end
					4'd3: begin /* H wait */
						c_state_r_next = c_state_wait_h;
						v_wait_cnt_next = copper_list_ins[9:0];	
					end
					4'd4: begin /* skip V */
						if (display_y >= copper_list_ins[9:0]) begin
							copper_list_pc_next = copper_list_pc + 1;
							c_state_r_next = c_state_begin; // synchronize
						end
						else
							copper_list_pc_next = copper_list_pc + 1;
							
					end
					4'd5: begin /* skip H */
						if (display_x >= copper_list_ins[9:0]) begin
							copper_list_pc_next = copper_list_pc + 2;
							c_state_r_next = c_state_begin; // synchronize
						end
						else
							copper_list_pc_next = copper_list_pc + 1;
	
					end
					4'd6: begin /* update background color and wait next scanline */
						bg_wr = 1'b1;
						c_state_r_next = c_state_wait_v;
						v_wait_cnt_next = display_y + 1;
					end
					4'd7: begin /* V wait N */
						c_state_r_next = c_state_wait_v;
						v_wait_cnt_next = display_y + copper_list_ins[9:0];	
					end
					4'd8: begin /* H wait N */
						c_state_r_next = c_state_wait_h;
						v_wait_cnt_next = display_x + copper_list_ins[9:0];		
					end
					4'd9: begin /* write gfx register */
						c_state_r_next = c_state_write_reg;
						copper_list_pc_next = copper_list_pc + 1;
						c_addr_r_next = copper_list_ins[11:0];
					end
					default:
						copper_list_pc_next = copper_list_pc + 1;
				endcase
			end	
			c_state_wait_v: begin
				if (display_y >= v_wait_cnt) begin
					c_state_r_next = c_state_execute;
					copper_list_pc_next = copper_list_pc + 1;
				end					
			end
			c_state_wait_h: begin
				if (display_x >= v_wait_cnt) begin
					c_state_r_next = c_state_execute;
					copper_list_pc_next = copper_list_pc + 1;
				end					
			end
			c_state_write_reg: begin
				c_dat_next = copper_list_ins;
				copper_wr_r_next = 1'b1;	
				copper_list_pc_next = copper_list_pc + 1;
				c_state_r_next = c_state_execute;	
			end
		endcase
	end
end

// Copper memory interface

always @(*)
begin
	background_color_r_next = background_color_r;
	copper_list_WR 			= 1'b0;
	cpr_en_next 			= cpr_en;
	x_pan_next				= x_pan;
	y_flip_next				= y_flip;
	y_flip_en_next			= y_flip_en;

	if (WR == 1'b1) begin
		casex (ADDRESS)
			12'hd20:	/* copper control */
				cpr_en_next = DATA_IN[0];
			12'hd21: begin	/* copper Y flip */
				y_flip_next = DATA_IN[9:0];
				y_flip_en_next = DATA_IN[15];
			end
			12'hd22:	/* copper background color */
				background_color_r_next = DATA_IN[11:0];
			12'hd23:	/* x pan */
				x_pan_next = DATA_IN[9:0];
			12'h4xx, 12'h5xx:  /* copper list memory */
				copper_list_WR = 1'b1;
		endcase
	end

	if (bg_wr == 1'b1)
		background_color_r_next = copper_list_ins[11:0];
end

// Sequential logic

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		background_color_r <= 12'hf00;
		copper_list_pc <= 9'd0;
		c_state_r <= c_state_execute;
		v_wait_cnt <= 10'd0;
		c_addr_r <= 12'd0;
		cpr_en <= 1'b0;
		c_dat <= 16'h0000;
		copper_wr_r <= 1'b0;	
		y_flip <= 10'd0;
		x_pan <= 10'd0;
		y_flip_en <= 1'b0;	
	end else begin
		background_color_r <= background_color_r_next;
		copper_list_pc 	   <= copper_list_pc_next;
		c_state_r 		   <= c_state_r_next;
		v_wait_cnt		   <= v_wait_cnt_next;
		c_addr_r 		   <= c_addr_r_next;
		cpr_en 			   <= cpr_en_next;
		c_dat <= c_dat_next;
		copper_wr_r <= copper_wr_r_next;
		y_flip <= y_flip_next;
		x_pan <= x_pan_next;
		y_flip_en <= y_flip_en_next;
	end
end

endmodule
