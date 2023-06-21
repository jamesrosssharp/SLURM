/*
 *	slurm16 : Memory interface
 *
 */

module slurm16_cpu_memory_interface #(parameter BITS = 16, ADDRESS_BITS = 16)  (
	input CLK,
	input RSTb,

	/* instruction interface */
	input  [ADDRESS_BITS - 2: 0] 	instruction_memory_address,	/* requested address */
	output [BITS - 1: 0]	     	instruction_memory_data,	/* data output */
	output reg [ADDRESS_BITS - 2: 0] instruction_memory_address_out, /* requested address pass back */
	output 			     	instruction_memory_success,	/* 1 = read successful, 0 = read failed */

	/* data interface */
	input  [ADDRESS_BITS - 1: 0] 	data_memory_address,
	input  [BITS - 1: 0]	     	data_memory_in,
	input				data_memory_read_req,
	input				data_memory_write_req,
	input	[1:0]			data_memory_wr_mask,

	output [BITS - 1: 0]	     	data_memory_data_out,
	output				data_memory_success,	
	output reg [1:0]		data_memory_wr_mask_out,

	/* data memory output to memory arbiter */
	output reg [ADDRESS_BITS - 1 : 0] 	memory_address,	
	output reg [BITS - 1 : 0]		data_out,
	input  [BITS - 1 : 0]		data_in,
	output reg [1:0]		wr_mask,
	output reg			mem_wr,
	output reg			mem_rd,
	input				memory_success,

	/* instruction memory output to memory arbiter */

	output [ADDRESS_BITS - 2 : 0] 	i_memory_address,	
	input  [BITS - 1 : 0]		i_data_in,
	input				i_memory_success
);

assign instruction_memory_success = i_memory_success;
assign data_memory_success = memory_success;
assign instruction_memory_data = i_data_in;
assign data_memory_data_out = data_in;

assign i_memory_address = instruction_memory_address;

always @(posedge CLK)
begin
	instruction_memory_address_out <= instruction_memory_address;
	memory_address <= data_memory_address;
	mem_wr <= data_memory_write_req;
	mem_rd <= data_memory_read_req;
	wr_mask <= data_memory_wr_mask;
	data_out <= data_memory_in;
	data_memory_wr_mask_out <= wr_mask;
end

endmodule
