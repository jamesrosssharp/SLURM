module tb;

reg CLK = 1'b0;
reg RSTb = 1'b0;

always #50 CLK <= !CLK; // ~ 10MHz

initial begin 
	#150 RSTb = 1'b1;
end

wire [15:0] memory_address;
reg  [15:0] memory_in;
wire [15:0] memory_out;
wire memory_wr;
wire memory_valid;
wire  memory_ready;

wire [15:0] port_address;
wire [15:0] port_in;
wire [15:0] port_out;
wire port_wr;
wire port_rd;

wire [3:0] irq = 4'd0;

// Memory interface logic

reg [15:0] memory [65535:0];

initial begin
        $display("Loading rom.");
        $readmemh("ram_image.mem", memory);
end

// State machine for memory simulation

localparam state_idle = 2'b00;
localparam state_grant = 2'b01;

reg [1:0] state = state_idle, state_next;

reg memBUSY = 1'b0;

always @(*)
begin
	state_next = state;

	case (state)
		state_idle:
			if (memory_valid == 1'b1 && !memBUSY) begin
				state_next = state_grant;
			end
		state_grant:
			if (memory_valid == 1'b0)
				state_next = state_idle;
	endcase

end

always @(posedge CLK)
begin
	state <= state_next;
end

assign   memory_ready = (state == state_grant) ? 1'b1 : 1'b0;

always @(posedge CLK)
begin
	if (state == state_grant) begin
		if (memory_wr == 1'b1)
			memory[memory_address] <= memory_out;
		memory_in <= memory[memory_address];
	end else if (memBUSY == 1'b1)
		memory_in <= 16'hbeef;
	else
		memory_in <= 16'hdead;
end

slurm16_cpu_top top0
(
    CLK,
    RSTb,

    memory_address,
    memory_in,
    memory_out,
    memory_valid,   /* memory request */
    memory_wr,      /* memory write */
    memory_ready,   /* memory ready - from arbiter */

    port_address,
    port_in,
    port_out,
    port_rd,
    port_wr,

    irq         /* interrupt lines */
);

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);
	# 20000 $finish;
end

genvar j;
for (j = 0; j < 16; j = j + 1) begin
    initial $dumpvars(0, top0.reg0.regFileA[j]);
end



endmodule
