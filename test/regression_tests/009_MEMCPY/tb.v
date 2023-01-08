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
wire  flash_miso;
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



initial begin
    $dumpvars(0, tb);
	# 10000000 $finish;
end

genvar j;
for (j = 0; j < 16; j = j + 1) begin
    initial $dumpvars(0, cpu0.cpu0.reg0.regFileA[j]);
end

for (j = 0; j < 16; j = j + 1) begin
    initial $dumpvars(0, cpu0.mem0.mb2.RAM[j]);
end



endmodule
