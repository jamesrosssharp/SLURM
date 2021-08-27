module pwm_led
#(parameter BITS = 16, ADDRESS_BITS = 8, CLK_FREQ = 12000000)
(
	input CLK,	
	input RSTb,
	input [ADDRESS_BITS - 1 : 0]  ADDRESS,
	input [BITS - 1 : 0] DATA_IN,
	output [BITS - 1 : 0] DATA_OUT,
	input WRb,  /* write memory */
	output [2:0] PINS /* output pins */ 
);

reg pwm_g;
reg pwm_b;
reg pwm_r;

reg [BITS - 1:0] red_reg;
reg [BITS - 1:0] red_reg_next;

reg [BITS - 1:0] green_reg;
reg [BITS - 1:0] green_reg_next;

reg [BITS - 1:0] blue_reg;
reg [BITS - 1:0] blue_reg_next;

SB_RGBA_DRV RGBA_DRIVER (
  .CURREN(1'b1),
  .RGBLEDEN(1'b1),
  .RGB0PWM(pwm_b),
  .RGB1PWM(pwm_g),
  .RGB2PWM(pwm_r),
  .RGB0(PINS[2]),
  .RGB1(PINS[1]),
  .RGB2(PINS[0])
);

defparam RGBA_DRIVER.CURRENT_MODE = "0b1";
defparam RGBA_DRIVER.RGB0_CURRENT = "0b000111";
defparam RGBA_DRIVER.RGB1_CURRENT = "0b000111";
defparam RGBA_DRIVER.RGB2_CURRENT = "0b000111";

assign DATA_OUT = {BITS{1'b0}};

reg [BITS - 1:0] pwm_ctr = {BITS{1'b0}};


always@(posedge CLK)
begin
 pwm_r = (pwm_ctr < red_reg)   ? 1'b1 : 1'b0;
 pwm_g = (pwm_ctr < green_reg) ? 1'b1 : 1'b0;
 pwm_b = (pwm_ctr < blue_reg)  ? 1'b1 : 1'b0;
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

	casez (ADDRESS)
		8'h00:	/* red value register */
			if (WRb == 1'b0) begin
				red_reg_next = DATA_IN;
			end
		8'h01:	/* green value register */
			if (WRb == 1'b0) begin
				green_reg_next = DATA_IN;
			end
		8'h02:	/* green value register */
			if (WRb == 1'b0) begin
				blue_reg_next = DATA_IN;
			end
		default:;
	endcase
end

endmodule
