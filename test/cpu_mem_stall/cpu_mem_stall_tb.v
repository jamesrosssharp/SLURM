`timescale 1 ns / 1 ps
module cpu_mem_stall_tb;

reg CLK  = 1;

always #50 CLK <= !CLK; // ~ 10MHz

reg RSTb = 1'b0;

reg memBUSY = 1'b0;

reg [15:0] memory [65535:0];

initial begin
        $display("Loading rom.");
        $readmemh("ram_image.mem", memory);
end

wire [15:0] memoryAddr;
reg [15:0]  memoryIn;
wire [15:0] memoryOut;
wire  memoryRvalid;
reg   memoryRvalid_r;
wire  memoryRready = (memBUSY == 1'b0) ? memoryRvalid_r : 1'b0;
wire  memoryWvalid;
reg   memoryWvalid_r;
wire  memoryWready = (memBUSY == 1'b0) ? memoryWvalid_r : 1'b0;


always @(posedge CLK)
begin
	memoryRvalid_r <= memoryRvalid;
	memoryWvalid_r <= memoryWvalid;
end

initial begin
	#1000 memBUSY = 1'b0;
	#3000 memBUSY = 1'b1;
	#1000 memBUSY = 1'b0;
	#3000 memBUSY = 1'b1;
	#1000 memBUSY = 1'b0;
end

initial begin 
	#150 RSTb = 1'b1;
end

always @(posedge CLK)
begin
	if (memBUSY == 1'b0) begin
		if (memoryWvalid == 1'b1)
			memory[memoryAddr] <= memoryOut;
		memoryIn <= memory[memoryAddr];
	end else
		memoryIn <= 16'hbeef;
end

cpu_harness cpu0 
(


	CLK,
	RSTb,
	memoryIn,
	memoryOut,
	memoryAddr,
	memoryRvalid,
	memoryRready,
	memoryWvalid,
	memoryWready,
	irq
);

initial begin
    $dumpfile("cpu_mem_stall_test.vcd");
    $dumpvars(0, cpu_mem_stall_tb);
	# 1000000 $finish;
end

genvar j;
for (j = 0; j < 16; j = j + 1) begin
    initial $dumpvars(0, cpu0.reg0.regFileA[j]);
end

endmodule
