`timescale 1 ns / 1 ps
module tb;

reg CLK  = 1;

always #50 CLK <= !CLK; // ~ 10MHz

reg RSTb = 1'b0;

wire [3:0] gpio_out;
wire [5:0] gpio_in;

wire [3:0] vid_r;
wire [3:0] vid_g;
wire [3:0] vid_b;
wire vid_hsync;
wire vid_vsync;
wire vid_blank;

wire uart_tx;

wire led_r;
wire led_g;
wire led_b;

wire i2s_sclk;
wire i2s_lrclk;
wire i2s_data;
wire i2s_mclk;

wire flash_mosi;
reg  flash_miso;
wire flash_sclk;
wire flash_csb;

wire cpu_debug_pin;

slurm16 #(
.CLOCK_FREQ(10000000)
) cpu0 (
	CLK,
	RSTb,
    gpio_out,
    gpio_in,

    vid_r,
    vid_g,
    vid_b,
    vid_hsync,
    vid_vsync,
    vid_blank,

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
    flash_csb,

    cpu_debug_pin
);

initial begin 
	#150 RSTb = 1'b1;
end

integer i, k;

reg [7:0] UART_BYTE = 8'h00;

reg [63:0] SPI_BYTE;

integer f;

initial begin
    f = $fopen("simout.txt", "w");
end

localparam BAUD_TICK = 1e9/115200;

always begin
	@(negedge uart_tx);
	#(BAUD_TICK/2); // start bit
	UART_BYTE <= 8'h00;
	for (i = 0; i < 8; i += 1) begin
		#BAUD_TICK; // bits
		UART_BYTE <= {uart_tx, UART_BYTE[7:1]};	
	end
	#BAUD_TICK; // stop bit
	$fwrite(f, "%c", UART_BYTE);
end

always begin
	SPI_BYTE <= 64'h4243424342434243;
	@(negedge flash_csb);
	flash_miso <= SPI_BYTE[63];
	@(negedge flash_csb);
	SPI_BYTE <= {SPI_BYTE[126:0], 1'b0};	
	for (k = 0; k < 64; k += 1) begin
		@(negedge flash_sclk);
		SPI_BYTE <= {SPI_BYTE[126:0], 1'b0};	
		flash_miso <= SPI_BYTE[63];
	end
//	@(posedge flash_csb);
end



initial begin
    $dumpfile("cpu_mem_stall_test.vcd");
    $dumpvars(0, tb);
	# 10000000 $finish;
end

genvar j;
for (j = 0; j < 16; j = j + 1) begin
    initial $dumpvars(0, cpu0.cpu0.reg0.regFileA[j]);
end

endmodule
