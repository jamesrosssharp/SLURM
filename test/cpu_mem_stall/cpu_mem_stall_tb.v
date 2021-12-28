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

wire  [15:0] memoryAddr;
reg   [15:0]  memoryIn;
wire  [15:0] memoryOut;
wire  memoryValid;
wire  memoryWr;

wire [3:0] irq;

localparam state_idle = 2'b00;
localparam state_grant = 2'b01;

reg [1:0] state = state_idle, state_next;

wire   memoryReady = (state == state_grant) ? 1'b1 : 1'b0;

always @(*)
begin
	state_next = state;

	case (state)
		state_idle:
			if (memoryValid == 1'b1 && !memBUSY) begin
				state_next = state_grant;
			end
		state_grant:
			if (memoryValid == 1'b0)
				state_next = state_idle;
	endcase

end

always @(posedge CLK)
begin
	state <= state_next;
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
	if (state == state_grant) begin
		if (memoryWr == 1'b1)
			memory[memoryAddr] <= memoryOut;
		memoryIn <= memory[memoryAddr];
	end else if (memBUSY == 1'b1)
		memoryIn <= 16'hbeef;
	else
		memoryIn <= 16'hdead;
end

cpu_harness cpu0 
(
	CLK,
	RSTb,
	memoryIn,
	memoryOut,
	memoryAddr,
	memoryValid,
	memoryReady,
	memoryWr,
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
