`timescale 1 ns / 1 ps
module memory_tb;

parameter BITS 				= 16; 	/* 16 bit data */
parameter ADDRESS_BITS 		= 16; 	/* 16 bit address */

reg CLK  = 1;

always #10 CLK <= !CLK; // ~ 50MHz

reg [ADDRESS_BITS - 1:0] address;
wire [BITS - 1:0] 		 data;
reg OEb = 1;
reg WRb = 1;
reg [BITS - 1:0] datreg;

assign data = (WRb == 1'b0) ? datreg : {BITS{1'bz}};

memory_controller
#(.BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS))
mem_ctl
(
	CLK,	
	address,
	data,
	OEb, 
	WRb  
);


initial begin
	#199 address <= 16'h0004;
	OEb<=1'b0;
	#20 address <= 16'h8000;
	OEb<=1'b1;
	datreg = 16'ha5a5;
	WRb<=1'b0;
	#20 WRb<=1'b1;	
		OEb<=1'b0;
end

initial begin
    $dumpfile("memory.vcd");
    $dumpvars(0, memory_tb);
    # 100000 $finish;
end

endmodule
