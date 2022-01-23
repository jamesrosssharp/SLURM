/* 	memory_controller.v : memory controller 
 *	
 *	instantiate memory arbiter, rom and memory banks
 *
 */

module memory_controller
#(parameter BITS = 16, ADDRESS_BITS = 16, CLOCK_FREQ = 10000000)
(
	input CLK,	
	input RSTb,

	/* memory ports */
	/* sprite controller */
	input  [15:0] 	sprite_memory_address,
	output [15:0] 	sprite_memory_data,
	input 			sprite_rvalid, // memory address valid
	output  		sprite_rready,  // memory data valid

	/* background controller 0 */
	input  [15:0] 	bg0_memory_address,
	output [15:0] 	bg0_memory_data,
	input 			bg0_rvalid, // memory address valid
	output  		bg0_rready,  // memory data valid

	/* background controller 1 */
	input  [15:0] 	bg1_memory_address,
	output [15:0] 	bg1_memory_data,
	input 			bg1_rvalid, // memory address valid
	output  		bg1_rready,  // memory data valid

	/* overlay controller */
	input  [15:0] 	ov_memory_address,
	output [15:0] 	ov_memory_data,
	input 			ov_rvalid, // memory address valid
	output  		ov_rready,  // memory data valid

	/* flash controller */
	input  [15:0] 	fl_memory_address,
	input [15:0] 	fl_memory_data,
	input 			fl_wvalid, // memory address valid
	output  		fl_wready,  // memory data valid
	
	/* audio controller */
	/*input  [15:0] 	au_memory_address,
	output [15:0] 	au_memory_data,
	input 			au_rvalid, // memory address valid
	output  		au_rready,  // memory data valid
*/
	/* CPU */
	input  [15:0] 	cpu_memory_address,
	input  [15:0]   cpu_memory_data_in,
	output [15:0] 	cpu_memory_data,
	input 			cpu_valid, // memory address valid
	input			cpu_wr, // CPU is writing to memory
	output  		cpu_ready  // memory access granted
);

wire [13:0]	B1_ADDR;
wire [15:0]	B1_DOUT;
wire [15:0] B1_DIN;
wire B1_WR;

wire [13:0] B2_ADDR;
wire [15:0] B2_DOUT;
wire [15:0] B2_DIN;
wire B2_WR;

wire [13:0] B3_ADDR;
wire [15:0] B3_DOUT;
wire [15:0] B3_DIN;
wire B3_WR;
	
wire [13:0] B4_ADDR;
wire [15:0] B4_DOUT;
wire [15:0] B4_DIN;
wire B4_WR;

memory #(.BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS - 2), .MEM_INIT_FILE("mem_init1.mem")) mb1
(
	CLK,
	B1_ADDR,
	B1_DIN,
	B1_DOUT,
	B1_WR
);

memory #(.BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS - 2), .MEM_INIT_FILE("mem_init2.mem")) mb2
(
	CLK,
	B2_ADDR,
	B2_DIN,
	B2_DOUT,
	B2_WR
);

memory #(.BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS - 2), .MEM_INIT_FILE("mem_init3.mem")) mb3
(
	CLK,
	B3_ADDR,
	B3_DIN,
	B3_DOUT,
	B3_WR
);

memory #(.BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS - 2), .MEM_INIT_FILE("mem_init4.mem")) mb4
(
	CLK,
	B4_ADDR,
	B4_DIN,
	B4_DOUT,
	B4_WR
);

wire [15:0] cpu_memory_data_w;
wire [15:0] boot_data;

reg [15:0] cpu_memory_address_r;

always @(posedge CLK)
begin
	cpu_memory_address_r <= cpu_memory_address;
end

// ROM Overlay
assign cpu_memory_data = (cpu_memory_address_r[15:8] == 8'h00) ? boot_data : cpu_memory_data_w; 
wire wr_boot = (cpu_memory_address[15:8] == 8'h00) ? cpu_wr : 1'b0; 

boot_memory #(.BITS(BITS), .ADDRESS_BITS(8)) theBootMem
(
	CLK,
 	cpu_memory_address[7:0],
	cpu_memory_data_in,
	boot_data,
	wr_boot
);

wire dummy;
wire [BITS - 1:0] dummy_data;

memory_arbiter ma0
(
	CLK,
	RSTb,
	sprite_memory_address,
	sprite_memory_data,
	sprite_rvalid, // memory address valid
	sprite_rready,  // memory data valid
	bg0_memory_address,
	bg0_memory_data,
	bg0_rvalid, // memory address valid
	bg0_rready,  // memory data valid
	bg1_memory_address,
	bg1_memory_data,
	bg1_rvalid, // memory address valid
	bg1_rready,  // memory data valid
	ov_memory_address,
	ov_memory_data,
	ov_rvalid, // memory address valid
	ov_rready,  // memory data valid	
	fl_memory_address,
	fl_memory_data,
	fl_wvalid, // memory address valid
	fl_wready,  // memory data valid
	
	// Audio: unused
	16'd0,
	dummy_data,
	1'b0, //au_rvalid, // memory address valid
	dummy,  // memory data valid

	cpu_memory_address,
	cpu_memory_data_in,
	cpu_memory_data_w,
	cpu_valid, // memory address valid
	cpu_wr, // CPU is writing to memory
	cpu_ready,  // memory access granted
	B1_ADDR,
	B1_DOUT,
	B1_DIN,
	B1_WR,
	B2_ADDR,
	B2_DOUT,
	B2_DIN,
	B2_WR,
	B3_ADDR,
	B3_DOUT,
	B3_DIN,
	B3_WR,
	B4_ADDR,
	B4_DOUT,
	B4_DIN,
	B4_WR
);


endmodule
