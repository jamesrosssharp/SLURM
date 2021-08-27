/* memory_controller.v : memory controller */

/* Memory map:
 *
 *	0x0000 - 0x0fff:  4k x 16 bit boot ROM
 *	0x1000 - 0x10ff:  UART
 *  0x1100 - 0x11ff:  GPIO
 *  0x1200 - 0x12ff:  PWM LED
 *	0x1300 - 0x13ff:  Timers ?
 *	0x1400 - 0x14ff:  SPI ?
 *	0x1500 - 0x15ff:  I2C ?
 *	0x1600 - 0x16ff:  DMAC ?
 *
 *	0x4000 - 0x7fff:  OCM, 16k x 16 bit RAM, dual port - DMA able ?
 *
 *  0x8000 - 0xffff:  Hi memory, 32k x 16 bit RAM - program memory, single port, non-DMA able
 *
 * Pin assignments: 
 * 		7 - 0 	: GPIO output
 * 		10 - 8 	: PWM LED
 * 		14 - 11 : reserved
 * 		15		: UART tx 
 *
 */


module memory_controller
#(parameter BITS = 16, ADDRESS_BITS = 16, CLOCK_FREQ = 10000000)
(
	input CLK,	
	input RSTb,
	input [ADDRESS_BITS - 1 : 0]  ADDRESS,
	input [BITS - 1 : 0] DATA_IN,
	output [BITS - 1 : 0] DATA_OUT,
	input WRb,  /* write memory */
	output [15:0] PINS /* output pins */ 
);

reg WRb_HIRAM;
reg WRb_UART;
reg WRb_GPIO;
reg WRb_PWM;

wire [BITS - 1 : 0] DATA_OUT_HIRAM;
wire [BITS - 1 : 0] DATA_OUT_ROM;
wire [BITS - 1 : 0] DATA_OUT_UART;
wire [BITS - 1 : 0] DATA_OUT_GPIO;
wire [BITS - 1 : 0] DATA_OUT_PWM;

reg [BITS - 1 : 0] dout_next;
reg [BITS - 1 : 0] dout;

always @(posedge CLK)
begin
	dout <= dout_next;
end

// ROM and HIRAM are synchronous so we mux them with the registered outputs from
// the other peripherals
assign DATA_OUT = (ADDRESS < 16'h1000) ? DATA_OUT_ROM : ((ADDRESS >= 16'h8000) ? DATA_OUT_HIRAM : dout);

always @(*)
begin

	WRb_HIRAM = 1'b1;
	WRb_UART  = 1'b1;
	WRb_GPIO  = 1'b1;
	WRb_PWM   = 1'b1;

	dout_next = {BITS{1'b0}};

	casez (ADDRESS)
		16'h10??: begin
			dout_next = DATA_OUT_UART;
			WRb_UART = WRb;
		end
		16'h11??: begin
			dout_next = DATA_OUT_GPIO;
			WRb_GPIO = WRb;
		end
		16'h12??: begin
			dout_next = DATA_OUT_PWM;
			WRb_PWM = WRb;
		end
		16'b1000000000000000: begin
			WRb_HIRAM = 1'b0;
		end
		default: 
			dout_next = {BITS{1'b0}};
	endcase

end

assign PINS[14:11] = 4'b0000;

rom #(.BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS - 1)) theRom
(
	CLK,
 	ADDRESS[ADDRESS_BITS - 2 : 0],
	DATA_OUT_ROM
);


memory #(.BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS - 1)) theRam
(
	CLK,
	ADDRESS[ADDRESS_BITS - 2: 0],
	DATA_IN,
	DATA_OUT_HIRAM,
	WRb_HIRAM
);

uart 
#(.CLK_FREQ(CLOCK_FREQ), .BAUD_RATE(115200), .BITS(16)) u0
(
	CLK,	
	RSTb,
	ADDRESS[7:0],
	DATA_IN,
	DATA_OUT_UART,
	WRb_UART,  /* write memory  */
	PINS[15]   /* UART output   */
);

gpio
#(.CLK_FREQ(CLOCK_FREQ), .BITS(16)) g0
(
	CLK,	
	RSTb,
	ADDRESS[7:0],
	DATA_IN,
	DATA_OUT_GPIO,
	WRb_GPIO,  /* write memory */
	PINS[7:0] /* output pins */ 
);

pwm_led
#(.CLK_FREQ(CLOCK_FREQ), .BITS(16)) led0
(
	CLK,	
	RSTb,
	ADDRESS[7:0],
	DATA_IN,
	DATA_OUT_PWM,
	WRb_PWM,  /* write memory */
	PINS[10:8] /* output pins */ 
);

endmodule
