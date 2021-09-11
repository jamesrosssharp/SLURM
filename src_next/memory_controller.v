/* memory_controller.v : memory controller */

/* Memory map:
 *
 *	0x0000 - 0x0fff:  4k x 16 bit boot ROM
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
	input memWR,  /* write memory */
	input memRD,  /* read request */
	output memBUSY, /* memory is busy (GFX / SND mem) */
	output [15:0] PINS /* output pins */ 
);

/* memory is never busy for now */
assign memBUSY = 1'b0;

reg [ADDRESS_BITS - 1 : 0] addr_reg;
reg [BITS - 1 : 0] DATA_OUT_REG;

wire [BITS - 1 : 0] DATA_OUT_ROM;

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		addr_reg <= {ADDRESS_BITS{1'b0}};
	end else begin
		addr_reg <= ADDRESS;
	end
end

assign DATA_OUT = DATA_OUT_REG; 

always @(*)
begin

	DATA_OUT_REG = {BITS{1'b0}};

	/* verilator lint_off CASEX */
	casex (addr_reg)
		16'h0xxx: begin
			DATA_OUT_REG = DATA_OUT_ROM;
		end
		default: ;
	endcase
	/* lint_on */
end

assign PINS[15:0] = 16'h0000;

rom #(.BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS - 1)) theRom
(
	CLK,
 	ADDRESS[ADDRESS_BITS - 2 : 0],
	DATA_OUT_ROM
);


endmodule
