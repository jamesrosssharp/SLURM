module slurm16_memory_arbiter
(
	input  CLK,
	input  RSTb,
	
	/* sprite controller */
	input  [15:0] 	sprite_memory_address,
	output reg [15:0] 	sprite_memory_data,
	input 		sprite_rvalid, // memory address valid
	output reg 	sprite_rready,  // memory data valid

	/* background controller 0 */
	input  [15:0] 	bg0_memory_address,
	output reg [15:0] 	bg0_memory_data,
	input 		bg0_rvalid, // memory address valid
	output reg 	bg0_rready,  // memory data valid

	/* flash controller */
	input  [15:0] 	fl_memory_address,
	input [15:0] 	fl_memory_data,
	input 		fl_wvalid, // memory address valid
	output reg 	fl_wready,  // memory data valid
	
	/* CPU 
 	   ---
 
	   Default access to memory is given to the CPU. Other peripherals (flash, sprites, backgrounds)
	   will request and hold the memory, and if the CPU tries to access the memory while it is held by another
	   peripheral, "cpu_memory_success" will be deasserted, forcing the CPU to reissue the memory request. 

  	*/

	input  [14:0] 	cpu_memory_address,
	input  [15:0]   cpu_memory_data_in,
	output reg [15:0] cpu_memory_data,
	input		cpu_wr, // CPU is writing to memory
	output reg	cpu_memory_success,
	input  [1:0]	cpu_wr_mask, // Write mask from CPU (for byte wise writes)

	output [13 : 0] B1_ADDR,
	input  [15 : 0] B1_DOUT,
	output [15 : 0] B1_DIN,
	output [ 1 : 0] B1_MASK,
	output B1_WR,

	output [13 : 0] B2_ADDR,
	input  [15 : 0] B2_DOUT,
	output [15 : 0] B2_DIN,
	output [ 1 : 0] B2_MASK,
	output B2_WR,

	output [13 : 0] B3_ADDR,
	input  [15 : 0] B3_DOUT,
	output [15 : 0] B3_DIN,
	output [ 1 : 0] B3_MASK,
	output B3_WR,

	output [13 : 0] B4_ADDR,
	input  [15 : 0] B4_DOUT,
	output [15 : 0] B4_DIN,
	output [ 1 : 0] B4_MASK,
	output B4_WR
);

/* Bank mux selectors */

localparam MUXSEL_CPU 		= 2'd0;
localparam MUXSEL_FLASH 	= 2'd1;
localparam MUXSEL_BACKGROUND 	= 2'd2;
localparam MUXSEL_SPRITES	= 2'd3;

wire [1:0] b1_mux_sel; 
wire [1:0] b2_mux_sel; 
wire [1:0] b3_mux_sel; 
wire [1:0] b4_mux_sel; 

reg [1:0] b1_mux_sel_x; 
reg [1:0] b2_mux_sel_x; 
reg [1:0] b3_mux_sel_x; 
reg [1:0] b4_mux_sel_x; 

always @(posedge CLK)
begin
	b1_mux_sel_x <= b1_mux_sel; 
	b2_mux_sel_x <= b2_mux_sel; 
	b3_mux_sel_x <= b3_mux_sel; 
	b4_mux_sel_x <= b4_mux_sel; 
end


/* muxed peripheral signals */

wire [13:0] b1_periph_addr;
wire [13:0] b2_periph_addr;
wire [13:0] b3_periph_addr;
wire [13:0] b4_periph_addr;

wire [15:0] b1_periph_din;
wire [15:0] b2_periph_din;
wire [15:0] b3_periph_din;
wire [15:0] b4_periph_din;

wire [1:0] b1_periph_wr_mask;
wire [1:0] b2_periph_wr_mask;
wire [1:0] b3_periph_wr_mask;
wire [1:0] b4_periph_wr_mask;

wire b1_periph_wr;
wire b2_periph_wr;
wire b3_periph_wr;
wire b4_periph_wr;

/* mux signals going into the memory banks */

assign B1_ADDR = b1_periph_addr;
assign B2_ADDR = b2_periph_addr;
assign B3_ADDR = b3_periph_addr;
assign B4_ADDR = b4_periph_addr;

assign B1_DIN = b1_periph_din;
assign B2_DIN = b2_periph_din;
assign B3_DIN = b3_periph_din;
assign B4_DIN = b4_periph_din;

assign B1_MASK = b1_periph_wr_mask;
assign B2_MASK = b2_periph_wr_mask;
assign B3_MASK = b3_periph_wr_mask;
assign B4_MASK = b4_periph_wr_mask;

assign B1_WR = b1_periph_wr;
assign B2_WR = b2_periph_wr;
assign B3_WR = b3_periph_wr;
assign B4_WR = b4_periph_wr;


/* mux signals going into cpu */

reg cpu_memory_address14;

always @(posedge CLK)
begin
	cpu_memory_address14 <= cpu_memory_address[14];
	
	if (b1_mux_sel == MUXSEL_CPU && cpu_memory_address[14] == 1'b0)
		cpu_memory_success <= 1'b1;
	else if (b2_mux_sel == MUXSEL_CPU && cpu_memory_address[14] == 1'b1)
		cpu_memory_success <= 1'b1;
	else
		cpu_memory_success <= 1'b0;
end

always @(*)
begin
	case (cpu_memory_address14)
		1'b0: begin
			cpu_memory_data = B1_DOUT;
		end
		1'b1: begin
			cpu_memory_data = B2_DOUT; 
		end
	endcase
end

/* 
 * mux signals going into sprite - 
 *
 * sprite connects to banks 2 and 3, read only
 */

always @(posedge CLK)
begin
	if (b2_mux_sel == MUXSEL_SPRITES)
		sprite_rready <= 1'b1;
	else if (b3_mux_sel == MUXSEL_SPRITES)
		sprite_rready <= 1'b1;
	else if (b4_mux_sel == MUXSEL_SPRITES)
		sprite_rready <= 1'b1;
	else
		sprite_rready <= 1'b0;
end

always @(*)
begin
	if (b2_mux_sel_x == MUXSEL_SPRITES)
		sprite_memory_data = B2_DOUT;
	else if (b3_mux_sel_x == MUXSEL_SPRITES)
		sprite_memory_data = B3_DOUT;
	else 
		sprite_memory_data = B4_DOUT;

end


/* mux signals going into background - 
 *
 *
 * background connects to banks 2, 3 and 4, read only
 */


always @(posedge CLK)
begin
	if (b2_mux_sel == MUXSEL_BACKGROUND)
		bg0_rready <= 1'b1;
	else if (b3_mux_sel == MUXSEL_BACKGROUND)
		bg0_rready <= 1'b1;
	else if (b4_mux_sel == MUXSEL_BACKGROUND)
		bg0_rready <= 1'b1;
	else
		bg0_rready <= 1'b0;
end

always @(*)
begin
	if (b2_mux_sel_x == MUXSEL_BACKGROUND)
		bg0_memory_data = B2_DOUT;
	else if (b3_mux_sel_x == MUXSEL_BACKGROUND)
		bg0_memory_data = B3_DOUT;
	else 
		bg0_memory_data = B4_DOUT;

end

/* mux signals going into flash -
 *
 * flash connects to whole memory, write only
 *
 */

always @(posedge CLK)
begin
	if (b1_mux_sel == MUXSEL_FLASH)
		fl_wready <= 1'b1;
	else if (b2_mux_sel == MUXSEL_FLASH)
		fl_wready <= 1'b1;
	else if (b3_mux_sel == MUXSEL_FLASH)
		fl_wready <= 1'b1;
	else if (b4_mux_sel == MUXSEL_FLASH)
		fl_wready <= 1'b1;
	else
		fl_wready <= 1'b0;
end

/* instantiate perhiperal arbiters for banks 1-4 */

slurm16_peripheral_memory_arbiter arb1
(
	CLK,
	RSTb,	
	b1_mux_sel,
	b1_periph_addr,
	b1_periph_din,
	b1_periph_wr,
	b1_periph_wr_mask,
	1'b0,	/* sprite valid */ 
	1'b0,   /* background valid */
	fl_wvalid && (fl_memory_address[15:14] == 2'b00), /* flash valid */
	sprite_memory_address, /* sprite address */
	bg0_memory_address, /* background address */
	fl_memory_address, /* flash address */
	fl_memory_data, /* flash write data */

	/* signals from CPU */
	cpu_memory_address,
	cpu_memory_data_in,
	cpu_wr && (cpu_memory_address[14] == 1'b0),
	cpu_wr_mask
);

slurm16_peripheral_memory_arbiter arb2
(
	CLK,
	RSTb,	
	b2_mux_sel,
	b2_periph_addr,
	b2_periph_din,
	b2_periph_wr,
	b2_periph_wr_mask,
	sprite_rvalid && (sprite_memory_address[15:14] == 2'b01), /* sprite valid */ 
	bg0_rvalid && (bg0_memory_address[15:14] == 2'b01),   /* background valid */
	fl_wvalid && (fl_memory_address[15:14] == 2'b01), /* flash valid */
	sprite_memory_address, /* sprite address */
	bg0_memory_address, /* background address */
	fl_memory_address, /* flash address */
	fl_memory_data, /* flash write data */

	/* signals from CPU */
	cpu_memory_address,
	cpu_memory_data_in,
	cpu_wr && (cpu_memory_address[14] == 1'b1),
	cpu_wr_mask
);

slurm16_peripheral_memory_arbiter arb3
(
	CLK,
	RSTb,	
	b3_mux_sel,
	b3_periph_addr,
	b3_periph_din,
	b3_periph_wr,
	b3_periph_wr_mask,
	sprite_rvalid && (sprite_memory_address[15:14] == 2'b10), /* sprite valid */ 
	bg0_rvalid && (bg0_memory_address[15:14] == 2'b10),   /* background valid */
	fl_wvalid && (fl_memory_address[15:14] == 2'b10), /* flash valid */
	sprite_memory_address, /* sprite address */
	bg0_memory_address, /* background address */
	fl_memory_address, /* flash address */
	fl_memory_data, /* flash write data */

	/* signals from CPU */
	cpu_memory_address,
	cpu_memory_data_in,
	1'b0,
	cpu_wr_mask
);

slurm16_peripheral_memory_arbiter arb4
(
	CLK,
	RSTb,	
	b4_mux_sel,
	b4_periph_addr,
	b4_periph_din,
	b4_periph_wr,
	b4_periph_wr_mask,
	sprite_rvalid && (sprite_memory_address[15:14] == 2'b11), /* sprite valid */ 
	bg0_rvalid && (bg0_memory_address[15:14] == 2'b11),   /* background valid */
	fl_wvalid && (fl_memory_address[15:14] == 2'b11), /* flash valid */
	sprite_memory_address, /* sprite address */
	bg0_memory_address, /* background address */
	fl_memory_address, /* flash address */
	fl_memory_data, /* flash write data */
	/* signals from CPU */
	cpu_memory_address,
	cpu_memory_data_in,
	1'b0,
	cpu_wr_mask
);

endmodule
