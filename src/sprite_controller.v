/*
 *	Sprite controller: capable of N sprites, can display the top most 2 (in case of overlap)
 *
 *	Memory bus is AXI-like
 *
 *
 */

module sprite_controller
(
	input  CLK,
	input  RSTb,

	input  [9:0] ADDRESS,
	input  [15:0] DATA_IN,
	input  WR,

	/* single cycle tick when vertical count is zero */
	input V_tick,
	/* single cycle tick horizontal count is zero */
	input H_tick,

	/* display uses this channel to read scanline block RAM */
	input [9:0]   display_x,
	output [7:0] color_index,

	/* memory channel to memory arbiter */
	output [15:0] memory_address,
	input  [15:0] memory_data,
	output rvalid, // memory address valid
	input  rready  // memory data valid

);

localparam LOG2_SPRITES = 2;
localparam N_SPRITES = 2**LOG2_SPRITES;

reg [9:0] display_x_r;
reg [9:0] display_x_next;

reg [9:0] display_y_r;
reg [9:0] display_y_next;

// Instantiate sprite channels

genvar j;

reg WR_sp [N_SPRITES - 1 : 0];

wire 		isActive_sp[N_SPRITES - 1 : 0];
wire [17:0] sprite_address [N_SPRITES - 1 : 0];
wire [3:0] 	pal_hi [N_SPRITES - 1 : 0]; 

generate
	for (j = 0; j < N_SPRITES; j = j + 1)
	begin: Gen_sprites
	memory_sprite sp_inst
	(
		CLK,
		RSTb,

		ADDRESS[3:0],
		DATA_IN,
		WR_sp[j],

		display_x_r,
		display_y_r,
			
		isActive_sp[j],
		sprite_address[j],	
		pal_hi[j]
	);
	end
endgenerate

// logic to select top two sprites

integer k, l;


reg sprite_address_valid_1_r;
reg sprite_address_valid_1_r_next;

assign color_index = sprite_address_valid_1_r == 1'b1 ? 8'h00 : 8'hff;

reg [17:0] sprite_address_1_r;
reg [17:0] sprite_address_1_r_next;

reg sprite_address_valid_2_r;
reg sprite_address_valid_2_r_next;

reg [17:0] sprite_address_2_r;
reg [17:0] sprite_address_2_r_next;

always @(*)
begin
	sprite_address_valid_1_r_next = 1'b0;
	sprite_address_valid_2_r_next = 1'b0;

	sprite_address_1_r_next = 18'd0;
	sprite_address_2_r_next = 18'd0;

	for (k = N_SPRITES - 1; k >= 0; k = k - 1)
	begin
		if (isActive_sp[k] == 1'b1) begin
			sprite_address_valid_1_r_next = 1'b1;
			sprite_address_1_r_next = sprite_address[k];

			for (l = N_SPRITES - 1; l > k; l = l -1) begin
				if (isActive_sp[l] == 1'b1) begin
					sprite_address_valid_2_r_next = 1'b1;
					sprite_address_2_r_next = sprite_address[l];
				end
			end
		end
	end
end

// Horizontal count

always @(*)
begin
	if (H_tick == 1'b1)
		display_x_next = 10'd0;
	else
		display_x_next = display_x_r + 1;		
end

// Vertical count

always @(*)
begin
	if (V_tick == 1'b1)
		display_y_next = 10'd0;
	else if (H_tick == 1'b1)
		display_y_next = display_y_r + 1;		
	else
		display_y_next = display_y_r;
end

// Memory interface 

always @(*)
begin
	for (k = 0; k < N_SPRITES; k = k + 1)
		WR_sp[k] = 1'b0;

	casex (ADDRESS[9:4])
		// Put all other rigister spaces in here

		default: 
			WR_sp[ADDRESS[LOG2_SPRITES - 1 + 4:4]] = 1'b1;
	endcase
end



// Sequential logic

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		display_x_r = 10'd0;
		display_y_r = 10'd0;
		sprite_address_valid_1_r = 1'b0;
		sprite_address_valid_2_r = 1'b0;
		sprite_address_1_r = 18'd0;
		sprite_address_2_r = 18'd0;
	end else begin
		display_x_r = display_x_next;
		display_y_r = display_y_next;
		sprite_address_valid_1_r = sprite_address_valid_1_r_next;
		sprite_address_valid_2_r = sprite_address_valid_2_r_next;
		sprite_address_1_r = sprite_address_1_r_next;
		sprite_address_2_r = sprite_address_2_r_next;
	end
end

endmodule
