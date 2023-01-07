module tb;

reg CLK = 1'b0;
reg RSTb = 1'b0;

always #50 CLK <= !CLK; // ~ 10MHz

initial begin 
	#150 RSTb = 1'b1;
end


reg [15:0] sprite_memory_address;
wire [15:0] sprite_memory_data;
reg  sprite_rvalid;
wire sprite_rready;

reg [15:0] bg0_memory_address;
wire [15:0] bg0_memory_data;
reg bg0_rvalid;
wire bg0_rready;

reg [15:0] fl_memory_address;
reg [15:0] fl_memory_data;
reg fl_wvalid;
wire fl_wready;
	
reg [14:0] cpu_memory_address;
reg [15:0] cpu_memory_data_in;
wire [15:0] cpu_memory_data;
reg  cpu_wr;
wire cpu_memory_success;
reg [1:0] cpu_wr_mask;

wire [13:0] B1_ADDR;
wire [15:0] B1_DOUT = 16'hdead;
wire [15:0] B1_DIN;
wire [1:0]  B1_MASK;
wire B1_WR;

wire [13:0] B2_ADDR;
wire [15:0] B2_DOUT = 16'hbeef;
wire [15:0] B2_DIN;
wire [1:0]  B2_MASK;
wire B2_WR;

wire [13:0] B3_ADDR;
wire [15:0] B3_DOUT = 16'hbadd;
wire [15:0] B3_DIN;
wire [1:0]  B3_MASK;
wire B3_WR;

wire [13:0] B4_ADDR;
wire [15:0] B4_DOUT = 16'hecaf;
wire [15:0] B4_DIN;
wire [1:0]  B4_MASK;
wire B4_WR;

slurm16_memory_arbiter arb0
(
	CLK,
	RSTb,
	
	/* sprite controller */
	sprite_memory_address,
	sprite_memory_data,
	sprite_rvalid, // memory address valid
	sprite_rready,  // memory data valid

	/* background controller 0 */
	bg0_memory_address,
	bg0_memory_data,
	bg0_rvalid, // memory address valid
	bg0_rready,  // memory data valid

	/* flash controller */
	fl_memory_address,
	fl_memory_data,
	fl_wvalid, // memory address valid
	fl_wready,  // memory data valid
	
	cpu_memory_address,
	cpu_memory_data_in,
	cpu_memory_data,
	cpu_wr, // CPU is writing to memory
	cpu_memory_success,
	cpu_wr_mask, // Write mask from CPU (for byte wise writes)

	B1_ADDR,
	B1_DOUT,
	B1_DIN,
	B1_MASK,
	B1_WR,

	B2_ADDR,
	B2_DOUT,
	B2_DIN,
	B2_MASK,
	B2_WR,

	B3_ADDR,
	B3_DOUT,
	B3_DIN,
	B3_MASK,
	B3_WR,

	B4_ADDR,
	B4_DOUT,
	B4_DIN,
	B4_MASK,
	B4_WR
);

/* 		Run some tests on the modules 		*/

reg [127:0] test_name;
reg [63:0] pass_fail = "";

initial begin
	
	sprite_memory_address <= 16'h4000;
	sprite_rvalid <= 1'b0;

	bg0_memory_address <= 16'hc000;
	bg0_rvalid <= 1'b0;

	fl_memory_address <= 16'h8000;
	fl_memory_data <= 16'hffff;
	fl_wvalid <= 1'b0;
		
	cpu_memory_address <= 15'h0200;
	cpu_memory_data_in <= 16'hcccc;
	cpu_wr <= 1'b0;
	cpu_wr_mask <= 1'b10;

	#200
	
	/* 1. Pass in add r3, r4, r5 
	 * we should see:
 	 *
 	 *  aluOp -> 5'd1 after 1 cycle
 	 *  aluA -> regA
 	 *  aluB -> regB
 	 */

	pass_fail <= "CHK";
	test_name <= "Test 1";

	sprite_rvalid <= 1'b1;

	#200

	sprite_rvalid <= 1'b0;

	//assert(aluOut == 32'd7) else $fatal;

	//if (aluOut == 32'd7 && C == 1'b0 && Z == 1'b0 && V == 1'b0 && S == 1'b0)
	//	pass_fail <= "Pass";
	//else
	//	pass_fail <= "Fail";

	#1000;

end


initial begin
	$dumpfile("dump.vcd");
	$dumpvars(0, tb);
	# 15000 $finish;
end

endmodule
