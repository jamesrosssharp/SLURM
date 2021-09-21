module gpio
#(parameter BITS = 16, ADDRESS_BITS = 8, CLK_FREQ = 12000000)
(
	input CLK,	
	input RSTb,
	input [ADDRESS_BITS - 1 : 0]  ADDRESS,
	input [BITS - 1 : 0] DATA_IN,
	output [BITS - 1 : 0] DATA_OUT,
	input WR,  /* write memory */
	output [7:0] PINS /* output pins */ 
);

reg [7:0] gpio_reg;
reg [7:0] gpio_reg_next;

assign PINS = gpio_reg;

assign DATA_OUT = {BITS {1'b0}};

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		gpio_reg <= 8'h00;
	end else begin
		gpio_reg <= gpio_reg_next;
	end
end

always @(*)
begin
	gpio_reg_next = gpio_reg;

	case (ADDRESS)
		8'h00:	/* Output register */
			if (WR == 1'b1) begin
				gpio_reg_next = DATA_IN[7:0];
			end
		default:;
	endcase
end



endmodule
