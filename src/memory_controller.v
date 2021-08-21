/* memory_controller.v : memory controller */

/* Memory map:
 *
 *	0x0000 - 0x0fff:  4k x 16 bit boot ROM
 *	0x1000 - 0x10ff:  UART
 *	0x1100 - 0x11ff:  Timers ?
 *	0x1200 - 0x12ff:  SPI ?
 *	0x1300 - 0x13ff:  I2C ?
 *	0x1400 - 0x14ff:  GPIO ?
 *	0x1500 - 0x15ff:  DMAC ?
 *
 *	0x4000 - 0x7fff:  OCM, 16k x 16 bit RAM, dual port - DMA able ?
 *
 *  0x8000 - 0xffff:  Hi memory, 32k x 16 bit RAM - program memory, single port, non-DMA able
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

wire [BITS - 1 : 0] DATA_OUT_HIRAM;
wire [BITS - 1 : 0] DATA_OUT_ROM;
wire [BITS - 1 : 0] DATA_OUT_UART;

reg [BITS - 1 : 0] dout;
assign DATA_OUT = dout;

always @(*)
begin

	WRb_HIRAM = 1'b1;
	WRb_UART  = 1'b1;

	casez (ADDRESS)
		16'h0???:
			dout = DATA_OUT_ROM;
		16'h10??: begin
			dout = DATA_OUT_UART;
			WRb_UART = WRb;
		end
		16'b1???????????????: begin
			dout = DATA_OUT_HIRAM;
			WRb_HIRAM = WRb;
		end		
		default:
			dout = {BITS{1'b0}};
	endcase

end

assign PINS[14:0] = 15'b000000000000000;

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

endmodule
