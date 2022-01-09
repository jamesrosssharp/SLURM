module tb;

reg CLK = 1'b0;
reg RSTb = 1'b0;

reg load_memory = 1'b0;
reg store_memory = 1'b0;
reg halt = 1'b0;
reg wake = 1'b0;

reg [15:0] pc = 16'h0;
reg [15:0] load_store_address = 16'hbeef;

wire [15:0] memory_address;
wire memory_valid;
wire memory_ready;
wire memory_wr;

wire is_executing;
wire is_fetching;

always #50 CLK <= !CLK; // ~ 10MHz

initial begin 
	#150 RSTb = 1'b1;
end

always @(posedge CLK)
begin
	if (is_fetching)
		pc <= pc + 1;
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

initial begin
	#300 load_memory = 1'b1;
	#400 load_memory = 1'b0;
end


slurm16_cpu_memory_interface #(.BITS(16), .ADDRESS_BITS(16)) mem0 (
    CLK,
    RSTb,

    load_memory,     /* perform a load operation next */
    store_memory,    /* perform a store operation next */
    halt,            /* put the CPU to sleep */
	wake,			 /* wake up CPU */

    pc, /* pc input from pc module */
    load_store_address, /* load store address */

    memory_address, /* memory address - to memory arbiter */
    memory_valid,                        /* memory valid signal - request to mem. arbiter */
    memory_ready,                        /* grant - from memory arbiter */
    memory_wr,                           /* write to memory */

    is_executing,                         /* CPU is currently executing */
	is_fetching							  /* CPU is fetching instructions */
);

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);
	# 1000000 $finish;
end

endmodule
