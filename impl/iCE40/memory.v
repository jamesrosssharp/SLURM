/* memory.v : Memory */

module memory
#(parameter BITS = 16, ADDRESS_BITS = 15)
(
	input CLK,
	input [ADDRESS_BITS - 1 : 0]  ADDRESS,
	input [BITS - 1 : 0] DATA_IN,
	output [BITS - 1 : 0] DATA_OUT,
	input WR,  /* write memory */  

	input [ADDRESS_BITS - 1 : 0] GFX_ADDRESS,
    input GFX_VALID,
    output GFX_READY

);

wire [15:0] data_out1;

assign DATA_OUT = data_out1;

reg [13:0] addr = (GFX_VALID == 1'b1) ? GFX_ADDRESS[13:0] : ADDRESS[13:0];

reg ready;

assign GFX_READY = ready;

wire wr_w = (GFX_VALID == 1'b1) ? 1'b0 : WR; 

always @(posedge CLK)
begin
	if (GFX_VALID == 1'b1 && ready == 1'b0)
		ready <= 1'b1;
	else
		ready <= 1'b0;
end

SB_SPRAM256KA spram0
(
.ADDRESS(addr),
.DATAIN(DATA_IN),
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
