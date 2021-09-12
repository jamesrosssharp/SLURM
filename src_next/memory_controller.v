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

reg WR_HIRAM;
reg WR_UART;
reg WR_GPIO;
reg WR_PWM;

wire [BITS - 1 : 0] DATA_OUT_HIRAM;
wire [BITS - 1 : 0] DATA_OUT_ROM;
wire [BITS - 1 : 0] DATA_OUT_UART;
wire [BITS - 1 : 0] DATA_OUT_GPIO;
wire [BITS - 1 : 0] DATA_OUT_PWM;

reg [BITS - 1 : 0] dout_next;
reg [BITS - 1 : 0] dout;

reg [BITS - 1 : 0] DATA_OUT_REG;

reg [ADDRESS_BITS - 1 : 0] addr_reg;

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
	WR_UART  = 1'b0;
	WR_GPIO  = 1'b0;
	WR_PWM   = 1'b0;

	dout_next = dout;

	casex (ADDRESS)
		16'h10xx: begin
			dout_next = DATA_OUT_UART;
			WR_UART = memWR;
		end
		16'h11xx: begin
			dout_next = DATA_OUT_GPIO;
			WR_GPIO = memWR;
		end
		16'h12xx: begin
			dout_next = DATA_OUT_PWM;
			WR_PWM = memWR;
		end
		16'b1xxxxxxxxxxxxxxx: begin
			WR_HIRAM = memWR;
		end
		default: ;
	endcase
end

always @(*)
begin

	DATA_OUT_REG = {BITS{1'b0}};

	casex (addr_reg)
		16'h0xxx: begin
			DATA_OUT_REG = DATA_OUT_ROM;
		end
		16'h10xx: begin
			DATA_OUT_REG = dout;
		end
		16'h11xx: begin
			DATA_OUT_REG = dout;
		end
		16'h12xx: begin
			DATA_OUT_REG = dout;
		end
		16'b1xxxxxxxxxxxxxxx: begin
			DATA_OUT_REG = DATA_OUT_HIRAM;
		end
		default: ;
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
	WR_HIRAM
);

uart 
#(.CLK_FREQ(CLOCK_FREQ), .BAUD_RATE(115200), .BITS(BITS)) u0
(
	CLK,	
	RSTb,
	ADDRESS[7:0],
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
	ADDRESS[7:0],
	DATA_IN,
	DATA_OUT_GPIO,
	WR_GPIO,  // write memory 
	PINS[7:0] // output pins  
);


pwm_led
#(.CLK_FREQ(CLOCK_FREQ), .BITS(BITS)) led0
(
	CLK,	
	RSTb,
	ADDRESS[7:0],
	DATA_IN,
	DATA_OUT_PWM,
	WR_PWM,  // write memory 
	PINS[10:8] // output pins 
);



endmodule
