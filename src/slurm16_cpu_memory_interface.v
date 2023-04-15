/*
 *	slurm16 : Memory interface
 *
 */

module slurm16_cpu_memory_interface #(parameter BITS = 16, ADDRESS_BITS = 16)  (
	input CLK,
	input RSTb,

	/* instruction interface */
	input  [ADDRESS_BITS - 2: 0] 	instruction_memory_address,	/* requested address */
	input 			     	instruction_memory_read_req,	/* requesting a read */

	output [BITS - 1: 0]	     	instruction_memory_data,	/* data output */
	output [ADDRESS_BITS - 2: 0]	instruction_memory_address_out, /* requested address pass back */
	output 			     	instruction_memory_success,	/* 1 = read successful, 0 = read failed */

	/* data interface */
	input  [ADDRESS_BITS - 1: 0] 	data_memory_address,
	input  [BITS - 1: 0]	     	data_memory_in,
	input				data_memory_read_req,
	input				data_memory_write_req,
	input	[1:0]			data_memory_wr_mask,

	output [BITS - 1: 0]	     	data_memory_data_out,
	output				data_memory_success,	
	output [1:0]			data_memory_wr_mask_out,

	/* output to memory arbiter */
	output [ADDRESS_BITS - 1 : 0] 	memory_address,	/* one more bit to output address - tied low */
	output [BITS - 1 : 0]		data_out,
	input  [BITS - 1 : 0]		data_in,
	output [1:0]			wr_mask,
	output				mem_wr,
	input				memory_success
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
reg [BITS - 1 : 0] 	   data_stage_2;

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
		data_stage_2 <= 16'h0000;
	end else begin	
		flags_stage_2   <= flags_stage_1;
		address_stage_2 <= address_stage_1;
		data_wr_mask_stage_2 <= data_wr_mask_stage_1;
		data_stage_2 <= data_stage_1;
	end
end

// Main state machine

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		address_stage_1 <= {ADDRESS_BITS{1'b0}};
		data_stage_1 	<= {BITS{1'b0}};
		flags_stage_1   <= 3'b000;
		data_wr_mask_stage_1 <= 2'b00;	
	end else begin
		address_stage_1 <= address_stage_1_next;
		data_stage_1 	<= data_stage_1_next;
		flags_stage_1 	<= flags_stage_1_next; 
		data_wr_mask_stage_1 <= data_wr_mask_stage_1_next;
	end
end

always @(*)
begin

 	address_stage_1_next 	= address_stage_1;
	data_stage_1_next 	= data_stage_1;
	flags_stage_1_next 	= flags_stage_1;	
	data_wr_mask_stage_1_next = data_wr_mask_stage_1;

	if (data_memory_read_req || data_memory_write_req) begin
				
		address_stage_1_next 	= data_memory_address;
		data_stage_1_next 	= data_memory_in; 

		flags_stage_1_next[0] 	= data_memory_read_req;
		flags_stage_1_next[1] 	= 1'b0;
		flags_stage_1_next[2] 	= 1'b1;

		data_wr_mask_stage_1_next = data_memory_wr_mask;

	end else if (instruction_memory_read_req) begin

		address_stage_1_next 	= {1'b0, instruction_memory_address};

		flags_stage_1_next[0] 	= 1'b1;
		flags_stage_1_next[1] 	= 1'b1;
		flags_stage_1_next[2] 	= 1'b1;

		data_wr_mask_stage_1_next = 2'b00;

	end else begin
		flags_stage_1_next 	= 3'b000;
		data_wr_mask_stage_1_next = 2'b00;
	end
end

// Determine output address

assign memory_address 	= address_stage_1;

assign instruction_memory_address_out = address_stage_2;

assign instruction_memory_success 	= (flags_stage_2[1] == 1'b1) && (flags_stage_2[2] == 1'b1) && (memory_success);
assign data_memory_success 		= (flags_stage_2[1] == 1'b0) && (flags_stage_2[2] == 1'b1) && (memory_success);

assign mem_wr = (flags_stage_1[1] == 1'b0) && (flags_stage_1[0] == 1'b0) && (flags_stage_1[2] == 1'b1);

endmodule
