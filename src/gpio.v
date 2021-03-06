module gpio
#(parameter BITS = 16, ADDRESS_BITS = 4, CLK_FREQ = 12000000)
(
	input CLK,	
	input RSTb,
	input [ADDRESS_BITS - 1 : 0]  ADDRESS,
	input [BITS - 1 : 0] DATA_IN,
	output [BITS - 1 : 0] DATA_OUT,
	input WR,  /* write memory */
	output [3:0] PINS, /* output pins */ 
	input  [5:0] INPUT_PINS,
	output irq
);

reg [3:0] gpio_reg;
reg [3:0] gpio_reg_next;

reg [5:0] gpio_in_reg_a;
reg [5:0] gpio_in_reg_b;
reg [5:0] gpio_in_reg_c;

assign PINS = gpio_reg;

reg [7:0] dout_r;

assign DATA_OUT = {8'h00, dout_r};

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		gpio_reg <= 4'h0;
		gpio_in_reg_a <= 6'h00;
		gpio_in_reg_b <= 6'h00;
		gpio_in_reg_c <= 6'h00;
	end else begin
		gpio_reg <= gpio_reg_next;
		gpio_in_reg_a <= INPUT_PINS;
		gpio_in_reg_b <= gpio_in_reg_a;
		gpio_in_reg_c <= gpio_in_reg_b;
	end
end

always @(*)
begin
	gpio_reg_next = gpio_reg;
	dout_r = 8'h00;

	case (ADDRESS)
		4'h0:	/* Output register */
			if (WR == 1'b1) begin
				gpio_reg_next = DATA_IN[3:0];
			end
		4'h1: /* Input register */
			dout_r = {2'b00, gpio_in_reg_b};
		default:;
	endcase
end

// Int on change
wire [5:0] change = gpio_in_reg_c ^ gpio_in_reg_b;
assign irq = (change == 6'd0) ? 1'b0 : 1'b1;


endmodule
