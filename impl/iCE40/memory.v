/* memory.v : Memory */

module memory
#(parameter BITS = 16, ADDRESS_BITS = 16)
(
	input CLK,
	input [ADDRESS_BITS - 1 : 0]  ADDRESS,
	input [BITS - 1 : 0] DATA_IN,
	output [BITS - 1 : 0] DATA_OUT,
	input WRb  /* write memory */  
);

wire [15:0] data_out1;
wire [15:0] data_out2;

assign DATA_OUT = ((ADDRESS[14] == 1'b0) ? data_out1 : data_out2);

SB_SPRAM256KA spram0
(
.ADDRESS(ADDRESS[13:0]),
.DATAIN(DATA_IN),
.MASKWREN({!WRb, !WRb, !WRb, !WRb}),
.WREN(!WRb),
.CHIPSELECT(!ADDRESS[14]),
.CLOCK(CLK),
.STANDBY(1'b0),
.SLEEP(1'b0),
.POWEROFF(1'b1),
.DATAOUT(data_out1)
);

SB_SPRAM256KA spram1
(
.ADDRESS(ADDRESS[13:0]),
.DATAIN(DATA_IN),
.MASKWREN({!WRb, !WRb, !WRb, !WRb}),
.WREN(!WRb),
.CHIPSELECT(ADDRESS[14]),
.CLOCK(CLK),
.STANDBY(1'b0),
.SLEEP(1'b0),
.POWEROFF(1'b1),
.DATAOUT(data_out2)
);

endmodule
