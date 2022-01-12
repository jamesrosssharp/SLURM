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

	// OV
	output  [15:0] 	ov_memory_address,
	input [15:0] 	ov_memory_data,
	output 			ov_rvalid, // memory address valid
	input  			ov_rready,  // memory data valid

	// Spi flash (write)
	output  [15:0] 	fl_memory_address,
	output [15:0] 	fl_memory_data,
	output 			fl_wvalid, // memory address valid
	input  			fl_wready,  // memory data valid
	
	// Audio 
	output  [15:0] 	au_memory_address,
	input [15:0] 	au_memory_data,
	output 			au_rvalid, // memory address valid
	input  			au_rready,  // memory data valid

	// Interrupt request quotients
	output [3:0]	irq

);

assign gpio_out[0] = cpu_debug_pin;

// TODO: remove this when we add in the audio core
assign au_rvalid = 1'b0;


reg WR_UART;
reg WR_GPIO;
reg WR_PWM;
reg WR_GFX;
reg WR_AUDIO;
reg WR_SPI;
reg WR_TRACE;

wire RD_TRACE = 1'b0;

wire [BITS - 1 : 0] DATA_OUT_ROM;
wire [BITS - 1 : 0] DATA_OUT_UART;
wire [BITS - 1 : 0] DATA_OUT_GPIO;
wire [BITS - 1 : 0] DATA_OUT_PWM;
wire [BITS - 1 : 0] DATA_OUT_GFX;
wire [BITS - 1 : 0] DATA_OUT_AUDIO;
wire [BITS - 1 : 0] DATA_OUT_SPI;
wire [BITS - 1 : 0] DATA_OUT_TRACE;

reg [BITS - 1 : 0] dout_next;
reg [BITS - 1 : 0] dout;

reg [BITS - 1 : 0] DATA_OUT_REG;

reg [ADDRESS_BITS - 1 : 0] addr_reg;

wire spi_flash_wvalid;
wire spi_flash_wready;
wire [15:0] spi_flash_memory_address;
wire [15:0] spi_flash_memory_data;

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

always @(*)
begin
	WR_UART  = 1'b0;
	WR_GPIO  = 1'b0;
	WR_PWM   = 1'b0;
	WR_GFX   = 1'b0;
	WR_AUDIO = 1'b0;
	WR_SPI   = 1'b0;
	WR_TRACE = 1'b0;

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
			dout_next = DATA_OUT_GFX;
			WR_GFX = memWR;	
		end
		16'h6xxx: begin
			WR_TRACE = memWR;
		end
		default: ;
	endcase
end

always @(*)
begin

	DATA_OUT_REG = {BITS{1'b0}};

	casex (addr_reg)
		16'h0xxx, 16'h1xxx, 16'h2xxx, 16'h3xxx, 16'h4xxx, 16'h6xxx: begin
			DATA_OUT_REG = dout;
		end
		16'h5xxx: begin /* gfx reads are already delayed by one cycle */ 
			DATA_OUT_REG = DATA_OUT_GFX;
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

/*
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
	gpio_in // input pins
);
*/


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

/*
assign PINS[31:30] = 2'b00;

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
	.ov_rready(ov_rready)
);
*/

/*audio
#(.BITS(BITS), .ADDRESS_BITS(8), .CLK_FREQ(CLOCK_FREQ)) aud0
(
	CLK,	
	RSTb,
	ADDRESS[3:0],
	DATA_IN,
	DATA_OUT_AUDIO,
	WR_AUDIO, 
	i2s_sclk,
	i2s_lrclk,
	i2s_data,
	i2s_mclk
);*/

/*
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
	fl_memory_data
);
*/

endmodule
