/* memory.v : Memory */

module memory
#(parameter BITS = 16, ADDRESS_BITS = 15)
(
	input CLK,
	input [ADDRESS_BITS - 1 : 0]  ADDRESS,
	input [BITS - 1 : 0] DATA_IN,
	output [BITS - 1 : 0] DATA_OUT,
	input WR,  /* write memory */  
    output BUSY,
    input [ADDRESS_BITS - 1 : 0] GFX_ADDRESS,
    input GFX_REQ,
    input [BITS - 1 : 0] GFX_DATA_IN,
    input GFX_WR
);

wire [15:0] data_out1;

assign DATA_OUT = data_out1;

wire [13:0] addr = (GFX_REQ == 1'b1) ? GFX_ADDRESS[13:0] : ADDRESS[13:0];

wire busy_r = GFX_REQ;
assign BUSY = busy_r;

wire [15:0] dat = (GFX_REQ == 1'b1) ? GFX_DATA_IN : DATA_IN;

wire wr_w = (GFX_REQ == 1'b1) ? GFX_WR : WR; 

SB_SPRAM256KA spram0
(
.ADDRESS(addr),
.DATAIN(dat),
.MASKWREN(4'b1111),
.WREN(wr_w),
.CHIPSELECT(1'b1),
.CLOCK(CLK),
.STANDBY(1'b0),
.SLEEP(1'b0),
.POWEROFF(1'b1),
.DATAOUT(data_out1)
);
endmodule
