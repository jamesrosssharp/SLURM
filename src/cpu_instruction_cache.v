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

assign address_data = {data_out[31:17], 1'b0, data_out[15:0]};

localparam st_init 		= 2'd0;
localparam st_invalidate 	= 2'd1;
localparam st_invalidate_done 	= 2'd2;
localparam st_execute		= 2'd3;

reg [1:0] state, next_state;

reg [CACHE_DEPTH_BITS - 1 : 0] invalid_addr, invalid_addr_next;

wire [CACHE_DEPTH_BITS - 1 : 0] bram_wr_addr = (state == st_execute) ? memory_requested_address[7:0] : invalid_addr;
wire  [CACHE_WIDTH_BITS - 1 : 0 ] bram_wr_data = (state == st_execute) ? {memory_requested_address, 1'b0, memory_data} : {CACHE_WIDTH_BITS{1'b1}};  
wire wr_bram = (state == st_execute && memory_success) || (state == st_invalidate);

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

reg [14:0] address_x;
reg [7:0] mem_address_x;



always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		address_x <= 15'd0;
		mem_address_x <= 15'd0;
	end
	else begin

		address_x <= cache_request_address;
		if (address_x != cache_request_address)	// If we just got a new request, then we will service it.
			mem_address_x <= cache_request_address;
		else if ((mem_address_x != 8'hff) && (state == st_execute) && (memory_success == 1'b1))
			mem_address_x <= mem_address_x + 1;	// Fill cache in our spare time (we need to keep the memory pipeline filled)

	end
end

assign cache_miss = (address_x != data_out[31:17]) || (data_out[16] != 1'b0);	// bit 16 must be zero to be valid

assign memory_address = {address_x[14:8], mem_address_x};
assign memory_rd_req = (state == st_execute);	// Always request memory when we are in "execute"

// State machine

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		state <= st_init;
		invalid_addr <= {CACHE_DEPTH_BITS{1'b0}};
	end else begin
		state <= next_state;
		invalid_addr <= invalid_addr_next;
	end
end

always @(*)
begin
	next_state = state;
	invalid_addr_next = invalid_addr;

	case (state)
		st_init:		
			next_state = st_invalidate;
		st_invalidate: begin
			invalid_addr_next = invalid_addr + 1;
			if (invalid_addr == (1 << CACHE_DEPTH_BITS) - 1)
				next_state = st_invalidate_done;
		end
		st_invalidate_done:
			next_state = st_execute;
		st_execute:
			if (invalidate_cache == 1'b1)
				next_state = st_invalidate;
	endcase

end

endmodule
