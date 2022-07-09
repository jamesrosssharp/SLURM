module tb;

reg CLK = 1'b1;
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

reg [14:0] cache_request_address = 15'd0;
wire [31:0] address_data;

wire cache_miss;

reg invalidate_cache = 1'b0;;
wire invalidation_done;

wire [14:0] instruction_memory_address;
wire instruction_memory_read_req;

wire instruction_memory_success;
wire [14:0] instruction_memory_requested_address;
wire [15:0] instruction_memory_data;

reg [14:0] data_memory_address = 15'd0;
reg [15:0] data_memory_in = 16'h0000;
reg data_memory_read_req = 1'b0;
reg data_memory_write_req = 1'b0;
	
wire [15:0] data_memory_data_out;
wire data_memory_success;	
wire bank_sw;
wire [14:0] memory_address;
wire [15:0] data_out;
reg  [15:0] data_in;
wire valid;	
reg  rdy;
wire mem_wr;
reg [1:0] 	data_memory_wr_mask = 2'b00;
wire [1:0] 	data_memory_wr_mask_out;
wire [1:0] 	wr_mask;

cpu_instruction_cache cache0 (
	CLK,
	RSTb,

	cache_request_address, /* request address from the cache */
	
	address_data,

	cache_miss, /* = 1 when the requested address doesn't match the address in the cache line */

	invalidate_cache, /* asserted by cpu to invalidate cache */
	invalidation_done, /* asserted when cache has been invalidated */

	/* ports to memory interface */
	instruction_memory_address,
	instruction_memory_read_req,	/* we are requesting a read - we will get the value in two cycles time */
	
	instruction_memory_success,	/* Arbiter will assert this when we our request was successful */
	instruction_memory_requested_address,	/* Requested address will come back to us */ 
	instruction_memory_data /* our data */
);

cpu_memory_interface mem0 (
	CLK,
	RSTb,

	/* instruction interface */
	instruction_memory_address,	/* requested address */
	instruction_memory_read_req,	/* requesting a read */

	instruction_memory_data,	/* data output */
	instruction_memory_requested_address, /* requested address pass back */
	instruction_memory_success,	/* 1 = read successful, 0 = read failed */

	/* data interface */
	data_memory_address,
	data_memory_in,
	data_memory_read_req,
	data_memory_write_req,
	data_memory_wr_mask,

	data_memory_data_out,
	data_memory_success,	
	data_memory_was_requested,
        data_memory_wr_mask_out,

	/* bank switch flag : asserted when switching bank. See notes above */
	bank_sw,

	memory_address,	/* one more bit to output address - tied low */
	data_out,
	data_in,
 	wr_mask,
	mem_wr,
	valid,		/* request access to memory bank */
	rdy		/* we have access to the bank */

);

// Simulate memory arbiter

localparam st_idle = 2'd0;
localparam st_grant = 2'd1;

reg [1:0] state;

always @(posedge CLK)
begin
	if (RSTb == 1'b0)
		state <= st_idle;
	else begin
		case (state)
			st_idle: begin
				if (valid == 1'b1) begin
					state <= st_grant;
					rdy <= 1'b1;
				end
				data_in <= 16'hbeef;
			end	
			st_grant: begin
				if (valid == 1'b0) begin
					state <= st_idle;
					rdy <= 1'b0;
				end
				data_in <= memory[memory_address];
				if (mem_wr == 1'b1)
					memory[memory_address] <= data_out;
			end
			endcase
	end
end



initial begin
	#27810 cache_request_address <= cache_request_address + 1;
	#800 cache_request_address <= cache_request_address + 1;
	#800 cache_request_address <= 15'd0;
	#800 cache_request_address <= 15'h4000;
end


initial begin
	$dumpfile("dump.vcd");
	$dumpvars(0, tb);
	# 100000 $finish;
end

genvar j;
for (j = 0; j < 256; j = j + 1) begin
	initial $dumpvars(0, cache0.mem0.RAM[j]);
end



endmodule
