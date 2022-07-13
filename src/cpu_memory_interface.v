/*
 *	slurm16 : Memory interface
 *
 *	Simple arbiter state machine to allow instruction and data paths to
 *	access memory
 *
 *	We will pipeline this so we can clock our core fast.
 *
 *	Method: we will feed the address, data (if applicable), request type, and requestor into
 *	pipeline stage 0.
 *      In stage one, if we have access to the bank, the address and data (if
 *      applicable) will be output and the write or read will take place.
 *      In stage two, if we didn't change bank, and if the request was
 *      serviced, set the success flag for the relevant channel, indicating 
 *      the data is valid or the write was successful.
 *	
 *	If a bank switch is required, the flag "bank_sw" will be asserted
 *	following deassertion of "successful" until the bank has been
 *	switched. CPU pipeline should hold the failing instruction back in
 *	slot 2 until "bank_sw" is deasserted. If the memory operation still
 *	fails for some reason, the process will repeat until the fault clears.
 *	
 *	TODO: Read / write mask and pass back
 */

module cpu_memory_interface #(parameter BITS = 16, ADDRESS_BITS = 15)  (
	input CLK,
	input RSTb,

	/* instruction interface */
	input  [ADDRESS_BITS - 1: 0] 	instruction_memory_address,	/* requested address */
	input 			     	instruction_memory_read_req,	/* requesting a read */

	output [BITS - 1: 0]	     	instruction_memory_data,	/* data output */
	output [ADDRESS_BITS - 1: 0]	instruction_memory_address_out, /* requested address pass back */
	output 			     	instruction_memory_success,	/* 1 = read successful, 0 = read failed */
	output				instruction_will_queue,


	/* data interface */
	input  [ADDRESS_BITS - 1: 0] 	data_memory_address,
	input  [BITS - 1: 0]	     	data_memory_in,
	input				data_memory_read_req,
	input				data_memory_write_req,
	input	[1:0]			data_memory_wr_mask,

	output [BITS - 1: 0]	     	data_memory_data_out,
	output				data_memory_success,	
	output				data_memory_was_requested,
	output [1:0]			data_memory_wr_mask_out,

	/* bank switch flag : asserted when switching bank. See notes above */
	output 				bank_sw,

	output [ADDRESS_BITS: 0] 	memory_address,	/* one more bit to output address - tied low */
	output [BITS - 1 : 0]		data_out,
	input  [BITS - 1 : 0]		data_in,
	output [1:0]			wr_mask,
	output				mem_wr,
	output				valid,		/* request access to memory bank */
	input				rdy,		/* we have access to the bank */

	input				halt

);

// Output data is always whatever come from the memory interface (which may
// not be valid)

assign instruction_memory_data 	= data_in;
assign data_memory_data_out 	= data_in;

// Pipeline

reg [ADDRESS_BITS - 1 : 0] address_stage_1, address_stage_1_next;
reg [BITS - 1 : 0] 	   data_stage_1, data_stage_1_next;
reg [2:0] 		   flags_stage_1, flags_stage_1_next;	// bit 0: RD/WRb, bit 1: 1 = instruction, 0 = memory, bit 2: 1 = is requested, 0 = no requests
reg [1:0]		   data_wr_mask_stage_1, data_wr_mask_stage_1_next;

reg [ADDRESS_BITS - 1 : 0] address_stage_2;
reg [2:0] 		   flags_stage_2;
reg [1:0]		   data_wr_mask_stage_2;


assign data_out 	= data_stage_1; 
assign wr_mask		= data_wr_mask_stage_1;
assign data_memory_wr_mask_out = data_wr_mask_stage_2;

// Pipeline

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		flags_stage_2   <= 3'b000;
		address_stage_2 <= {ADDRESS_BITS{1'b0}}; 
		data_wr_mask_stage_2 <= 2'b00;
	end else begin	
		// Pipeline always advances.
		// When we are changing banks, xxx_stage_1 will be held at
		// previous value of xxx_stage_2
		flags_stage_2   <= flags_stage_1;
		address_stage_2 <= address_stage_1;
		data_wr_mask_stage_2 <= data_wr_mask_stage_1;
	end
end

// Main state machine

localparam st_idle 	   = 2'd0;	/* waiting for memory requests */
localparam st_request_bank = 2'd1;	/* request bank on target address */
localparam st_execute	   = 2'd2;	/* normal execution, with exclusive access to memory bank */
localparam st_bank_switch  = 2'd3;	/* starting a bank switch. Wait state where access to the bank is relinquished. Jump straight to request_bank */

reg [1:0] state, next_state;

reg bank_switch_required;
wire bank_switch_required_next = address_stage_2[ADDRESS_BITS - 1] != address_stage_1[ADDRESS_BITS - 1];

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		state <= st_idle;
		address_stage_1 <= {ADDRESS_BITS{1'b0}};
		data_stage_1 	<= {BITS{1'b0}};
		flags_stage_1   <= 3'b000;
		data_wr_mask_stage_1 <= 2'b00;	
		bank_switch_required <= 1'b0;
	end else begin
		state <= next_state;
		address_stage_1 <= address_stage_1_next;
		data_stage_1 	<= data_stage_1_next;
		flags_stage_1 	<= flags_stage_1_next; 
		data_wr_mask_stage_1 <= data_wr_mask_stage_1_next;
		bank_switch_required <= bank_switch_required_next;
	end
end

reg instruction_will_queue_r;

assign instruction_will_queue = instruction_will_queue_r;

always @(*)
begin
	next_state = state;

 	address_stage_1_next 	= address_stage_1;
	data_stage_1_next 	= data_stage_1;
	flags_stage_1_next 	= flags_stage_1;	
	data_wr_mask_stage_1_next = data_wr_mask_stage_1;

	instruction_will_queue_r = 1'b0;

	case (state)
		st_idle: begin
			if (data_memory_read_req || data_memory_write_req || instruction_memory_read_req)
			       next_state = st_request_bank;	
			if (data_memory_read_req || data_memory_write_req) begin
				flags_stage_1_next[0] 	= data_memory_read_req;
				flags_stage_1_next[1] 	= 1'b0;
				flags_stage_1_next[2] 	= 1'b1;
			end
		end
		st_request_bank: begin
       		
			if (data_memory_read_req || data_memory_write_req) begin
				flags_stage_1_next[0] 	= data_memory_read_req;
				flags_stage_1_next[1] 	= 1'b0;
				flags_stage_1_next[2] 	= 1'b1;
			end
		
			if (rdy == 1'b1)
				next_state = st_execute;
		end
		st_execute:
			if (bank_switch_required) begin

				next_state = st_bank_switch;
				address_stage_1_next 	= address_stage_2;
				flags_stage_1_next	= flags_stage_2;
				flags_stage_1_next[0] 	= 1'b1; // Don't explicitly write the memory until 
							       // we are executing again and the request comes
							       // in again from cpu
				data_wr_mask_stage_1_next = data_wr_mask_stage_1;

			end else if (data_memory_read_req || data_memory_write_req) begin
				
				address_stage_1_next 	= data_memory_address;
				data_stage_1_next 	= data_memory_in; 

				flags_stage_1_next[0] 	= data_memory_read_req;
				flags_stage_1_next[1] 	= 1'b0;
				flags_stage_1_next[2] 	= 1'b1;

				data_wr_mask_stage_1_next = data_memory_wr_mask;

			end else if (instruction_memory_read_req) begin

				address_stage_1_next 	= instruction_memory_address;

				flags_stage_1_next[0] 	= 1'b1;
				flags_stage_1_next[1] 	= 1'b1;
				flags_stage_1_next[2] 	= 1'b1;

				data_wr_mask_stage_1_next = 2'b00;

				instruction_will_queue_r = 1'b1;

			end else begin

				address_stage_1_next 	= {ADDRESS_BITS{1'b0}};
				flags_stage_1_next 	= 3'b000;
				data_wr_mask_stage_1_next = 2'b00;

				if (halt == 1'b1)
					next_state = st_idle;
			end
		st_bank_switch: begin
			// Wait state
			next_state = st_request_bank;
			if (data_memory_read_req || data_memory_write_req) begin
				flags_stage_1_next[0] 	= data_memory_read_req;
				flags_stage_1_next[1] 	= 1'b0;
				flags_stage_1_next[2] 	= 1'b1;
			end
		end


	endcase
end

// Determine output address

assign memory_address 	= {1'b0, address_stage_1};

assign instruction_memory_address_out = address_stage_2;

// Determine success of request

//
//	To do: register these signals
//

assign instruction_memory_success 	= (flags_stage_2[1] == 1'b1) && (flags_stage_2[2] == 1'b1) && (!bank_switch_required) && (state == st_execute);
assign data_memory_success 		= (flags_stage_2[1] == 1'b0) && (flags_stage_2[2] == 1'b1) && (!bank_switch_required) && (state == st_execute);

assign bank_sw = (state == st_bank_switch) || (state == st_request_bank);
assign valid   = (state == st_request_bank) || (state == st_execute);

assign mem_wr = (flags_stage_1[1] == 1'b0) && (flags_stage_1[0] == 1'b0) && (flags_stage_1[2] == 1'b1) && (bank_switch_required_next != 1'b1) && (state == st_execute);

assign data_memory_was_requested = (flags_stage_2[1] == 1'b0) && (flags_stage_2[2] == 1'b1);

endmodule
