module pwm_led
#(parameter BITS = 16, ADDRESS_BITS = 4, CLK_FREQ = 12000000)
(
	input CLK,	
	input RSTb,
	input [ADDRESS_BITS - 1 : 0]  ADDRESS,
	input [BITS - 1 : 0] DATA_IN,
	output [BITS - 1 : 0] DATA_OUT,
	input WR,  /* write memory */
	output [2:0] PINS /* output pins */ 
);

wire pwm_g;
wire pwm_b;
wire pwm_r;

reg [BITS - 1:0] red_reg;
reg [BITS - 1:0] red_reg_next;

reg [BITS - 1:0] green_reg;
reg [BITS - 1:0] green_reg_next;

reg [BITS - 1:0] blue_reg;
reg [BITS - 1:0] blue_reg_next;

assign DATA_OUT = {BITS{1'b0}};

reg [BITS - 1:0] pwm_ctr = {BITS{1'b0}};

assign pwm_r = (pwm_ctr < red_reg)   ? 1'b1 : 1'b0;
assign pwm_g = (pwm_ctr < green_reg) ? 1'b1 : 1'b0;
assign pwm_b = (pwm_ctr < blue_reg)  ? 1'b1 : 1'b0;

assign PINS[0] = pwm_r;
assign PINS[1] = pwm_g;
assign PINS[2] = pwm_b;



always@(posedge CLK)
begin
  pwm_ctr <= pwm_ctr + 1;
end

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		red_reg <= {BITS{1'b0}};
		green_reg <= {BITS{1'b0}};
		blue_reg <= {BITS{1'b0}};
	end else begin
		red_reg   <= red_reg_next;
		green_reg <= green_reg_next;
		blue_reg  <= blue_reg_next;
	end
end

always @(*)
begin
	red_reg_next   = red_reg;
	green_reg_next = green_reg;
	blue_reg_next  = blue_reg;

	case (ADDRESS)
		4'h0:	/* red value register */
			if (WR == 1'b1) begin
				red_reg_next = DATA_IN;
			end
		4'h1:	/* green value register */
			if (WR == 1'b1) begin
				green_reg_next = DATA_IN;
			end
		4'h2:	/* green value register */
			if (WR == 1'b1) begin
				blue_reg_next = DATA_IN;
			end
		default:;
	endcase
end

endmodule
