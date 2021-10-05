module top
(
	output UART_TX,

	output GPIO1,
	output GPIO2,

	output RED_LED,
	output GREEN_LED,
	output BLUE_LED,

	output [3:0] BB,
	output [3:0] RR,
	output [3:0] GG,
	
	output HS,
	output VS,

	input CLK12,

	input UP_BUTTON,
	input DOWN_BUTTON,
	input LEFT_BUTTON,
	input RIGHT_BUTTON,
	input A_BUTTON,
	input B_BUTTON,

	output DAC_MCLK,
	output DAC_LRCLK,
	output DAC_SCLK,
	output DAC_SDIN,

	inout SPI_FLASH_MOSI,
	inout  SPI_FLASH_MISO,
	inout SPI_FLASH_SCK,
	inout SPI_FLASH_CSb

);

wire clk;

localparam CLOCKFREQ = 25125000;
wire locked;

SB_PLL40_PAD #(
   .FEEDBACK_PATH("SIMPLE"),
   .PLLOUT_SELECT("GENCLK"),
   .DIVR(4'b0000),
   .DIVF(7'b1000010),
   .DIVQ(3'b101),
   .FILTER_RANGE(3'b001),
 ) SB_PLL40_CORE_inst (
   .RESETB(1'b1),
   .BYPASS(1'b0),
   .PACKAGEPIN(CLK12),
   .PLLOUTCORE(clk),
);

reg [20:0] COUNT = 0;
wire RSTb = (COUNT < 10000) ? 1'b0 : 1'b1;

always @(posedge clk)
begin
	if (COUNT < 100000)
		COUNT <= COUNT + 1;	
end

wire [31:0] PINS;

wire [7:0] INPUT_PINS;

assign INPUT_PINS[0] = UP_BUTTON;
assign INPUT_PINS[1] = DOWN_BUTTON;
assign INPUT_PINS[2] = LEFT_BUTTON;
assign INPUT_PINS[3] = RIGHT_BUTTON;
assign INPUT_PINS[4] = A_BUTTON;
assign INPUT_PINS[5] = B_BUTTON;
assign INPUT_PINS[6] = 1'b0;

assign UART_TX = PINS[15];

assign RED_LED = PINS[8];
assign GREEN_LED = PINS[9];
assign BLUE_LED = PINS[10];

assign BB = PINS[19:16];
assign RR = PINS[23:20];
assign GG = PINS[27:24];
assign HS = PINS[28];
assign VS = PINS[29];

assign DAC_MCLK = PINS[11]; 
assign DAC_LRCLK = PINS[12];
assign DAC_SCLK = PINS[13];
assign DAC_SDIN = PINS[14];

wire MO;
wire MO_OE;
wire MI;
wire SO;
wire SO_OE;
wire SI;
wire SSb;
wire SSb_OE;
wire SCK_O;
wire SCK_I;
wire SCK_OE;

SB_IO #(
  .PIN_TYPE(6'b101001),
) miso_io (
  .PACKAGE_PIN(SPI_FLASH_MISO),
  .OUTPUT_ENABLE(SO_OE),
  .D_OUT_0(SO),
  .D_IN_0(MI)
);

SB_IO #(
  .PIN_TYPE(6'b101001),
) mosi_io (
  .PACKAGE_PIN(SPI_FLASH_MOSI),
  .OUTPUT_ENABLE(MO_OE),
  .D_OUT_0(MO),
  .D_IN_0(SI)
);

SB_IO #(
  .PIN_TYPE(6'b101001),
) sck_io (
  .PACKAGE_PIN(SPI_FLASH_SCK),
  .OUTPUT_ENABLE(SCK_OE),
  .D_OUT_0(SCK_O),
  .D_IN_0(SCK_I)
);

wire dummy;

SB_IO #(
  .PIN_TYPE(6'b1010_01),
) csb_io (
  .PACKAGE_PIN(SPI_FLASH_CSb),
  .OUTPUT_ENABLE(SSb_OE),
  .D_OUT_0(SSb),
  .D_IN_0(dummy)
);

slurm16 #(
	.CLOCK_FREQ(CLOCKFREQ)
) slm0 (
	clk,
	RSTb,
	PINS,
	INPUT_PINS,
 	MO,
    MO_OE,
    MI,
    SO,
    SO_OE,
    SI,
    SSb,
    SSb_OE,
    SCK_O,
    SCK_I,
    SCK_OE
);

endmodule
