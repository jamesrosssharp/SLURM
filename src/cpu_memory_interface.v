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
	input  [ADDRESS_BITS - 1:0] store_memory_data,  /* data to store to memory */
	input  [1:0] store_memory_wr_mask,

	output [ADDRESS_BITS - 1:0] memory_address, /* memory address - to memory arbiter */
	output [BITS - 1:0]			memory_out,		/* memory output */	

	output memory_valid,						/* memory valid signal - request to mem. arbiter */
	input  memory_ready,						/* grant - from memory arbiter */
	output memory_wr,							/* write to memory */
	output [1:0] memory_wr_mask,				/* write mask to memory */

	output is_executing,						/* CPU is currently executing */
	output is_fetching,							/* CPU is currently fetching */
	output will_execute_next_cycle,				/* CPU will be executing on next cycle */


	output memory_is_instruction,				/* current value of memory in is an instruction (i.e. previous memory operation was instruction read) */

	output [ADDRESS_BITS - 1:0] memory_address_prev_plus_two,

	output [1:0] memory_wr_mask_delayed, 		/* delayed memory write mask - used in write back to select correct byte from memory */

	output stall_memory_pipeline_stage3,

	input stall

);


/* CPU state */

reg [3:0] cpu_state_r, cpu_state_r_next;

localparam cpust_halt 	 	     = 4'd0; // 0 CPU is halted; instructions not fetched
localparam cpust_execute 	     = 4'd1; // 1 CPU is executing non-memory instructions
localparam cpust_wait_mem_ready1 = 4'd2; // 2 Wait state when switching banks
localparam cpust_wait_mem_ready2 = 4'd3; // 3 CPU is waiting to access a new memory bank for fetching non-memory instructions
localparam cpust_execute_load    = 4'd4; // 4 CPU is executing load instruction
localparam cpust_wait_mem_load1  = 4'd5; // 5 Wait state when switching banks to load memory from
localparam cpust_wait_mem_load2  = 4'd6; // 6 CPU is waiting for memory grant to load from
localparam cpust_execute_store   = 4'd7; // 7 CPU is executing store instruction
localparam cpust_wait_mem_store1 = 4'd8; // 8 Wait state when switching banks to store to memory
localparam cpust_wait_mem_store2 = 4'd9; // 9 CPU is waiting for memory grant to store to
localparam cpust_pre_execute 	 = 4'd10; // 1 CPU is executing non-memory instructions
localparam cpust_wait_mem_ready1_2 = 4'd11; // 2 Wait state when switching banks
localparam cpust_wait_mem_ready2_2 = 4'd12; // 3 CPU is waiting to access a new memory bank for fetching non-memory instructions

/* addresses */

reg [ADDRESS_BITS - 1:0] next_addr_r;
reg [ADDRESS_BITS - 1:0] addr_r;
reg [ADDRESS_BITS - 1:0] prev_addr_r;

assign memory_address = {1'b0, addr_r[15:1]}; 

reg is_executing_r;

assign is_executing = is_executing_r;

reg is_fetching_r;

assign is_fetching = is_fetching_r;

reg valid_r;
reg wr_r;

assign memory_valid = valid_r;
assign memory_wr = wr_r;

reg [BITS - 1:0] memory_out_r;
assign memory_out = memory_out_r;

reg 	memory_is_instruction_r, memory_is_instruction_r_next;

reg [1:0] memory_wr_mask_r;
reg [1:0] memory_wr_mask_del_r;
assign memory_wr_mask = memory_wr_mask_r;
assign memory_wr_mask_delayed = memory_wr_mask_del_r;

reg preserve_addr_r;

assign stall_memory_pipeline_stage3 = preserve_addr_r;

/* is fetching? */

reg is_fetching_del_r;
reg is_fetching_deldel_r;

always @(posedge CLK)
begin
	is_fetching_deldel_r <= is_fetching_del_r;
	is_fetching_del_r <= is_fetching && !stall;
end


assign  memory_is_instruction = memory_is_instruction_r && is_fetching_deldel_r || (cpu_state_r == cpust_pre_execute);

reg will_execute_next_cycle_r;

assign will_execute_next_cycle = will_execute_next_cycle_r;

/* sequential logic */

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		addr_r <= {ADDRESS_BITS{1'b0}};
		cpu_state_r <= cpust_wait_mem_ready1; 	
		memory_out_r <= {BITS{1'b0}};
		memory_is_instruction_r <= 1'b0;
		memory_wr_mask_r <= 2'b11;
	end else begin
		cpu_state_r <= cpu_state_r_next;
		
		if (!preserve_addr_r) begin
			addr_r <= next_addr_r;
			prev_addr_r <= addr_r;
			if (is_executing_r) begin
				memory_out_r <= store_memory_data;
				memory_wr_mask_r <= store_memory_wr_mask;
			end
			memory_wr_mask_del_r <= memory_wr_mask_r;
		end
		
		memory_is_instruction_r <= memory_is_instruction_r_next;
	end
end

/* state machine */

function has_bank_switch;
input [ADDRESS_BITS - 1:0] addr;
input [ADDRESS_BITS - 1:0] addr2;
	has_bank_switch = (addr[ADDRESS_BITS - 1] ^ addr2[ADDRESS_BITS - 1]);
endfunction




always @(*)
begin
	cpu_state_r_next = cpu_state_r;
	memory_is_instruction_r_next = memory_is_instruction_r;
	preserve_addr_r = 1'b0;
	will_execute_next_cycle_r = 1'b0;

	case (cpu_state_r)
		cpust_halt: 
			if (wake == 1'b1) begin
				cpu_state_r_next = cpust_wait_mem_ready1;	
				will_execute_next_cycle_r = 1'b1;
			end
		/* non-memory instructions (access program memory) */
		cpust_execute: begin
			memory_is_instruction_r_next = 1'b1;
			// TODO: If we are not changing bank, we don't need the penalty
			// and can jump straight to the corresponding execute state
			if (halt == 1'b1) 
				cpu_state_r_next = cpust_halt;
			else if (load_memory == 1'b1) begin 
				// If in same bank, short circuit 
				if (! has_bank_switch(addr_r, prev_addr_r)) begin
					cpu_state_r_next = cpust_execute_load;
					will_execute_next_cycle_r = 1'b1;	
				end else 
					cpu_state_r_next = cpust_wait_mem_load1;
			end
			else if (store_memory == 1'b1) begin
				if (! has_bank_switch(addr_r, prev_addr_r)) begin
					cpu_state_r_next = cpust_execute_store;
					will_execute_next_cycle_r = 1'b1;
				end else
					cpu_state_r_next = cpust_wait_mem_store1;
			end else begin
				if (has_bank_switch(addr_r, prev_addr_r))
					cpu_state_r_next = cpust_wait_mem_ready1;
				else
					will_execute_next_cycle_r = 1'b1;
			end
		end 
		cpust_wait_mem_ready1: begin
			cpu_state_r_next = cpust_wait_mem_ready2;
			memory_is_instruction_r_next = 1'b0;
		end
		cpust_wait_mem_ready2: begin
			if (memory_ready == 1'b1) begin
				will_execute_next_cycle_r = 1'b1;
				cpu_state_r_next = cpust_execute;
			end

			memory_is_instruction_r_next = 1'b0;
		end
		cpust_wait_mem_ready1_2: begin
			cpu_state_r_next = cpust_wait_mem_ready2_2;
			memory_is_instruction_r_next = 1'b0;
		end
		cpust_wait_mem_ready2_2: begin
			if (memory_ready == 1'b1)
				cpu_state_r_next = cpust_pre_execute;
			memory_is_instruction_r_next = 1'b1;
		end
		cpust_pre_execute: begin
			cpu_state_r_next = cpust_execute;
			will_execute_next_cycle_r = 1'b1;
		end
		/* load instructions (access data memory) */
		cpust_execute_load: begin
			if (has_bank_switch(addr_r, prev_addr_r)) begin
				cpu_state_r_next = cpust_wait_mem_load1;
				preserve_addr_r = 1'b1;
			end
			else if (store_memory == 1'b1)
				if (has_bank_switch(pc, prev_addr_r)) 
					cpu_state_r_next = cpust_wait_mem_store1;
				else begin
					cpu_state_r_next = cpust_execute_store;
					will_execute_next_cycle_r = 1'b1;
				end
			else if (load_memory == 1'b0) begin
				if (has_bank_switch(addr_r, pc))
					cpu_state_r_next = cpust_wait_mem_ready1_2;
				else begin
					cpu_state_r_next = cpust_execute;
					will_execute_next_cycle_r = 1'b1;
				end
			end
			memory_is_instruction_r_next = 1'b0;
		end 
		cpust_wait_mem_load1: begin
			memory_is_instruction_r_next = 1'b0;
			cpu_state_r_next = cpust_wait_mem_load2;
		end
		cpust_wait_mem_load2: begin
			if (memory_ready == 1'b1) begin
				will_execute_next_cycle_r = 1'b1;
				cpu_state_r_next = cpust_execute_load;
			end
			memory_is_instruction_r_next = 1'b0;
		end
		/* store instructions (write to data memory) */
		cpust_execute_store: begin
			if (has_bank_switch(addr_r, prev_addr_r)) begin
				cpu_state_r_next = cpust_wait_mem_store1;
				preserve_addr_r = 1'b1;
			end
			else if (load_memory == 1'b1)
				if (has_bank_switch(pc, prev_addr_r)) 
					cpu_state_r_next = cpust_wait_mem_load1;
				else begin
					cpu_state_r_next = cpust_execute_load;	
					will_execute_next_cycle_r = 1'b1;
				end
			else if (store_memory == 1'b0) begin
				if (has_bank_switch(addr_r, pc))
					cpu_state_r_next = cpust_wait_mem_ready1_2;
				else begin	
					cpu_state_r_next = cpust_execute;
					will_execute_next_cycle_r = 1'b1;
				end
			end
			memory_is_instruction_r_next = 1'b0;
		end
		cpust_wait_mem_store1: begin
			cpu_state_r_next = cpust_wait_mem_store2;
			memory_is_instruction_r_next = 1'b0;
		end
		cpust_wait_mem_store2: begin
			if (memory_ready == 1'b1) begin
				cpu_state_r_next = cpust_execute_store;
				will_execute_next_cycle_r = 1'b1;
			end
			memory_is_instruction_r_next = 1'b0;
		end
		default:
			cpu_state_r_next = cpust_halt;
	endcase
end

/* is executing? */

always @(*) begin
	is_executing_r = 1'b0;

	case (cpu_state_r)
		cpust_execute,
		cpust_pre_execute,
		cpust_execute_load,
		cpust_execute_store:
			is_executing_r = 1'b1;
		default: ;
	endcase
end

/* is fetching? */

always @(*) begin
	is_fetching_r = 1'b0;

	if (cpu_state_r_next == cpust_execute && !has_bank_switch(addr_r, pc))
		is_fetching_r = 1'b1;
	
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
		cpust_wait_mem_ready2,
		cpust_wait_mem_ready2_2,
		cpust_pre_execute: begin
			valid_r 	 = 1'b1;
		end
		cpust_execute_load,
		cpust_wait_mem_load2: begin
			valid_r = 1'b1; 
		end
		cpust_execute_store,
		cpust_wait_mem_store2: begin
			valid_r = 1'b1; 
			if (!has_bank_switch(addr_r, prev_addr_r))
				wr_r = 1'b1;
		end
		default: ;
	endcase
end

/* previous memory address plus 2 - points to return address for instructions */

reg [ADDRESS_BITS - 1:0] prev_address_plus_two;
assign memory_address_prev_plus_two = prev_address_plus_two;

always @(posedge CLK)
begin
	prev_address_plus_two <= addr_r + 2;
end


endmodule
