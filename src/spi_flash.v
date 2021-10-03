/*
 *
 *	Place holder for SPI master IP on iCE40 (overridden in impl)
 *
 */

module spi_flash
#(parameter BITS = 16, ADDRESS_BITS = 8, CLK_FREQ = 25125000)
(
	input CLK,	
	input RSTb,
	input [ADDRESS_BITS - 1 : 0]  ADDRESS,
	input [BITS - 1 : 0] DATA_IN,
	output [BITS - 1 : 0] DATA_OUT,
	input WR,  /* write memory */
	output MOSI,
	output SSb,
	output SCK,
	input MISO
);

reg [7:0] address_r;
reg [7:0] address_r_next;

reg [7:0] data_in_r;
reg [7:0] data_in_r_next;

reg [7:0] cmd_r;
reg [7:0] cmd_r_next;

reg [7:0] data_out_r = 8'h00;

reg [7:0] status_r = 8'h00;

reg [BITS - 1 : 0] dout_r;

assign DATA_OUT = dout_r;

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		address_r  <= 8'h00;
		data_in_r <= 8'h00;
		status_r   <= 8'h00;
	end else begin
		address_r  <= address_r_next;
		data_in_r  <= data_in_r_next;
		cmd_r      <= cmd_r_next;
	end
end

always @(*)
begin

	address_r_next = address_r;
	data_in_r_next = data_in_r;
	cmd_r_next = cmd_r;

	dout_r = {BITS{1'b0}};

	case (ADDRESS)
		8'h00:	/* Address reg */
			if (WR == 1'b1) begin
				address_r_next = DATA_IN[7:0];
			end
		8'h01: /* Data out reg */
			dout_r = data_out_r;
		8'h02: /* Data in reg */
			if (WR == 1'b1) begin
				data_in_r_next = DATA_IN[7:0];
			end
		8'h03: /* Command bits reg */
			if (WR == 1'b1) begin
				cmd_r_next = DATA_IN[7:0];
			end
		8'h04: /* Status bits reg */
			dout_r = status_r;
		default:;
	endcase
end

endmodule
