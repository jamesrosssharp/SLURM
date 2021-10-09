/*
 *	Memory sprite
 *
 *  Registers are write only
 *
 *	4 bits per pixel chunky, with custom palette high nibble configuration register (15 colors at one time, from a choice of 16 regions of the palette), color 0 means transparent pixel.
 *
 */

module memory_sprite
(
	input  CLK,
	input  RSTb,

	input  [3:0] ADDRESS,
	input  [15:0] DATA_IN,
	input  WR,

	input [9:0] display_x,
	input [9:0] display_y,
		
	/* if display_x and display_y fall within the sprite and sprite color is non-zero, isActive will be high */
	output isActive,

	/* the address of the current sprite's pixel in memory (if active) - nibble address */
	output [17:0] sprite_address
);

reg [9:0] sprite_x;
reg [9:0] sprite_x_next;

reg [9:0] sprite_y;
reg [9:0] sprite_y_next;

reg [9:0] sprite_width;
reg [9:0] sprite_height;

reg [15:0] sprite_address_r = 0;
reg [15:0] sprite_address_next;

/* flags:
 *
 * Bit 0 : Active
 * 		   0 = disabled
 * 		   1 = active
 *
 * Bits 1-2: Rotation
 * 			 0 = normal
 * 			 1 = 90 Deg rotation
 * 			 2 = 180 Deg rotation
 * 			 3 = 270 Deg rotation
 *
 * Bits 3 - 4: Width
 * 			0 = 8 pixels
 * 			1 = 16 pixels
 * 			2 = 32 pixels
 * 			3 = 64 pixels
 * 	Bits 4 - 6: Height
 * 			0 = 8 pixels
 * 			1 = 16 pixels
 * 			2 = 32 pixels
 * 			3 = 64 pixels
 *
 *
 */
reg [6:0] flags_r = 7'b0000000;
reg [6:0] flags_r_next;

reg isActive_r;
assign isActive = isActive_r;

// Sprite x, y
always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		sprite_x <= 10'd0;
		sprite_y <= 10'd0;
		flags_r   <= 7'd0;
		sprite_address_r <= 16'd0;
	end else begin
		sprite_x <= sprite_x_next;
		sprite_y <= sprite_y_next;
		flags_r   <= flags_r_next;
		sprite_address_r <= sprite_address_next;
	end
end

always @(*)
begin
	sprite_x_next = sprite_x;
	sprite_y_next = sprite_y;
	sprite_address_next = sprite_address_r;
	flags_r_next = flags_r;

	if (WR == 1'b1) begin
		case (ADDRESS)
			4'd0:	/* sprite X */
				sprite_x_next = DATA_IN[9:0];
			4'd1:	/* sprite Y */
				sprite_y_next = DATA_IN[9:0];
			4'd2:	/* sprite address */
			 	sprite_address_next = DATA_IN[15:0];
			4'd3:	/* flags */
				flags_r_next = DATA_IN[6:0];
			default: ;
		endcase
	end

end

always @(*)
begin
	case (flags_r[4:3])
		2'b00: /* 8 pixels */
			sprite_width = 8;
		2'b01: /* 16 pixels */
			sprite_width = 16;
		2'b10: /* 32 pixels */
			sprite_width = 32;
		2'b11: /* 64 pixels */
			sprite_width = 64;
	endcase

	case (flags_r[6:5])
		 2'b00: /* 8 pixels */
			 sprite_height = 8;
		 2'b01: /* 16 pixels */
			 sprite_height = 16;
		 2'b10: /* 32 pixels */
			 sprite_height = 32;
		 2'b11: /* 64 pixels */
			 sprite_height = 64;
	 endcase
end

always @(*)
begin
	if (display_x >= sprite_x && display_x < (sprite_x + sprite_width) && display_y >= sprite_y && display_y < (sprite_y + sprite_height))  
		isActive_r = 1'b1;
	else
		isActive_r = 1'b0;		
end



endmodule
