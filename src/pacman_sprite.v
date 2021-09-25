module pacman_sprite
(
	input  CLK,
	input  RSTb,

	input frameTick,

	input [9:0] display_x,
	input [9:0] display_y,
		
	output [11:0] color,

	/* if display_x and display_y fall within the sprite and sprite color is non-zero, isActive will be high */
	output isActive
);

reg [9:0] sprite_x = 320;
reg [9:0] sprite_y = 240;

reg [9:0] sprite_x_next;
reg [9:0] sprite_y_next;

reg [4:0] spriteFrame_r = 0;
reg [4:0] spriteFrame_next;

localparam SPRITE_WIDTH = 16;
localparam SPRITE_HEIGHT = 16;

reg isActive_r;

assign isActive = isActive_r;

reg [9:0] spriteRomAddress;

wire [16:0] spriteColor; 

assign color = spriteColor[11:0];

pacman_sprite_rom rom0 (
	CLK,
	spriteRomAddress,
	spriteColor
);

// Sprite frame
always @(posedge CLK)
begin
	spriteFrame_r <= spriteFrame_next;
end

always @(*)
begin
	spriteFrame_next = spriteFrame_r;
	if (frameTick == 1'b1) begin
		spriteFrame_next = spriteFrame_r + 1;
		if (spriteFrame_r == 5'd23)
			spriteFrame_next = 5'b0000;
	end
end

// Sprite rom address
always @(*)
begin
	spriteRomAddress[3:0] = (display_y - sprite_y);
	// Generate data 1 clock early
	spriteRomAddress[7:4] = (display_x - sprite_x + 1);
	spriteRomAddress[9:8] = spriteFrame_r[4:3];
end

// Is active
always @(*)
begin
	if (display_x >= sprite_x && display_x < (sprite_x + SPRITE_WIDTH) && display_y >= sprite_y && display_y < (sprite_y + SPRITE_HEIGHT) && spriteColor != 16'h0000)  
		isActive_r = 1'b1;
	else
		isActive_r = 1'b0;		
end

// Sprite x, y
always @(posedge CLK)
begin
	sprite_x <= sprite_x_next;
	sprite_y <= sprite_y_next;
end

always @(*)
begin
	sprite_x_next = sprite_x;
	sprite_y_next = sprite_y;
	if (frameTick == 1'b1) begin
		sprite_x_next = sprite_x + 2;
		if (sprite_x >= 10'd784) begin
			sprite_y_next = sprite_y + 16;
			sprite_x_next = 10'd0;
			if (sprite_y >= 10'd509)
				sprite_y_next = 10'd0;
		end
	end
end

endmodule
