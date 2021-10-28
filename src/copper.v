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

reg copper_wr_r = 1'b0;
assign COPPER_WR = copper_wr_r;

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

localparam c_state_execute = 3'd0;
localparam c_state_wait_v  = 3'd1;

reg bg_wr;

reg [2:0] c_state_r;
reg [2:0] c_state_r_next;

reg [9:0] v_wait_cnt;
reg [9:0] v_wait_cnt_next;


always @(*)
begin
	bg_wr = 1'b0;
	c_state_r_next = c_state_r;
	v_wait_cnt_next = v_wait_cnt;
	copper_list_pc_next = copper_list_pc;

	if (V_tick == 1'b1) begin
		c_state_r_next = c_state_execute;
		copper_list_pc_next = 9'd0;		
	end else begin
		case (c_state_r)
			c_state_execute: begin
				case (copper_list_ins[15:12]) 
					4'd7: begin
						bg_wr = 1'b1;
						c_state_r_next = c_state_wait_v;
						v_wait_cnt_next = display_y + 1;
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
		endcase
	end

end




// Copper memory interface

always @(*)
begin
	background_color_r_next = background_color_r;
	copper_list_WR 			= 1'b0;

	if (WR == 1'b1) begin
		casex (ADDRESS)
			12'hd20:;	/* copper X pan */
			12'hd21:;	/* copper Y flip */
			12'hd22:	/* copper background color */
				background_color_r_next = DATA_IN;
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
	end else begin
		background_color_r <= background_color_r_next;
		copper_list_pc 	   <= copper_list_pc_next;
		c_state_r 		   <= c_state_r_next;
		v_wait_cnt		   <= v_wait_cnt_next;
	end
end

endmodule
