/*
 *
 *	To solve the numerous problems with the memory interface,
 *	we introduce a simple instruction cache. This should improve
 *	performance and allow us to restructure the cpu memory interface.
 *
 *	We may make the cache burst read to improve performance.
 *
 */


module cpu_instruction_cache #(
	parameter CACHE_DEPTH_BITS = 8,
	parameter CACHE_WIDTH_BITS = 32
) (
	input CLK,
	input RSTb,

	input [15:0] request_address, /* request address from the cache */
	
	output [15:0] address,
	output [15:0] data,

	output cache_miss, /* = 1 when the requested address doesn't match the address in the cache line */

	/* memory interface to memory arbiter */
	output memory_ready,
	input  memory_valid,
	output [15:0] memory_address,
	input [15:0] memory_data
);

wire [CACHE_WIDTH_BITS - 1 : 0] data_out;

assign address 	= data_out[31:16];
assign data 	= data_out[15:0];

reg [15:0] address2mem, address2mem_next;
reg wr_bram;

bram
#(.BITS(CACHE_WIDTH_BITS), .ADDRESS_BITS(CACHE_DEPTH_BITS)) mem0
(
	.CLK(CLK),
	.RD_ADDRESS(request_address[7:0]),
	.DATA_OUT(data_out),
	.WR_ADDRESS(address2mem[7:0]),
	.DATA_IN({address2mem, memory_data}),
	.WR(wr_bram)
);

reg [15:0] address_x;

always @(posedge CLK)
begin
	address_x <= request_address;
end

assign cache_miss = address_x != data_out[31:16];


localparam state_idle 		= 1'd0;
localparam state_request_mem 	= 1'd1;

reg state, state_next;

assign memory_address = address2mem;

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		state <= state_idle;
		address2mem <= 16'h00;
	end else begin
		state <= state_next;
		address2mem <= address2mem_next;
	end
end

reg memory_ready_r;
assign memory_ready = memory_ready_r;

always @(*)
begin
	state_next = state;
	address2mem_next = address2mem;
	memory_ready_r = 1'b0;
	wr_bram = 1'b0;

	case (state)
		state_idle: begin
			if (cache_miss == 1'b1) begin
				address2mem_next = address_x;
				state_next = state_request_mem;
			end
		end
		state_request_mem: begin
			memory_ready_r = 1'b1;
			if (memory_valid == 1'b1) begin
				state_next = state_idle;
				wr_bram = 1'b1;
			end
		end
	endcase

end

endmodule
