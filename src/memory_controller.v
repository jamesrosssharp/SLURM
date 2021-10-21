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
	output [31:0] PINS, /* output pins */ 
	input [7:0] INPUT_PINS /* input pins */
);

/* memory is never busy for now */
assign memBUSY = 1'b0;

reg WR_HIRAM;
reg WR_HIRAM2;
reg WR_HIRAM3;
reg WR_HIRAM4;
reg WR_UART;
reg WR_GPIO;
reg WR_PWM;
reg WR_GFX;
reg WR_AUDIO;
reg WR_SPI;

wire [BITS - 1 : 0] DATA_OUT_HIRAM;
wire [BITS - 1 : 0] DATA_OUT_HIRAM2;
wire [BITS - 1 : 0] DATA_OUT_HIRAM3;
wire [BITS - 1 : 0] DATA_OUT_HIRAM4;
wire [BITS - 1 : 0] DATA_OUT_ROM;
wire [BITS - 1 : 0] DATA_OUT_UART;
wire [BITS - 1 : 0] DATA_OUT_GPIO;
wire [BITS - 1 : 0] DATA_OUT_PWM;
wire [BITS - 1 : 0] DATA_OUT_GFX;
wire [BITS - 1 : 0] DATA_OUT_AUDIO;
wire [BITS - 1 : 0] DATA_OUT_SPI;

reg [BITS - 1 : 0] dout_next;
reg [BITS - 1 : 0] dout;

reg [BITS - 1 : 0] DATA_OUT_REG;

reg [ADDRESS_BITS - 1 : 0] addr_reg;

wire [ADDRESS_BITS - 3 : 0] GFX_B1_ADDR;
wire [BITS - 1 : 0] 		GFX_B1_DIN;
wire						GFX_B1_VALID;
wire						GFX_B1_READY;

wire [ADDRESS_BITS - 3 : 0] GFX_B2_ADDR;
wire [BITS - 1 : 0] 		GFX_B2_DIN;
wire						GFX_B2_VALID;
wire						GFX_B2_READY;

wire [ADDRESS_BITS - 3 : 0] GFX_B3_ADDR;
wire [BITS - 1 : 0]			GFX_B3_DIN;
wire						GFX_B3_VALID;
wire						GFX_B3_READY;

wire [ADDRESS_BITS - 3 : 0] GFX_B4_ADDR;
wire [BITS - 1 : 0]			GFX_B4_DIN;
wire						GFX_B4_VALID;
wire						GFX_B4_READY;

assign GFX_B1_DIN = DATA_OUT_HIRAM;
assign GFX_B2_DIN = DATA_OUT_HIRAM2;
assign GFX_B3_DIN = DATA_OUT_HIRAM3;
assign GFX_B4_DIN = DATA_OUT_HIRAM4;

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		dout <= {BITS{1'b0}};
		addr_reg <= {ADDRESS_BITS{1'b0}};
	end else begin
		dout <= dout_next;
		addr_reg <= ADDRESS;
	end
end

// ROM and HIRAM are synchronous so we mux them with the registered outputs from
// the other peripherals
assign DATA_OUT = DATA_OUT_REG; 

always @(*)
begin
	WR_HIRAM = 1'b0;
	WR_HIRAM2 = 1'b0;
	WR_HIRAM3 = 1'b0;
	WR_HIRAM4 = 1'b0;
	WR_UART  = 1'b0;
	WR_GPIO  = 1'b0;
	WR_PWM   = 1'b0;
	WR_GFX   = 1'b0;
	WR_AUDIO = 1'b0;
	WR_SPI   = 1'b0;

	dout_next = dout;

	casex (ADDRESS)
		16'h010x: begin
			dout_next = DATA_OUT_UART;
			WR_UART = memWR;
		end
		16'h011x: begin
			dout_next = DATA_OUT_GPIO;
			WR_GPIO = memWR;
		end
		16'h012x: begin
			dout_next = DATA_OUT_PWM;
			WR_PWM = memWR;
		end
		16'h013x: begin
			dout_next = DATA_OUT_AUDIO;
			WR_AUDIO = memWR;
		end
		16'h014x: begin
			dout_next = DATA_OUT_SPI;
			WR_SPI = memWR;
		end
		16'h1xxx: begin
			dout_next = DATA_OUT_GFX;
			WR_GFX = memWR;	
		end
		16'b00xxxxxxxxxxxxxx: begin
			WR_HIRAM = memWR;
		end
		16'b01xxxxxxxxxxxxxx: begin
			WR_HIRAM2 = memWR;
		end
		16'b10xxxxxxxxxxxxxx: begin
			WR_HIRAM3 = memWR;
		end
		16'b11xxxxxxxxxxxxxx: begin
			WR_HIRAM4 = memWR;
		end
		default: ;
	endcase
end

always @(*)
begin

	DATA_OUT_REG = {BITS{1'b0}};

	casex (addr_reg)
		16'h00xx: begin
			DATA_OUT_REG = DATA_OUT_ROM;
		end
		16'h01xx, 16'h02xx, 16'h03xx, 16'h04xx, 16'h05xx: begin
			DATA_OUT_REG = dout;
		end
		16'h1xxx: begin
			DATA_OUT_REG = dout;
		end
		16'b00xxxxxxxxxxxxxx: begin
			DATA_OUT_REG = DATA_OUT_HIRAM;
		end
		16'b01xxxxxxxxxxxxxx: begin
			DATA_OUT_REG = DATA_OUT_HIRAM2;
		end
		16'b10xxxxxxxxxxxxxx: begin
			DATA_OUT_REG = DATA_OUT_HIRAM3;
		end
		16'b11xxxxxxxxxxxxxx: begin
			DATA_OUT_REG = DATA_OUT_HIRAM4;
		end
		default: ;
	endcase

end

rom #(.BITS(BITS), .ADDRESS_BITS(8)) theRom
(
	CLK,
 	ADDRESS[7 : 0],
	DATA_OUT_ROM
);


memory #(.BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS - 2)) theRam
(
	CLK,
	ADDRESS[ADDRESS_BITS - 3 : 0],
	DATA_IN,
	DATA_OUT_HIRAM,
	WR_HIRAM,
	GFX_B1_ADDR,
	GFX_B1_VALID,
	GFX_B1_READY
);

memory #(.BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS - 2)) theRam2
(
	CLK,
	ADDRESS[ADDRESS_BITS - 3 : 0],
	DATA_IN,
	DATA_OUT_HIRAM2,
	WR_HIRAM2,
	GFX_B2_ADDR,
	GFX_B2_VALID,
	GFX_B2_READY
);

memory #(.BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS - 2)) theRam3
(
	CLK,
	ADDRESS[ADDRESS_BITS - 3 : 0],
	DATA_IN,
	DATA_OUT_HIRAM3,
	WR_HIRAM3,
	GFX_B3_ADDR,
	GFX_B3_VALID,
	GFX_B3_READY
);

memory #(.BITS(BITS), .ADDRESS_BITS(ADDRESS_BITS - 2)) theRam4
(
	CLK,
	ADDRESS[ADDRESS_BITS - 3 : 0],
	DATA_IN,
	DATA_OUT_HIRAM4,
	WR_HIRAM4,
	GFX_B4_ADDR,
	GFX_B4_VALID,
	GFX_B4_READY
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
	PINS[15]   // UART output   
);


gpio
#(.CLK_FREQ(CLOCK_FREQ), .BITS(BITS)) g0
(
	CLK,	
	RSTb,
	ADDRESS[3:0],
	DATA_IN,
	DATA_OUT_GPIO,
	WR_GPIO,  // write memory 
	PINS[3:0], // output pins  
	INPUT_PINS[5:0] // input pins
);


pwm_led
#(.CLK_FREQ(CLOCK_FREQ), .BITS(BITS)) led0
(
	CLK,	
	RSTb,
	ADDRESS[3:0],
	DATA_IN,
	DATA_OUT_PWM,
	WR_PWM,  // write memory 
	PINS[10:8] // output pins 
);


assign PINS[31:30] = 2'b00;

gfx #(.BITS(BITS), .BANK_ADDRESS_BITS(14), .ADDRESS_BITS(12)) gfx0
(
	.CLK(CLK),
	.RSTb(RSTb),
	.ADDRESS(ADDRESS[11:0]),
	.DATA_IN(DATA_IN),
	.DATA_OUT(DATA_OUT_GFX),
	.WR(WR_GFX), 
	.HS(PINS[28]),
	.VS(PINS[29]),
	.BB(PINS[19:16]),
	.RR(PINS[23:20]),
	.GG(PINS[27:24]),
	.B1_ADDR(GFX_B1_ADDR),
	.B1_DIN(GFX_B1_DIN),
	.B1_VALID(GFX_B1_VALID),
	.B1_READY(GFX_B1_READY),
	.B2_ADDR(GFX_B2_ADDR),
	.B2_DIN(GFX_B2_DIN),
	.B2_VALID(GFX_B2_VALID),
	.B2_READY(GFX_B2_READY),
	.B3_ADDR(GFX_B3_ADDR),
	.B3_DIN(GFX_B3_DIN),
	.B3_VALID(GFX_B3_VALID),
	.B3_READY(GFX_B3_READY),
	.B4_ADDR(GFX_B4_ADDR),
	.B4_DIN(GFX_B4_DIN),
	.B4_VALID(GFX_B4_VALID),
	.B4_READY(GFX_B4_READY)
);

audio
#(.BITS(BITS), .ADDRESS_BITS(8), .CLK_FREQ(CLOCK_FREQ)) aud0
(
	CLK,	
	RSTb,
	ADDRESS[3:0],
	DATA_IN,
	DATA_OUT_AUDIO,
	WR_AUDIO, 
	PINS[14:11]
);

spi_flash
#(.BITS(BITS), .ADDRESS_BITS(8), .CLK_FREQ(CLOCK_FREQ)) spi_flash0
(
	CLK,	
	RSTb,
	ADDRESS[3:0],
	DATA_IN,
	DATA_OUT_SPI,
	WR_SPI,
	PINS[4],
	INPUT_PINS[7],
	PINS[5],
	PINS[6]
);


endmodule
