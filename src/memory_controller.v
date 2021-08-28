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

reg [BITS - 1 : 0] DATA_OUT_REG;

always @(posedge CLK)
begin
	dout <= dout_next;
end

// ROM and HIRAM are synchronous so we mux them with the registered outputs from
// the other peripherals
assign DATA_OUT = DATA_OUT_REG; //(ADDRESS <= 16'h0fff) ? DATA_OUT_ROM : ((ADDRESS >= 16'h8000) ? DATA_OUT_HIRAM : dout);

always @(*)
begin

	WRb_HIRAM = 1'b1;
	WRb_UART  = 1'b1;
	WRb_GPIO  = 1'b1;
	WRb_PWM   = 1'b1;

	DATA_OUT_REG = {BITS{1'b0}};

	dout_next = {BITS{1'b0}};

	casex (ADDRESS)
		16'h0xxx: begin
			DATA_OUT_REG = DATA_OUT_ROM;
		end
		16'h10xx: begin
			dout_next = DATA_OUT_UART;
			WRb_UART = WRb;
			DATA_OUT_REG = dout;
		end
		16'h11xx: begin
			dout_next = DATA_OUT_GPIO;
			WRb_GPIO = WRb;
			DATA_OUT_REG = dout;
		end
		16'h12xx: begin
			dout_next = DATA_OUT_PWM;
			WRb_PWM = WRb;
			DATA_OUT_REG = dout;
		end
		16'b1xxxxxxxxxxxxxxx: begin
			WRb_HIRAM = WRb;
			DATA_OUT_REG = DATA_OUT_HIRAM;
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
#(.CLK_FREQ(CLOCK_FREQ), .BAUD_RATE(115200), .BITS(BITS)) u0
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
#(.CLK_FREQ(CLOCK_FREQ), .BITS(BITS)) g0
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
#(.CLK_FREQ(CLOCK_FREQ), .BITS(BITS)) led0
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
