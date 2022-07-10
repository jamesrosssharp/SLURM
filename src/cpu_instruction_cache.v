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

	input [14:0] cache_request_address, /* request address from the cache */
	
	output [CACHE_WIDTH_BITS - 1:0] address_data,

	output cache_miss, /* = 1 when the requested address doesn't match the address in the cache line */

	input  invalidate_cache, /* asserted by cpu to invalidate cache */
	output invalidation_done, /* asserted when cache has been invalidated */

	/* ports to memory interface */
	output [14:0] memory_address,
	output memory_rd_req,	/* we are requesting a read - we will get the value in two cycles time */
	
	input memory_success,	/* Arbiter will assert this when we our request was successful */
	input [14:0]  memory_requested_address,	/* Requested address will come back to us */ 
	input [15:0]  memory_data /* our data */
);

wire [31:0] data_out;

assign address_data = data_out;

localparam st_init 		= 2'd0;
localparam st_invalidate 	= 2'd1;
localparam st_invalidate_done 	= 2'd2;
localparam st_execute		= 2'd3;

reg [1:0] state = st_execute, next_state;

reg [CACHE_DEPTH_BITS - 1 : 0] invalid_addr, invalid_addr_next;

wire [CACHE_DEPTH_BITS - 1 : 0] bram_wr_addr = memory_requested_address[7:0];
wire  [CACHE_WIDTH_BITS - 1 : 0 ] bram_wr_data = {memory_requested_address, 1'b0, memory_data};  
wire wr_bram = (state == st_execute && memory_success);

assign invalidation_done = (state == st_invalidate_done);

bram
#(.BITS(CACHE_WIDTH_BITS), .ADDRESS_BITS(CACHE_DEPTH_BITS)) mem0
(
	.CLK(CLK),
	.RD_ADDRESS(cache_request_address[7:0]),
	.DATA_OUT(data_out),
	.WR_ADDRESS(bram_wr_addr),
	.DATA_IN(bram_wr_data),	// In the spare bit we could hide a dirty bit or something
	.WR(wr_bram)
);

reg [14:0] address_x, address_xx;
reg [7:0] mem_address_x;
assign memory_address = {address_xx[14:8], mem_address_x};
assign memory_rd_req = (state == st_execute);	// Always request memory when we are in "execute"


always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		address_xx <= 15'd0;
		address_x <= 15'd0;
		mem_address_x <= 8'd0;
	end
	else begin
		address_xx 	<= address_x;
		address_x 	<= cache_request_address;

		// There is potential for the cache to get stuck here. TODO:
		// Fix
		
		if ((address_x != address_xx) && cache_miss) begin	// If we just got a new request, then we will service it.
			mem_address_x 		<= address_x[7:0];
			mem_address_x_prev 	<= mem_address_x;
		end
		// TODO: replace memory_success here 
		else if ((mem_address_x != 8'hff) && (state == st_execute) && (memory_success == 1'b1)) begin
			mem_address_x 		<= mem_address_x + 1;	// Fill cache in our spare time (we need to keep the memory pipeline filled)
		end
				
	end
end

assign cache_miss = (address_x != data_out[31:17]) || (data_out[16] != 1'b0);	// bit 16 must be zero to be valid

endmodule
