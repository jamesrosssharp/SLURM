`timescale 1 ns / 1 ps
module tb;

reg CLK  = 1;

always #50 CLK <= !CLK; // ~ 10MHz

reg RSTb = 1'b0;

initial begin 
	#150 RSTb = 1'b1;
end

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
    flash_csb
);





// Write rgb values to text file

integer f;
initial begin
    f = $fopen("simout.txt", "w");
end

integer k;
initial begin
	#2644800; 
	for (k = 0; k < 10; k += 1) begin
			$fwrite(f, "%0x", vid_r);
			$fwrite(f, "%0x", vid_g);
			$fwrite(f, "%0x", vid_b);
			$fwrite(f, "\n");
			#80000;
	end

end


initial begin
    $dumpvars(0, tb);
	# 4550000 $finish;
//	# 160375 $finish;
//	# 200000 $finish;
end

genvar j;
for (j = 0; j < 16; j = j + 1) begin
    initial $dumpvars(0, cpu0.cpu0.reg0.regFileA[j]);
end

endmodule
