/*
 *	slurm16 : Memory interface
 *
 */

module slurm16_cpu_memory_interface #(parameter BITS = 16, ADDRESS_BITS = 16)  (
	input CLK,
	input RSTb,

	input  load_memory, 	/* perform a load operation next */
	input  store_memory,	/* perform a store operation next */
	input  halt,			/* put the CPU to sleep */
	input  wake,			/* wake the CPU up */

	input  [ADDRESS_BITS - 1:0] pc, /* pc input from pc module */
	input  [ADDRESS_BITS - 1:0] load_store_address, /* load store address */

	output [ADDRESS_BITS - 1:0] memory_address, /* memory address - to memory arbiter */
	output memory_valid,						/* memory valid signal - request to mem. arbiter */
	input  memory_ready,						/* grant - from memory arbiter */
	output memory_wr,							/* write to memory */

	output is_executing,						/* CPU is currently executing */
	output is_fetching							/* CPU is currently fetching */

);

/* CPU state */

reg [3:0] cpu_state_r, cpu_state_r_next;

localparam cpust_halt 	 	     = 4'b0000; // 0 CPU is halted; instructions not fetched
localparam cpust_execute 	     = 4'b0001; // 1 CPU is executing non-memory instructions
localparam cpust_wait_mem_ready1 = 4'b0010; // 2 Wait state when switching banks
localparam cpust_wait_mem_ready2 = 4'b0011; // 3 CPU is waiting to access a new memory bank for fetching non-memory instructions
localparam cpust_execute_load    = 4'b0100; // 4 CPU is executing load instruction
localparam cpust_wait_mem_load1  = 4'b0101; // 5 Wait state when switching banks to load memory from
localparam cpust_wait_mem_load2  = 4'b0110; // 6 CPU is waiting for memory grant to load from
localparam cpust_execute_store   = 4'b0111; // 7 CPU is executing store instruction
localparam cpust_wait_mem_store1 = 4'b1000; // 8 Wait state when switching banks to store to memory
localparam cpust_wait_mem_store2 = 4'b1001; // 9 CPU is waiting for memory grant to store to
 
/* addresses */

reg [ADDRESS_BITS - 1:0] next_addr_r;
reg [ADDRESS_BITS - 1:0] addr_r;

assign memory_address = addr_r; 

reg is_executing_r;

assign is_executing = is_executing_r;

reg is_fetching_r;

assign is_fetching = is_fetching_r;

reg valid_r;
reg wr_r;

assign memory_valid = valid_r;
assign memory_wr = wr_r;

/* sequential logic */

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		addr_r <= {ADDRESS_BITS{1'b0}};
		cpu_state_r <= cpust_wait_mem_ready1; 	
	end else begin
		addr_r <= next_addr_r;
		cpu_state_r <= cpu_state_r_next;
	end
end

/* state machine */

function has_bank_switch;
input [ADDRESS_BITS - 1:0] addr;
input [ADDRESS_BITS - 1:0] addr2;
	has_bank_switch = (addr[ADDRESS_BITS - 1:ADDRESS_BITS - 2] != addr2[ADDRESS_BITS - 1:ADDRESS_BITS - 2]);
endfunction

always @(*)
begin
	cpu_state_r_next = cpu_state_r;

	case (cpu_state_r)
		cpust_halt: 
			if (wake == 1'b1)
				cpu_state_r_next = cpust_wait_mem_ready1;	
		/* non-memory instructions (access program memory) */
		cpust_execute: begin
			// TODO: If we are not changing bank, we don't need the penalty
			// and can jump straight to the corresponding execute state
			if (halt == 1'b1) 
				cpu_state_r_next = cpust_halt;
			else if (load_memory == 1'b1) begin 
				// If in same bank, short circuit 
				if (! has_bank_switch(addr_r, next_addr_r))
					cpu_state_r_next = cpust_execute_load;
				else 
					cpu_state_r_next = cpust_wait_mem_load1;
			end
			else if (store_memory == 1'b1) begin
				if (! has_bank_switch(addr_r, next_addr_r))
					cpu_state_r_next = cpust_execute_store;
				else
					cpu_state_r_next = cpust_wait_mem_store1;
			end else begin
				if (has_bank_switch(addr_r, next_addr_r))
					cpu_state_r_next = cpust_wait_mem_ready1;
			end
		end 
		cpust_wait_mem_ready1:
			cpu_state_r_next = cpust_wait_mem_ready2;
		cpust_wait_mem_ready2:
			if (memory_ready == 1'b1)
				cpu_state_r_next = cpust_execute;
		/* load instructions (access data memory) */
		cpust_execute_load: begin
			if (load_memory == 1'b0) begin
				if (! has_bank_switch(addr_r, next_addr_r))
					cpu_state_r_next = cpust_execute;
				else
					cpu_state_r_next = cpust_wait_mem_ready1;
			end
			else if (has_bank_switch(addr_r, next_addr_r))
				cpu_state_r_next = cpust_wait_mem_load1;
		end 
		cpust_wait_mem_load1:
			cpu_state_r_next = cpust_wait_mem_load2;
		cpust_wait_mem_load2:
			if (memory_ready == 1'b1)
				cpu_state_r_next = cpust_execute_load;
		/* store instructions (write to data memory) */
		cpust_execute_store: begin
			if (store_memory == 1'b0) begin
				if (! has_bank_switch(addr_r, next_addr_r))
					cpu_state_r_next = cpust_execute;
				else
					cpu_state_r_next = cpust_wait_mem_ready1;
			end
			else if (has_bank_switch(addr_r, next_addr_r))
				cpu_state_r_next = cpust_wait_mem_store1;
		end
		cpust_wait_mem_store1:
			cpu_state_r_next = cpust_wait_mem_store2;
		cpust_wait_mem_store2:
			if (memory_ready == 1'b1)
				cpu_state_r_next = cpust_execute_store;
		default:
			cpu_state_r_next = cpust_halt;
	endcase
end

/* is executing? */

always @(*) begin
	is_executing_r = 1'b0;

	case (cpu_state_r)
		cpust_execute,
		cpust_execute_load,
		cpust_execute_store:
			is_executing_r = 1'b1;
	endcase
end

/* is fetching? */

always @(*) begin
	is_fetching_r = 1'b0;

	case (cpu_state_r)
		cpust_execute:
			is_fetching_r = 1'b1;
	endcase
end



/* address loading */

always @(*) 
begin
	next_addr_r = addr_r;

	if (is_executing_r)
		if (load_memory || store_memory)
			next_addr_r = load_store_address;
		else
			next_addr_r = pc;
end

/* address valid */

always @(*)
begin
	valid_r = 1'b0;
	wr_r = 1'b0;

	case (cpu_state_r)
		cpust_execute,
		cpust_wait_mem_ready2: begin
			valid_r 	 = 1'b1;
		end
		cpust_execute_load,
		cpust_wait_mem_load2: begin
			valid_r = 1'b1; 
		end
		cpust_execute_store,
		cpust_wait_mem_store2: begin
			valid_r = 1'b1; 
			wr_r = 1'b1;
		end
		default: ;
	endcase
end



endmodule
