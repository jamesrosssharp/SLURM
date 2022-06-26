/*
 *	slurm16 : Memory interface
 *
 *	Simple arbiter state machine to allow instruction and data paths to
 *	access memory
 *
 */

module cpu_memory_interface #(parameter BITS = 16, ADDRESS_BITS = 16)  (
	input CLK,
	input RSTb,

	input  [ADDRESS_BITS - 1: 0] 	instruction_memory_address,
	output [BITS - 1: 0]	     	instruction_memory_data,
	input 			     	instruction_memory_valid,
	output 			     	instruction_memory_rdy,


	/* data interface */
	input  [ADDRESS_BITS - 1: 0] 	data_memory_address,
	output [BITS - 1: 0]	     	data_memory_data_out,
	input  [BITS - 1: 0]	     	data_memory_in,
	input				data_req,
	output				data_stall,	/* asserted if there is a request for data in/out which cannot be granted */	


	output [ADDRESS_BITS - 1: 0] 	memory_address,
	output [BITS - 1 : 0]		data_out,
	input  [BITS - 1 : 0]		data_in,
	output				valid,
	input				rdy

);

localparam st_idle        = 4'd0;
localparam st_instruction = 4'd1;
localparam st_data_val 	  = 4'd2;
localparam st_data_rdy    = 4'd3;

reg [3:0] state, state_next;

reg [ADDRESS_BITS - 1 : 0] memory_address_r;
reg [BITS - 1 : 0] 	   data_out_r;
reg [BITS - 1 : 0]	   data_memory_out_r;

assign data_stall = (state != st_data_rdy);

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		state <= st_idle;
	end else begin
		state <= state_next;	
	end
end



endmodule
