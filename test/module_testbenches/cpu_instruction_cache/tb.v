module tb;

reg CLK = 1'b0;
reg RSTb = 1'b0;

always #50 CLK <= !CLK; // ~ 10MHz

initial begin 
	#150 RSTb = 1'b1;
end

// Memory interface logic

reg [15:0] memory [65535:0];

initial begin
	$display("Loading rom.");
	$readmemh("ram_image.mem", memory);
end

// Cache (MUT)

reg [14:0] 	cache_request_address = 15'd0;
wire [31:0] 	address_data;

wire 	cache_miss;

reg 	invalidate_cache;
wire	invalidation_done;

wire [14:0]	memory_address;
wire 		memory_rd_req;

wire memory_success;
wire [14:0] memory_requested_address;
wire [15:0] memory_data;

cpu_instruction_cache cache0 (

 	CLK,
        RSTb,

        cache_request_address, /* request address from the cache */

        address_data,

        cache_miss, /* = 1 when the requested address doesn't match the address in the cache line */

        invalidate_cache, /* asserted by cpu to invalidate cache */
        invalidation_done, /* asserted when cache has been invalidated */

        /* ports to memory interface */
        memory_address,
        memory_rd_req,   /* we are requesting a read - we will get the value in two cycles time */

        memory_success,   /* Arbiter will assert this when we our request was successful */
        memory_requested_address, /* Requested address will come back to us */
        memory_data /* our data */

);

reg memBUSY = 1'b0;

reg [14:0] reg_addr1, reg_addr2;
reg [15:0] reg_data1, reg_data2;
reg reg_success1, reg_success2;

assign memory_data = reg_data2;
assign memory_success = reg_success2;
assign memory_requested_address = reg_addr2;

always @(posedge CLK)
begin
	reg_addr2 <= reg_addr1;
	reg_addr1 <= memory_address;
	reg_data1 <= memBUSY ? 16'hdead :  memory[memory_address];
	reg_data2 <= reg_data1;
	reg_success1 <= ! memBUSY && memory_rd_req;
	reg_success2 <= reg_success1;
end


initial begin	
	#28000 cache_request_address <= cache_request_address + 1;
	#800 cache_request_address <= cache_request_address + 1;
	#1000 memBUSY <= 1'b1;
	#100 cache_request_address <= cache_request_address + 1;
	#1000 memBUSY <= 1'b0;
	#5000 invalidate_cache <= 1'b1;
	#100 invalidate_cache <= 1'b0;
end

initial begin
	$dumpfile("dump.vcd");
	$dumpvars(0, tb);
	# 200000 $finish;
end

genvar j;
for (j = 0; j < 256; j = j + 1) begin
	initial $dumpvars(0, cache0.mem0.RAM[j]);
end

endmodule
