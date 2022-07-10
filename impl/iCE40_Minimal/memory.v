/* memory.v : Memory */

module memory
#(parameter BITS = 16, ADDRESS_BITS = 15, MEM_INIT_FILE = "mem_init.rom")
(
	input CLK,
	input [ADDRESS_BITS - 1 : 0]  ADDRESS,
	input [BITS - 1 : 0] DATA_IN,
	output [BITS - 1 : 0] DATA_OUT,
	input [1:0] MASK,
	input WR,  /* write memory */  
);

wire [15:0] data_out1;

assign DATA_OUT = data_out1;

wire [3:0] mask_wren = {MASK[1], MASK[1], MASK[0], MASK[0]};

SB_SPRAM256KA spram0
(
.ADDRESS(ADDRESS),
.DATAIN(DATA_IN),
.MASKWREN(mask_wren),
.WREN(WR),
.CHIPSELECT(1'b1),
.CLOCK(CLK),
.STANDBY(1'b0),
.SLEEP(1'b0),
.POWEROFF(1'b1),
.DATAOUT(data_out1)
);
endmodule
