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

reg [9:0] sprite_x_end;
reg [9:0] sprite_x_end_next;

reg [9:0] sprite_y_end;
reg [9:0] sprite_y_end_next;

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
 * Bit 3: Stride
 * 			0 = 128 pixels
 * 			1 = 256 pixels
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
		sprite_x_end <= 10'd0;
		sprite_y_end <= 10'd0;
		flags_r   <= 7'd0;
		sprite_base_address_r <= 16'd0;
		sprite_output_address_r <= 18'd0;
		isActive_r <= 1'b0;
	end else begin
		sprite_x <= sprite_x_next;
		sprite_y <= sprite_y_next;
		sprite_x_end <= sprite_x_end_next;
		sprite_y_end <= sprite_y_end_next;
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
	sprite_x_end_next = sprite_x_end;
	sprite_y_end_next = sprite_y_end;
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
			4'd5:  /* sprite x end */
				sprite_x_end_next = DATA_IN[9:0];
			4'd6:  /* sprite y end */
				sprite_y_end_next = DATA_IN[9:0];
			default: ;
		endcase
	end

end

always @(*)
begin
	isActive_r_next = 1'b0;

	if (flags_r[0] == 1'b1) begin
			if (display_x >= sprite_x && display_x < sprite_x_end && display_y >= sprite_y && display_y < sprite_y_end)  
				isActive_r_next = 1'b1;
	end
end

reg [5:0] sprite_u;
reg [5:0] sprite_v;

always @(*)
begin
	sprite_u = (display_x - sprite_x);
	sprite_v = (display_y - sprite_y);
end

always @(*)
begin
	sprite_output_address_next = 18'd0;

	case (flags_r[3])
		2'b00: /* 128 pixels */
			sprite_output_address_next = {sprite_base_address_r, 2'b00} + {sprite_v, 7'b0000000} + sprite_u;			
		2'b01: /* 256 pixels */
			sprite_output_address_next = {sprite_base_address_r, 2'b00} + {sprite_v, 8'b00000000} + sprite_u;			
	endcase
end

endmodule
