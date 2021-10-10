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
	output [17:0] sprite_address,

	/* the high nibble of the colour for this sprite */
	output [3:0] pal_hi
);

reg [9:0] sprite_x;
reg [9:0] sprite_x_next;

reg [9:0] sprite_y;
reg [9:0] sprite_y_next;

reg [9:0] sprite_width;
reg [9:0] sprite_height;

reg [15:0] sprite_base_address_r;
reg [15:0] sprite_base_address_next;

reg [17:0] sprite_output_address_r;
reg [17:0] sprite_output_address_next;

assign sprite_address = sprite_output_address_r;

reg isActive_r;
reg isActive_r_next;

assign isActive = isActive_r;


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

reg [3:0] pal_hi_r;
reg [3:0] pal_hi_r_next;

assign pal_hi = pal_hi_r;

// Sprite x, y
always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		sprite_x <= 10'd0;
		sprite_y <= 10'd0;
		flags_r   <= 7'd0;
		sprite_base_address_r <= 16'd0;
		sprite_output_address_r <= 18'd0;
		isActive_r <= 1'b0;
	end else begin
		sprite_x <= sprite_x_next;
		sprite_y <= sprite_y_next;
		flags_r   <= flags_r_next;
		sprite_base_address_r <= sprite_base_address_next;
		sprite_output_address_r <= sprite_output_address_next;
		isActive_r <= isActive_r_next;
	end
end

always @(*)
begin
	sprite_x_next = sprite_x;
	sprite_y_next = sprite_y;
	sprite_base_address_next = sprite_base_address_r;
	flags_r_next = flags_r;
	pal_hi_r_next = pal_hi_r;

	if (WR == 1'b1) begin
		case (ADDRESS)
			4'd0:	/* sprite X */
				sprite_x_next = DATA_IN[9:0];
			4'd1:	/* sprite Y */
				sprite_y_next = DATA_IN[9:0];
			4'd2:	/* sprite address */
			 	sprite_base_address_next = DATA_IN[15:0];
			4'd3:	/* flags */
				flags_r_next = DATA_IN[6:0];
			4'd4:   /* palette high */
				pal_hi_r_next = DATA_IN[3:0];
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
	isActive_r_next = 1'b0;

	if (flags_r[0] == 1'b1) begin
		case (flags_r[2:1])
			2'b00, 2'b10: begin	// Normal, 180 deg
				if (display_x >= sprite_x && display_x < (sprite_x + sprite_width) && display_y >= sprite_y && display_y < (sprite_y + sprite_height))  
					isActive_r_next = 1'b1;
				else
					isActive_r_next = 1'b0;		
			end
			2'b01, 2'b11: begin // Rotate 90 Deg, 270 deg
				if (display_x >= sprite_x && display_x < (sprite_x + sprite_height) && display_y >= sprite_y && display_y < (sprite_y + sprite_width))  
					isActive_r_next = 1'b1;
				else
					isActive_r_next = 1'b0;		
			end
		endcase
	end
end

reg [5:0] sprite_u;
reg [5:0] sprite_v;

always @(*)
begin
	sprite_u = 0;
	sprite_v = 0;
	case (flags_r[2:1])
		2'b00: begin	// Normal
			sprite_v = (display_y - sprite_y);
			sprite_u = (display_x - sprite_x);
		end
		2'b01: begin // Rotate 90 Deg
			sprite_u = (display_y - sprite_y);
			sprite_v = (display_x - sprite_x);
		end
		2'b10: begin // Rotate 180 Deg
			sprite_v = sprite_height - 1 - (display_y - sprite_y);
			sprite_u = sprite_width - 1 - ((display_x) - sprite_x);
		end
		2'b11: begin // Rotate 270 Deg
			sprite_u = sprite_height - 1 - (display_y - sprite_y);
			sprite_v = sprite_width - 1 - (display_x - sprite_x);
		end
	endcase
end

always @(*)
begin
	sprite_output_address_next = 18'd0;

	case (flags_r[4:3])
		2'b00: /* 8 pixels */
			sprite_output_address_next = {sprite_base_address_r, 2'b00} + {sprite_v, 3'b000} + sprite_u;			
		2'b01: /* 16 pixels */
			sprite_output_address_next = {sprite_base_address_r, 2'b00} + {sprite_v, 4'b0000} + sprite_u;			
		2'b10: /* 32 pixels */
			sprite_output_address_next = {sprite_base_address_r, 2'b00} + {sprite_v, 5'b00000} + sprite_u;			
		2'b11: /* 64 pixels */
			sprite_output_address_next = {sprite_base_address_r, 2'b00} + {sprite_v, 6'b000000} + sprite_u;			
	endcase
end

endmodule
