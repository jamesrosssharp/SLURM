/* port_controller.v : IO memory controller */

/* Memory map:
 *
 * 0x0000 - 0x0fff: UART
 * 0x1000 - 0x1fff: GPIO
 * 0x2000 - 0x2fff: PWM
 * 0x3000 - 0x3fff: Audio
 * 0x4000 - 0x4fff: SPI
 * 0x5000 - 0x5fff: GFX
 * 0x6000 - 0x6fff: Trace port 
 * 0x7000 - 0x7fff: Interrupt controller
 * 0x8000 - 0x83ff: scratch pad RAM
 * 0x9000 - 0x9fff: timer
 */

module port_controller
#(parameter BITS = 16, ADDRESS_BITS = 16, CLOCK_FREQ = 10000000)
(
	input CLK,	
	input RSTb,
	input [ADDRESS_BITS - 1 : 0]  ADDRESS,
	input [BITS - 1 : 0] DATA_IN,
	output [BITS - 1 : 0] DATA_OUT,
	input memWR,  /* write memory */
	input memRD,  /* read request */

	// Pins

	input  cpu_debug_pin,	/* debug pin from CPU; to trace signals on oscilloscope */

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

	// Memory ports

	// Sprite
	output  [15:0] 	spcon_memory_address,
	input [15:0] 	spcon_memory_data,
	output 			spcon_rvalid, // memory address valid
	input  			spcon_rready,  // memory data valid

	// BGCON0
	output  [15:0] 	bg0_memory_address,
	input [15:0] 	bg0_memory_data,
	output 			bg0_rvalid, // memory address valid
	input  			bg0_rready,  // memory data valid

	// BGCON1
	output  [15:0] 	bg1_memory_address,
	input [15:0] 	bg1_memory_data,
	output 			bg1_rvalid, // memory address valid
	input  			bg1_rready,  // memory data valid

	// Spi flash (write)
	output  [15:0] 	fl_memory_address,
	output [15:0] 	fl_memory_data,
	output 			fl_wvalid, // memory address valid
	input  			fl_wready,  // memory data valid
	
	// Interrupt request quotients
	output [3:0]	irq,
	output			interrupt,

	// Debug
	input debug_trigger,
	input [15:0] debug_data,
	input debug_wr_enable
);

wire irq_hsync;
wire irq_vsync;
wire irq_audio;
wire irq_spi_flash;
wire irq_timer;

//assign gpio_out[0] = cpu_debug_pin;

reg WR_UART;
reg WR_GPIO;
reg WR_PWM;
reg WR_GFX;
reg WR_AUDIO;
reg WR_SPI;
reg WR_TRACE;
reg WR_INTERRUPT;
reg WR_SCRATCH;
reg WR_TIMER;

wire RD_TRACE = 1'b0;
reg RD_DEBUG;


wire [BITS - 1 : 0] DATA_OUT_ROM;
wire [BITS - 1 : 0] DATA_OUT_UART;
wire [BITS - 1 : 0] DATA_OUT_GPIO;
wire [BITS - 1 : 0] DATA_OUT_PWM;
wire [BITS - 1 : 0] DATA_OUT_GFX;
wire [BITS - 1 : 0] DATA_OUT_AUDIO;
wire [BITS - 1 : 0] DATA_OUT_SPI;
wire [BITS - 1 : 0] DATA_OUT_TRACE;
wire [BITS - 1 : 0] DATA_OUT_INTERRUPT;
wire [BITS - 1 : 0] DATA_OUT_SCRATCH;
wire [BITS - 1 : 0] DATA_OUT_TIMER;

reg [BITS - 1 : 0] dout_next;
reg [BITS - 1 : 0] dout;

reg [BITS - 1 : 0] DATA_OUT_REG;

reg [ADDRESS_BITS - 1 : 0] addr_reg;

wire spi_flash_wvalid;
wire spi_flash_wready;
wire [15:0] spi_flash_memory_address;
wire [15:0] spi_flash_memory_data;

wire gpio_int;

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		dout 	 <= {BITS{1'b0}};
		addr_reg <= {ADDRESS_BITS{1'b0}};
	end else begin
		dout 	 <= dout_next;
		addr_reg <= ADDRESS;
	end
end

// ROM and HIRAM are synchronous so we mux them with the registered outputs from
// the other peripherals
assign DATA_OUT = DATA_OUT_REG; 

always @(CLK)
begin
	WR_UART  = 1'b0;
	WR_GPIO  = 1'b0;
	WR_PWM   = 1'b0;
	WR_GFX   = 1'b0;
	WR_AUDIO = 1'b0;
	WR_SPI   = 1'b0;
	WR_TRACE = 1'b0;
	WR_INTERRUPT = 1'b0;
	WR_SCRATCH = 1'b0;
	WR_TIMER = 1'b0;

	dout_next = dout;

	casex (ADDRESS)
		16'h0xxx: begin
			dout_next = DATA_OUT_UART;
			WR_UART = memWR;
		end
		16'h1xxx: begin
			dout_next = DATA_OUT_GPIO;
			WR_GPIO = memWR;
		end
		16'h2xxx: begin
			dout_next = DATA_OUT_PWM;
			WR_PWM = memWR;
		end
		16'h3xxx: begin
			dout_next = DATA_OUT_AUDIO;
			WR_AUDIO = memWR;
		end
		16'h4xxx: begin
			dout_next = DATA_OUT_SPI;
			WR_SPI = memWR;
		end
		16'h5xxx: begin
			WR_GFX = memWR;	
		end
		16'h6xxx: begin
			WR_TRACE = memWR;
		end
		16'h7xxx: begin
			dout_next = DATA_OUT_INTERRUPT;
			WR_INTERRUPT = memWR;
		end
		16'h8xxx: begin
			WR_SCRATCH = memWR;
		end
		16'h9xxx: begin
			dout_next = DATA_OUT_TIMER;
			WR_TIMER = memWR;
		end
		default: ;
	endcase
end

always @(*)
begin

	DATA_OUT_REG = {BITS{1'b0}};
	RD_DEBUG = 1'b0;

	casex (addr_reg)
		16'h0xxx, 16'h1xxx, 16'h2xxx, 16'h3xxx, 16'h4xxx, 16'h6xxx, 16'h7xxx, 16'h9xxx: begin
			DATA_OUT_REG = dout;
		end
		16'h5xxx: begin /* gfx reads are already delayed by one cycle */ 
			DATA_OUT_REG = DATA_OUT_GFX;
		end
		16'h8xxx: begin
			DATA_OUT_REG = DATA_OUT_SCRATCH;
		end
		16'haxxx: begin
			DATA_OUT_REG = DATA_OUT_TRACE;
			RD_DEBUG = 1'b1; /*memRD*/; 
		end
		default: ;
	endcase

end

// Debug trace port for simulations

trace tr0 (
	CLK,
	RSTb,
	ADDRESS[3:0],
	DATA_IN,
	DATA_OUT_TRACE,
	WR_TRACE,
	RD_TRACE
);

/*wire [15:0] count_lo;
wire [15:0] count_hi;


cpu_debug_core2 deb0 (
	CLK,
	debug_trigger,
	debug_data,
	DATA_OUT_TRACE,
	RD_DEBUG,
	debug_wr_enable
);*/

`ifndef WITHOUT_UART
uart 
#(.CLK_FREQ(CLOCK_FREQ), .BAUD_RATE(115200), .BITS(BITS)) u0
(
	CLK,	
	RSTb,
	ADDRESS[3:0],
	DATA_IN,
	DATA_OUT_UART,
	WR_UART,  // write memory  
	uart_tx   // UART output   
);
`else
assign DATA_OUT_UART = 16'd0;
`endif

`ifndef WITHOUT_GPIO
gpio
#(.CLK_FREQ(CLOCK_FREQ), .BITS(BITS)) g0
(
	CLK,	
	RSTb,
	ADDRESS[3:0],
	DATA_IN,
	DATA_OUT_GPIO,
	WR_GPIO,  // write memory 
	gpio_out, // output pins  
	gpio_in, // input pins
	gpio_int
);
`else
assign DATA_OUT_GPIO = 16'd0;
`endif


`ifndef WITHOUT_PWM
pwm_led
#(.CLK_FREQ(CLOCK_FREQ), .BITS(BITS)) led0
(
	CLK,	
	RSTb,
	ADDRESS[3:0],
	DATA_IN,
	DATA_OUT_PWM,
	WR_PWM,  // write memory 
	led_r, // output pins 
	led_g,
	led_b
);
`else
assign DATA_OUT_PWM = 16'd0;
`endif


`ifndef WITHOUT_GFX
gfx #(.BITS(BITS), .BANK_ADDRESS_BITS(14), .ADDRESS_BITS(12)) gfx0
(
	.CLK(CLK),
	.RSTb(RSTb),
	.ADDRESS(ADDRESS[11:0]),
	.DATA_IN(DATA_IN),
	.DATA_OUT(DATA_OUT_GFX),
	.WR(WR_GFX), 
	.HS(vid_hsync),
	.VS(vid_vsync),
	.BB(vid_b),
	.RR(vid_r),
	.GG(vid_g),
	.BLANK(vid_blank),
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
	.irq_hsync(irq_hsync),
	.irq_vsync(irq_vsync)
);
`else
assign DATA_OUT_GFX = 16'd0;
`endif

`ifndef WITHOUT_AUDIO
audio
#(.BITS(BITS), .ADDRESS_BITS(12), .CLK_FREQ(CLOCK_FREQ)) aud0
(
	CLK,	
	RSTb,
	ADDRESS[11:0],
	DATA_IN,
	DATA_OUT_AUDIO,
	WR_AUDIO, 
	i2s_mclk,
	i2s_lrclk,
	i2s_sclk,
	i2s_data,
	irq_audio
);
`else
assign DATA_OUT_AUDIO = 16'd0;
`endif

`ifndef WITHOUT_SPI_FLASH
spi_flash
#(.BITS(BITS), .ADDRESS_BITS(8), .CLK_FREQ(CLOCK_FREQ)) spi_flash0
(
	CLK,	
	RSTb,
	ADDRESS[7:0],
	DATA_IN,
	DATA_OUT_SPI,
	WR_SPI,
	flash_mosi,
	flash_miso,
	flash_sclk,
	flash_csb, 
	fl_wvalid,
	fl_wready,
	fl_memory_address,
	fl_memory_data,
	irq_spi_flash
);
`else
assign DATA_OUT_SPI = 16'd0;
`endif

`ifndef WITHOUT_INTERRUPT_CONTROLLER
interrupt_controller #(.BITS(BITS)) irq0
(
	CLK,	
	RSTb,
	ADDRESS[3:0],
	DATA_IN,
	DATA_OUT_INTERRUPT,
	WR_INTERRUPT,
	irq_hsync,
	irq_vsync,
	irq_audio,
	irq_spi_flash,
	irq_timer,
	gpio_int,
	interrupt,	
	irq
);
`else
assign DATA_OUT_INTERRUPT = 16'd0;
assign interrupt = 1'b0;
assign irq = 4'b0000;
`endif

// Scratchpad RAM

`ifndef WITHOUT_SCRATCH_PAD
bram #(.BITS(16), .ADDRESS_BITS(9)) scr0
(
	CLK,
	ADDRESS[8:0],
	DATA_OUT_SCRATCH,
	ADDRESS[8:0],
	DATA_IN,
	WR_SCRATCH
);
`else
assign DATA_OUT_SCRATCH = 16'd0;
`endif



`ifndef WITHOUT_TIMER
timer tim0
(
	CLK,
	RSTb,
	ADDRESS[3:0],
	DATA_IN,
	DATA_OUT_TIMER,
	WR_TIMER,
	irq_timer,
	count_lo,
	count_hi
);



`else
assign DATA_OUT_TIMER = 16'd0;
`endif



endmodule
