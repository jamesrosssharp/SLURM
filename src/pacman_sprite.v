module pacman_sprite
(
	input  CLK,
	input  RSTb,

	input  [3:0] ADDRESS,
	input  [15:0] DATA_IN,
	input  WR,

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

reg [1:0] spriteFrame_r = 0;
reg [1:0] spriteFrame_next;

reg [1:0] flip_r = 2'b00;
reg [1:0] flip_r_next;

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

// Sprite rom address
always @(*)
begin
	case (flip_r)
		2'b00: begin	// Normal
			spriteRomAddress[3:0] = (display_y - sprite_y);
			// Generate data 1 clock early
			spriteRomAddress[7:4] = (display_x - sprite_x + 1);
			spriteRomAddress[9:8] = spriteFrame_r[1:0];
		end
		2'b10: begin // Rotate 90 Deg
			spriteRomAddress[7:4] = (display_y - sprite_y);
			// Generate data 1 clock early
			spriteRomAddress[3:0] = (display_x - sprite_x + 1);
			spriteRomAddress[9:8] = spriteFrame_r[1:0];
		end
		2'b01: begin // Rotate 180 Deg
			spriteRomAddress[3:0] = 15 - (display_y - sprite_y);
			// Generate data 1 clock early
			spriteRomAddress[7:4] = 15 - ((display_x + 1) - sprite_x);
			spriteRomAddress[9:8] = spriteFrame_r[1:0];
		end
		2'b11: begin // Rotate 270 Deg
			spriteRomAddress[7:4] = 15 - (display_y - sprite_y);
			// Generate data 1 clock early
			spriteRomAddress[3:0] = 15 - (display_x - sprite_x + 1);
			spriteRomAddress[9:8] = spriteFrame_r[1:0];
		end
	endcase
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
	flip_r   <= flip_r_next;
end

always @(*)
begin
	sprite_x_next = sprite_x;
	sprite_y_next = sprite_y;
	spriteFrame_next = spriteFrame_r;
	flip_r_next = flip_r;

	if (WR == 1'b1) begin
		case (ADDRESS)
			4'd0:
				sprite_x_next = DATA_IN[9:0];
			4'd1:
				sprite_y_next = DATA_IN[9:0];
			4'd2:
				spriteFrame_next = DATA_IN[1:0];
			4'd3:
				flip_r_next = DATA_IN[1:0];
			default: ;
		endcase
	end
end


endmodule
