/*
 *
 *	slurm16 SOC
 *
 *
 */

module slurm16 #(
	parameter CLOCK_FREQ = 10000000
) (
	input CLK,
	input RSTb,

	output [3:0] gpio_out,
	input  [5:0] gpio_in,

	output [3:0] vid_r,
	output [3:0] vid_g,
	output [3:0] vid_b,
	output vid_hsync,
	output vid_vsync,
	output vid_blank,

	output uart_tx,

	output led_r,
	output led_g,
	output led_b,

	output i2s_sclk,
	output i2s_lrclk,
	output i2s_data,
	output i2s_mclk,

	output flash_mosi,
	input  flash_miso,
	output flash_sclk,
	output flash_csb 
);

wire [15:0] cpuMemoryIn;
wire [15:0] cpuMemoryOut;
wire [15:0] cpuMemoryAddr;
wire cpuMemory_ready;
wire cpuMemory_valid;
wire cpuMemory_wr;
wire [1:0] cpuMemory_wr_mask;

wire [15:0] cpuPort_in;
wire [15:0] cpuPort_out;
wire [15:0] cpuPort_address;
wire cpuPort_rd;
wire cpuPort_wr;

wire [3:0] cpuIRQ;
wire cpuInterrupt;

wire [15:0] spcon_memory_address;
wire [15:0] spcon_memory_data;
wire spcon_rvalid;
wire spcon_rready;
wire [15:0] bg0_memory_address;
wire [15:0] bg0_memory_data;
wire bg0_rvalid;
wire bg0_rready;
wire [15:0] bg1_memory_address;
wire [15:0] bg1_memory_data;
wire bg1_rvalid;
wire bg1_rready;
wire [15:0] ov_memory_address;
wire [15:0] ov_memory_data;
wire ov_rvalid;
wire ov_rready;
wire [15:0] fl_memory_address;
wire [15:0] fl_memory_data;
wire fl_wvalid;
wire fl_wready;

/*wire [15:0] au_memory_address;
wire [15:0] au_memory_data;
wire au_rvalid;
wire au_rready;
*/
wire cpu_debug_pin;

// CPU Top level

cpu_top cpu0
(
	CLK,
	RSTb,

	cpuMemoryAddr,
	cpuMemoryIn,
	cpuMemoryOut,
	cpuMemory_valid,	/* memory request */
	cpuMemory_wr,		/* memory write */
	cpuMemory_ready,	/* memory ready - from arbiter */
	cpuMemory_wr_mask,	/* memory write mask */

	cpuPort_address,
	cpuPort_in,
	cpuPort_out,
	cpuPort_rd,
	cpuPort_wr,

	cpuInterrupt,
	cpuIRQ,

	cpu_debug_pin	
);



// Port controller

port_controller
#(.BITS(16), .ADDRESS_BITS(16), .CLOCK_FREQ(CLOCK_FREQ))
pc0
(
	.CLK(CLK),	
	.RSTb(RSTb),
	.ADDRESS(cpuPort_address),
	.DATA_IN(cpuPort_out),
	.DATA_OUT(cpuPort_in),
	.memWR(cpuPort_wr), 
	.memRD(cpuPort_rd), 
	.cpu_debug_pin(cpu_debug_pin),
	.gpio_out(gpio_out),
	.gpio_in(gpio_in),
	.vid_r(vid_r),
	.vid_g(vid_g),
	.vid_b(vid_b),
	.vid_hsync(vid_hsync),
	.vid_vsync(vid_vsync),
	.vid_blank(vid_blank),
	.uart_tx(uart_tx),
	.led_r(led_r),
	.led_g(led_g),
	.led_b(led_b),
	.i2s_sclk(i2s_sclk),
	.i2s_lrclk(i2s_lrclk),
	.i2s_data(i2s_data),
	.i2s_mclk(i2s_mclk),
	.flash_mosi(flash_mosi),
	.flash_miso(flash_miso),
	.flash_sclk(flash_sclk),
	.flash_csb(flash_csb), 
	.spcon_memory_address(spcon_memory_address),
	.spcon_memory_data(spcon_memory_data),
	.spcon_rvalid(spcon_rvalid),
	.spcon_rready(spcon_rready),
	.bg0_memory_address(bg0_memory_address),
	.bg0_memory_data(bg0_memory_data),
	.bg0_rvalid(bg0_rvalid),
	.bg0_rready(bg0_rready),
	.bg1_memory_address(bg1_memory_address),
	.bg1_memory_data(bg1_memory_data),
	.bg1_rvalid(bg1_rvalid),
	.bg1_rready(bg1_rready),
	.ov_memory_address(ov_memory_address),
	.ov_memory_data(ov_memory_data),
	.ov_rvalid(ov_rvalid),
	.ov_rready(ov_rready),
	.fl_memory_address(fl_memory_address),
	.fl_memory_data(fl_memory_data),
	.fl_wvalid(fl_wvalid),
	.fl_wready(fl_wready),
	/*.au_memory_address(au_memory_address),
	.au_memory_data(au_memory_data),
	.au_rvalid(au_rvalid),
	.au_rready(au_rready),*/
	.interrupt(cpuInterrupt),
	.irq(cpuIRQ)
);

// Memory controller (wrapper to arbiter + ROM overlay)

memory_controller
#(.BITS(16), .ADDRESS_BITS(16), .CLOCK_FREQ(CLOCK_FREQ))
mem0
(
	CLK,	
	RSTb,

	spcon_memory_address,
	spcon_memory_data,
	spcon_rvalid, // memory address valid
	spcon_rready,  // memory data valid

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
	
/*	au_memory_address,
	au_memory_data,
	au_rvalid, // memory address valid
	au_rready,  // memory data valid
*/
	cpuMemoryAddr,
	cpuMemoryOut,
	cpuMemoryIn,
	cpuMemory_valid, // memory address valid
	cpuMemory_wr, // CPU is writing to memory
	cpuMemory_ready,  // memory access granted
	cpuMemory_wr_mask
);


endmodule
