/* port_controller.v : IO memory controller */

/* Memory map:
 *
 *
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
	output [31:0] PINS, /* output pins */ 
	input [7:0] INPUT_PINS /* input pins */

	// Memory ports

	// Sprite

	// BGCON0
	
	// BGCON1
	
	// OV

	// Spi flash (write)

	// Audio 

);


reg WR_UART;
reg WR_GPIO;
reg WR_PWM;
reg WR_GFX;
reg WR_AUDIO;
reg WR_SPI;

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

wire spi_flash_wvalid;
wire spi_flash_wready;
wire [15:0] spi_flash_memory_address;
wire [15:0] spi_flash_memory_data;

reg busy_r, busy_r_next;
assign 	memBUSY = busy_r;

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

	dout_next = dout;
	busy_r_next = 1'b0;

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
		default: ;
	endcase
end

always @(*)
begin

	DATA_OUT_REG = {BITS{1'b0}};

	casex (addr_reg)
		16'h01xx, 16'h02xx, 16'h03xx, 16'h04xx, 16'h05xx: begin
			DATA_OUT_REG = dout;
		end
		16'h1xxx: begin /* gfx reads are already delayed by one cycle */ 
			DATA_OUT_REG = DATA_OUT_GFX;
		end
		default: ;
	endcase

end

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
);

/*audio
#(.BITS(BITS), .ADDRESS_BITS(8), .CLK_FREQ(CLOCK_FREQ)) aud0
(
	CLK,	
	RSTb,
	ADDRESS[3:0],
	DATA_IN,
	DATA_OUT_AUDIO,
	WR_AUDIO, 
	PINS[14:11]
);*/

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
	PINS[6],
	spi_flash_wvalid,
	spi_flash_wready,
	spi_flash_memory_address,
	spi_flash_memory_data
);


endmodule
