/* memory.v : Memory */

module memory
#(parameter BITS = 16, ADDRESS_BITS = 15, MEM_INIT_FILE = "mem_init.rom")
(
	input CLK,
	input [ADDRESS_BITS - 1 : 0]  ADDRESS,
	input [BITS - 1 : 0] DATA_IN,
	output [BITS - 1 : 0] DATA_OUT,
	input WR  /* write memory */  
);

reg [BITS - 1:0] RAM [(1 << ADDRESS_BITS) - 1:0];
reg [BITS - 1:0] dout;

assign DATA_OUT = dout;

// Initialise memory contents in simulation, so we don't have to bootstrap using a dummy flash controller
initial begin
        $display("Loading memory contents.");
        $readmemh(MEM_INIT_FILE, RAM);
end

always @(posedge CLK)
begin
	if (WR == 1'b1)
		RAM[ADDRESS] <= DATA_IN;
	dout <= RAM[ADDRESS];
end

endmodule
