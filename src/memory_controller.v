/* memory_controller.v : memory controller */

module memory_controller
#(parameter BITS = 16, ADDRESS_BITS = 16)
(
	input CLK,	
	input [ADDRESS_BITS - 1 : 0]  ADDRESS,
	inout [BITS - 1 : 0] DATA,
	input OEb, /* output enable */
	input WRb  /* write memory */
);

wire OEb_RAM = OEb | !ADDRESS[ADDRESS_BITS - 1];
wire OEb_ROM = OEb | ADDRESS[ADDRESS_BITS - 1];

wire WRb_RAM = WRb | !ADDRESS[ADDRESS_BITS - 1];

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
	OEb_RAM,
	WRb_RAM
);

endmodule
