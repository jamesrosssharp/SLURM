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

wire [14:0] cache_request_address;
wire [31:0] address_data;

wire cache_miss;

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
wire [15:0] memory_address;
wire [15:0] data_out;
reg  [15:0] data_in;
wire valid;	
reg  rdy;
wire mem_wr;

reg [1:0] data_memory_wr_mask = 2'b00;
wire [1:0] wr_mask;
wire [1:0] data_memory_wr_mask_out = 2'b00;

wire data_memory_was_requested;

cpu_instruction_cache cache0 (
	CLK,
	RSTb,

	cache_request_address, /* request address from the cache */
	
	address_data,

	cache_miss, /* = 1 when the requested address doesn't match the address in the cache line */

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

wire [15:0] pipeline_stage0;
wire [15:0] pipeline_stage1;
wire [15:0] pipeline_stage2;
wire [15:0] pipeline_stage3;
wire [15:0] pipeline_stage4;

wire [15:0] pc_stage4;

wire [15:0] imm_reg;

reg load_pc = 1'b0;
reg [15:0] new_pc = 16'h0000;

reg	hazard_1;
reg	hazard_2;
reg	hazard_3;

reg	hazard_reg0 = 4'd0;
wire	modifies_flags0 = 1'b0;

wire	[3:0] hazard_reg1;
wire	[3:0] hazard_reg2;
wire	[3:0] hazard_reg3;

wire	modifies_flags1;
wire	modifies_flags2;
wire	modifies_flags3;

reg	interrupt_flag_set = 1'b0;
reg	interrupt_flag_clear = 1'b0;
reg	halt	= 1'b0;
wire	wake;

reg	interrupt = 1'b0;
reg	[3:0] irq = 4'b000;

wire 	is_executing;

cpu_pipeline pip0
(
	CLK,
	RSTb,

	pipeline_stage0,
	pipeline_stage1,
	pipeline_stage2,
	pipeline_stage3,
	pipeline_stage4,

	pc_stage4,

	imm_reg,

	load_pc,	
	new_pc,

	hazard_1, /* hazard between instruction in slot0 and slot1 */
	hazard_2, /* hazard between instruction in slot0 and slot2 */
	hazard_3, /* hazard between instruction in slot0 and slot3 */

	hazard_reg0,	/*  import hazard computation, it will move with pipeline in pipeline module */
	modifies_flags0,						/*  import flag hazard conditions */ 

	hazard_reg1,		/* export pipelined hazards */
	hazard_reg2,
	hazard_reg3,
	modifies_flags1,
	modifies_flags2,
	modifies_flags3,

	interrupt_flag_set,	/* cpu interrupt flag set */
	interrupt_flag_clear,	/* cpu interrupt flag clear */
	halt,
	wake,

	interrupt,		/* interrupt line from interrupt controller */	
	irq,			/* irq from interrupt controller */

	/* instruction cache memory interface */
	cache_request_address, /* request address from the cache */
	address_data,
	cache_miss, /* = 1 when the requested address doesn't match the address in the cache line */

	/* data memory interface */
	data_memory_success,
	bank_sw,	/* memory interface is switching banks or otherwise busy */
	data_memory_was_requested,

	is_executing
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



/*initial begin
	#27810 cache_request_address <= cache_request_address + 1;
	#800 cache_request_address <= 15'h4000;
end
*/

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
