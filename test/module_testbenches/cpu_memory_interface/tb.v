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

wire	instruction_memory_valid;
wire 	instruction_memory_ready;
wire	[15:0] instruction_memory_address;
wire	[15:0] instruction_memory_data;

wire	[31:0] address_data;

reg	[15:0] request_address = 0;

wire cache_miss;

reg 	[15:0] data_memory_address;
wire	[15:0] data_memory_data_out;
reg	[15:0] data_memory_in;
reg	data_req;
wire	data_stall;

wire	[15:0] memory_address;
wire 	[15:0] memory_data_out;
reg	[15:0] memory_data_in;
wire	memory_valid;
wire	memory_ready;



// Cache (MUT)

cpu_instruction_cache cache0 (
	CLK,
	RSTb,

	request_address, /* request address from the cache */
	
	address_data,

	cache_miss, /* = 1 when the requested address doesn't match the address in the cache line */

	/* memory interface to memory arbiter */
	instruction_memory_valid,
	instruction_memory_ready,
	instruction_memory_address,
	instruction_memory_data
);

cpu_memory_interface mem0  (
	CLK,
	RSTb,

	instruction_memory_address,
	instruction_memory_data,
	instruction_memory_valid,
	instruction_memory_ready,

	/* data interface */
	data_memory_address,
	data_memory_data_out,
	data_memory_in,
	data_req,
	data_stall,     /* asserted if there is a request for data in/out which cannot be granted */

	memory_address,
	memory_data_out,
	memory_data_in,
	memory_valid,
	memory_ready
);



localparam state_idle = 2'b00;
localparam state_grant = 2'b01;

reg [1:0] state = state_idle, state_next;

always @(posedge CLK)
begin
	case (state)
		state_idle:
			if (memory_valid == 1'b1) begin
				state <= state_grant;
			end
		state_grant:
			if (memory_valid == 1'b0)
				state <= state_idle;
	endcase

end


assign	 memory_ready = (state == state_grant) ? 1'b1 : 1'b0;

always @(posedge CLK)
begin
	if (state == state_grant) begin
		memory_data_in <= memory[memory_address];
	end else
		memory_data_in <= 16'hdead;
end



initial begin
	#600 request_address <= request_address + 2;
	#800 request_address <= request_address + 2;
end


initial begin
	$dumpfile("dump.vcd");
	$dumpvars(0, tb);
	# 20000 $finish;
end

genvar j;
for (j = 0; j < 256; j = j + 1) begin
	initial $dumpvars(0, cache0.mem0.RAM[j]);
end



endmodule
