module slurm16_top
#(
  //  modes tested on lenovo monitor
  //  640x400  @50Hz
  //  640x400  @60Hz
  //  640x480  @50Hz
  //  640x480  @60Hz
  //  720x576  @50Hz
  //  720x576  @60Hz
  //  800x480  @60Hz
  //  800x600  @60Hz
  // 1024x768  @60Hz
  // 1280x768  @60Hz
  // 1366x768  @60Hz
  // 1280x1024 @60Hz
  // 1920x1080 @30Hz
  // 1920x1080 @50Hz overclock 540MHz
  // 1920x1200 @50Hz overclock 600MHz
  parameter x =  640,      // pixels
  parameter y =  480,      // pixels
  parameter f =   60,      // Hz 60,50,30
  parameter xadjustf =  0, // adjust -3..3 if no picture
  parameter yadjustf =  0, // or to fine-tune f
  parameter c_ddr    =  1  // 0:SDR 1:DDR
)
(
  input        clk_25mhz,
  input  [6:0] btn,
  output [7:0] led,
  output [3:0] gpdi_dp,
  output       user_programn,
  output       wifi_gpio0,
  output       gp0,
  output       gp1,
  output       gp2,
  output       gp3,
  output       gp4,
  output [3:0] audio_l,
  output [3:0] audio_r
);

  function integer F_find_next_f(input integer f);
    if(25000000>f)
      F_find_next_f=25000000;
    else if(27000000>f)
      F_find_next_f=27000000;
    else if(40000000>f)
      F_find_next_f=40000000;
    else if(50000000>f)
      F_find_next_f=50000000;
    else if(54000000>f)
      F_find_next_f=54000000;
    else if(60000000>f)
      F_find_next_f=60000000;
    else if(65000000>f)
      F_find_next_f=65000000;
    else if(75000000>f)
      F_find_next_f=75000000;
    else if(80000000>f)
      F_find_next_f=80000000;  // overclock
    else if(100000000>f)
      F_find_next_f=100000000; // overclock
    else if(108000000>f)
      F_find_next_f=108000000; // overclock
    else if(120000000>f)
      F_find_next_f=120000000; // overclock
  endfunction
  
  localparam xminblank         = x/64; // initial estimate
  localparam yminblank         = y/64; // for minimal blank space
  localparam min_pixel_f       = f*(x+xminblank)*(y+yminblank);
  localparam pixel_f           = F_find_next_f(min_pixel_f);
  localparam yframe            = y+yminblank;
  localparam xframe            = pixel_f/(f*yframe);
  localparam xblank            = xframe-x;
  localparam yblank            = yframe-y;
  localparam hsync_front_porch = xblank/3;
  localparam hsync_pulse_width = xblank/3;
  localparam hsync_back_porch  = xblank-hsync_pulse_width-hsync_front_porch+xadjustf;
  localparam vsync_front_porch = yblank/3;
  localparam vsync_pulse_width = yblank/3;
  localparam vsync_back_porch  = yblank-vsync_pulse_width-vsync_front_porch+yadjustf;

  
  // wifi_gpio0=1 keeps board from rebooting
  // hold btn0 to let ESP32 take control over the board
  assign wifi_gpio0 = btn[0];

  // press BTN0 to exit this bitstream
  reg [19:0] R_delay_reload = 0;
  always @(posedge clk_25mhz)
    if(R_delay_reload[19]==0)
      R_delay_reload <= R_delay_reload+1;
  assign user_programn = btn[0] | ~R_delay_reload[19];

  // clock generator
  wire clk_locked;
  wire [3:0] clocks;
  wire clk_shift = clocks[0];
  wire clk_pixel = clocks[1];
  ecp5pll
  #(
      .in_hz(25000000),
    .out0_hz(pixel_f*5*(c_ddr?1:2)),
    .out1_hz(pixel_f)
  )
  ecp5pll_inst
  (
    .clk_i(clk_25mhz),
    .clk_o(clocks),
    .locked(clk_locked)
  );
  // VGA signal generator
  wire [7:0] vga_r, vga_g, vga_b;
  wire vga_hsync, vga_vsync, vga_blank;
  /*vga
  #(
    .c_resolution_x(x),
    .c_hsync_front_porch(hsync_front_porch),
    .c_hsync_pulse(hsync_pulse_width),
    .c_hsync_back_porch(hsync_back_porch),
    .c_resolution_y(y),
    .c_vsync_front_porch(vsync_front_porch),
    .c_vsync_pulse(vsync_pulse_width),
    .c_vsync_back_porch(vsync_back_porch),
    .c_bits_x(11),
    .c_bits_y(11)
  )
  vga_instance
  (
    .clk_pixel(clk_pixel),
    .clk_pixel_ena(1'b1),
    .test_picture(1'b1), // enable test picture generation
    .vga_r(vga_r),
    .vga_g(vga_g),
    .vga_b(vga_b),
    .vga_hsync(vga_hsync),
    .vga_vsync(vga_vsync),
    .vga_blank(vga_blank)
  );*/

  // LED blinky
  assign led[7:6] = 0;
  assign led[0] = vga_vsync;
  assign led[1] = vga_hsync;
  assign led[2] = vga_blank;

  // VGA to digital video converter
  wire [1:0] tmds_clock, tmds_red, tmds_green, tmds_blue;
  vga2dvid
  #(
    .c_ddr(c_ddr?1'b1:1'b0),
    .c_shift_clock_synchronizer(1'b0)
  )
  vga2dvid_instance
  (
    .clk_pixel(clk_pixel),
    .clk_shift(clk_shift),
    .in_red(vga_r),
    .in_green(vga_g),
    .in_blue(vga_b),
    .in_hsync(vga_hsync),
    .in_vsync(vga_vsync),
    .in_blank(vga_blank),
    .out_clock(tmds_clock),
    .out_red  (tmds_red  ),
    .out_green(tmds_green),
    .out_blue (tmds_blue )
  );

  generate
    if(c_ddr)
    begin
      // vendor specific DDR modules
      // convert SDR 2-bit input to DDR clocked 1-bit output (single-ended)
      // onboard GPDI
      ODDRX1F ddr0_clock (.D0(tmds_clock[0]), .D1(tmds_clock[1]), .Q(gpdi_dp[3]), .SCLK(clk_shift), .RST(0));
      ODDRX1F ddr0_red   (.D0(tmds_red  [0]), .D1(tmds_red  [1]), .Q(gpdi_dp[2]), .SCLK(clk_shift), .RST(0));
      ODDRX1F ddr0_green (.D0(tmds_green[0]), .D1(tmds_green[1]), .Q(gpdi_dp[1]), .SCLK(clk_shift), .RST(0));
      ODDRX1F ddr0_blue  (.D0(tmds_blue [0]), .D1(tmds_blue [1]), .Q(gpdi_dp[0]), .SCLK(clk_shift), .RST(0));
    end
    else
    begin
      assign gpdi_dp[3] = tmds_clock[0];
      assign gpdi_dp[2] = tmds_red  [0];
      assign gpdi_dp[1] = tmds_green[0];
      assign gpdi_dp[0] = tmds_blue [0];
    end
  endgenerate


// Instantiate SLURM16

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
wire flash_miso;
wire flash_sclk;
wire flash_csb;

reg [20:0] COUNT = 0;
wire RSTb = (COUNT < 10000) ? 1'b0 : 1'b1;

always @(posedge clk_pixel)
begin
	if (COUNT < 100000)
		COUNT <= COUNT + 1;	
end

slurm16 #(
.CLOCK_FREQ(25000000)
) cpu0 (
    clk_pixel,
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

// Assign to ULX3S pads
assign gp0 = uart_tx;

assign vga_r = {vid_r, 4'd0};
assign vga_g = {vid_g, 4'd0};
assign vga_b = {vid_b, 4'd0};
 
assign vga_vsync = !vid_vsync;
assign vga_hsync = !vid_hsync;
assign vga_blank = /*!vid_vsync || !vid_hsync;*/ vid_blank;

assign gp1 = i2s_mclk;
assign gp2 = i2s_lrclk;
assign gp3 = i2s_sclk;
assign gp4 = i2s_data;

/*LOCATE COMP "btn[1]" SITE "R1";  # FIRE1
LOCATE COMP "btn[2]" SITE "T1";  # FIRE2
LOCATE COMP "btn[3]" SITE "R18"; # UP
LOCATE COMP "btn[4]" SITE "V1";  # DOWN
LOCATE COMP "btn[5]" SITE "U1";  # LEFT
LOCATE COMP "btn[6]" SITE "H16"; # RIGHT*/

/*assign gpio_in[0] = UP_BUTTON;
assign gpio_in[1] = DOWN_BUTTON;
assign gpio_in[2] = LEFT_BUTTON;
assign gpio_in[3] = RIGHT_BUTTON;
assign gpio_in[4] = A_BUTTON;
assign gpio_in[5] = B_BUTTON;*/

assign gpio_in[0] = btn[3];
assign gpio_in[1] = btn[4];
assign gpio_in[2] = btn[5];
assign gpio_in[3] = btn[6];
assign gpio_in[4] = btn[1];
assign gpio_in[5] = btn[2];

// DEBUG : Instantiate UART
/*
wire [15:0] u_data_out;

reg [23:0] cnt;

always @(posedge clk_pixel) cnt <= cnt + 1;

wire wr = (cnt == 24'h000000);

uart 
#(.CLK_FREQ(25000000), .BAUD_RATE(115200), .BITS(16))
u0 (
	clk_pixel,	
	1'b1,
	4'd0,
	16'h0041,
	u_data_out,
	wr, 
	gp0  
);
*/

/*
  // external GPDI
  ODDRX1F ddr1_clock (.D0(tmds_clock[0]), .D1(tmds_clock[1]), .Q(gp[12]), .SCLK(clk_shift), .RST(0));
  ODDRX1F ddr1_red   (.D0(tmds_red  [0]), .D1(tmds_red  [1]), .Q(gp[11]), .SCLK(clk_shift), .RST(0));
  ODDRX1F ddr1_green (.D0(tmds_green[0]), .D1(tmds_green[1]), .Q(gp[10]), .SCLK(clk_shift), .RST(0));
  ODDRX1F ddr1_blue  (.D0(tmds_blue [0]), .D1(tmds_blue [1]), .Q(gp[ 9]), .SCLK(clk_shift), .RST(0));
*/

endmodule
