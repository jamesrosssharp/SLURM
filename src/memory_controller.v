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
	inout [BITS - 1 : 0] DATA,
	input OEb, /* output enable */
	input WRb,  /* write memory */
	output [15:0] PINS /* output pins */ 
);

reg OEb_HIRAM;
reg OEb_ROM;
reg OEb_UART;

reg WRb_HIRAM;
reg WRb_UART;

always @(*)
begin
	OEb_ROM   = 1'b1;
	OEb_HIRAM = 1'b1;
	OEb_UART  = 1'b1;

	WRb_HIRAM = 1'b1;
	WRb_UART  = 1'b1;

	casex (ADDRESS)
		16'h0xxx:
			OEb_ROM = OEb;
		16'h10xx: begin
			OEb_UART = OEb;
			WRb_UART = WRb;
		end
		16'b1xxxxxxxxxxxxxxx: begin
			OEb_HIRAM = OEb;
			WRb_HIRAM = WRb;
		end		
		default: ;
	endcase

end

assign PINS[14:0] = 15'b000000000000000;

rom #(.BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS - 1)) theRom
(
	CLK,
 	ADDRESS[ADDRESS_BITS - 2 : 0],
	DATA,
	OEb_ROM
);

memory #(.BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS - 1)) theRam
(
	CLK,
	ADDRESS[ADDRESS_BITS - 2: 0],
	DATA,
	OEb_HIRAM,
	WRb_HIRAM
);

uart 
#(.CLK_FREQ(CLOCK_FREQ), .BAUD_RATE(115200), .BITS(16)) u0
(
	CLK,	
	RSTb,
	ADDRESS[7:0],
	DATA,
	OEb_UART,  /* output enable */
	WRb_UART,  /* write memory  */
	PINS[15]   /* UART output   */
);

endmodule
