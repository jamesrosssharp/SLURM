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
	output flash_csb,

	output cpu_debug_pin

);

wire [15:0] cpuMemoryIn;
wire [15:0] cpuMemoryOut;
wire [15:0] cpuMemoryAddr;
wire cpuMemory_success;
wire cpuMemory_wr;
wire cpuMemory_rd;
wire [1:0] cpuMemory_wr_mask;

wire [14:0] cpuIMemoryAddr;
wire [15:0] cpuIMemoryData;
wire cpuIMemory_success;

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
wire [15:0] fl_memory_address;
wire [15:0] fl_memory_data;
wire fl_wvalid;
wire fl_wready;

// CPU Top level

wire debug_trigger;
wire [15:0] debug_data;
wire debug_wr_enable;

slurm16_cpu_top cpu0
(
	CLK,
	RSTb,

	cpuMemoryAddr,
	cpuMemoryIn,
	cpuMemoryOut,
	cpuMemory_wr,		/* memory write */
	cpuMemory_rd,
	cpuMemory_wr_mask,	/* memory write mask */
	cpuMemory_success,

	cpuIMemoryAddr,
	cpuIMemoryData,
	cpuIMemory_success,

	cpuPort_address,
	cpuPort_in,
	cpuPort_out,
	cpuPort_rd,
	cpuPort_wr,

	cpuInterrupt,
	cpuIRQ,

	cpu_debug_pin,

	debug_trigger,
	debug_data,
	debug_wr_enable	
);



// Port controller

wire dummy;
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
	.cpu_debug_pin(dummy),
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
	.fl_memory_address(fl_memory_address),
	.fl_memory_data(fl_memory_data),
	.fl_wvalid(fl_wvalid),
	.fl_wready(fl_wready),
	.interrupt(cpuInterrupt),
	.irq(cpuIRQ),
	.debug_trigger(debug_trigger),
	.debug_data(debug_data),
	.debug_wr_enable(debug_wr_enable)
);

// Memory controller (wrapper to arbiter + ROM overlay)

slurm16_memory_controller
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

	fl_memory_address,
	fl_memory_data,
	fl_wvalid, // memory address valid
	fl_wready,  // memory data valid
	
	cpuMemoryAddr,
	cpuMemoryOut,
	cpuMemoryIn,
	cpuMemory_wr, // CPU is writing to memory
	cpuMemory_rd, // CPU is reading from memory
	cpuMemory_wr_mask,
	cpuMemory_success,

	cpuIMemoryAddr,
	cpuIMemoryData,
	cpuIMemory_success
);

endmodule
