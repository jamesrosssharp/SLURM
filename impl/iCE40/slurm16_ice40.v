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

	output SPI_FLASH_MOSI,
	input  SPI_FLASH_MISO,
	output SPI_FLASH_SCK,
	output SPI_FLASH_CSb

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

wire [3:0] gpio_out;
wire [5:0] gpio_in;

wire [3:0] vid_r;
wire [3:0] vid_g;
wire [3:0] vid_b;
wire vid_hsync;
wire vid_vsync;

wire uart_tx;

wire led_r;
wire led_g;
wire led_b;

wire i2s_sclk;
wire i2s_lrclk;
wire i2s_data;
wire i2s_mclk;

wire flash_mosi;
wire  flash_miso;
wire flash_sclk;
wire flash_csb;

slurm16 #(
.CLOCK_FREQ(CLOCKFREQ)
) cpu0 (
	clk,
	RSTb,
    gpio_out,
    gpio_in,

    vid_r,
    vid_g,
    vid_b,
    vid_hsync,
    vid_vsync,

    uart_tx,
    
    led_r,
    led_g,
    led_b,
    
    i2s_sclk,
    i2s_lrclk,
    i2s_data,
    i2s_mclk,
    
    flash_mosi,
    flash_miso,
    flash_sclk,
    flash_csb
);

assign GPIO1 = gpio_out[0];
assign GPIO2 = gpio_out[1]; 

assign gpio_in[0] = UP_BUTTON;
assign gpio_in[1] = DOWN_BUTTON;
assign gpio_in[2] = LEFT_BUTTON;
assign gpio_in[3] = RIGHT_BUTTON;
assign gpio_in[4] = A_BUTTON;
assign gpio_in[5] = B_BUTTON;
assign flash_miso = SPI_FLASH_MISO;

assign UART_TX = uart_tx;

assign RED_LED   = led_r;
assign GREEN_LED = led_g;
assign BLUE_LED  = led_b;

assign BB = vid_b;
assign RR = vid_r;
assign GG = vid_g;
assign HS = vid_hsync;
assign VS = vid_vsync;

assign DAC_MCLK = i2s_mclk; 
assign DAC_LRCLK = i2s_lrclk;
assign DAC_SCLK = i2s_sclk;
assign DAC_SDIN = i2s_data;

assign SPI_FLASH_MOSI = flash_mosi;
assign SPI_FLASH_SCK = flash_sclk;
assign SPI_FLASH_CSb = flash_csb;


endmodule
