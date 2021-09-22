/* memory.v : Memory */

module memory
#(parameter BITS = 16, ADDRESS_BITS = 15)
(
	input CLK,
	input [ADDRESS_BITS - 1 : 0]  ADDRESS,
	input [BITS - 1 : 0] DATA_IN,
	output [BITS - 1 : 0] DATA_OUT,
	input WR  /* write memory */  
);

wire [15:0] data_out1;

assign DATA_OUT = data_out1;

SB_SPRAM256KA spram0
(
.ADDRESS(ADDRESS[13:0]),
.DATAIN(DATA_IN),
.MASKWREN(4'b1111),
.WREN(WR),
.CHIPSELECT(1'b1),
.CLOCK(CLK),
.STANDBY(1'b0),
.SLEEP(1'b0),
.POWEROFF(1'b1),
.DATAOUT(data_out1)
);
endmodule
