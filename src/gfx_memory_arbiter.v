module gfx_memory_arbiter
(
	/* sprite controller */
	input  [15:0] 	sprite_memory_address,
	output [15:0] 	sprite_memory_data,
	input 			sprite_rvalid, // memory address valid
	output  		sprite_rready,  // memory data valid

	/* background controller 0 */
	input  [15:0] 	bg0_memory_address,
	output [15:0] 	bg0_memory_data,
	input 			bg0_rvalid, // memory address valid
	output  		bg0_rready,  // memory data valid

	/* background controller 1 */
	input  [15:0] 	bg1_memory_address,
	output [15:0] 	bg1_memory_data,
	input 			bg1_rvalid, // memory address valid
	output  		bg1_rready,  // memory data valid

	/* overlay controller */
	input  [15:0] 	ov_memory_address,
	output [15:0] 	ov_memory_data,
	input 			ov_rvalid, // memory address valid
	output  		ov_rready,  // memory data valid

	output [13 : 0] B1_ADDR,
	input  [15 : 0] B1_DOUT,
	output B1_VALID,
	input  B1_READY,

	output [13 : 0] B2_ADDR,
	input  [15 : 0] B2_DOUT,
	output B2_VALID,
	input  B2_READY,

	output [13 : 0] B3_ADDR,
	input  [15 : 0] B3_DOUT,
	output B3_VALID,
	input  B3_READY,

	output [13 : 0] B4_ADDR,
	input  [15 : 0] B4_DOUT,
	output B4_VALID,
	input  B4_READY
);

reg [15:0] 	sprite_memory_data_r;
reg 		sprite_rready_r;

reg [15:0] 	bg0_memory_data_r;
reg 		bg0_rready_r;

reg [15:0] 	bg1_memory_data_r;
reg 		bg1_rready_r;

assign sprite_rready = sprite_rready_r; 
assign sprite_memory_data = sprite_memory_data_r;

assign bg0_rready = bg0_rready_r; 
assign bg0_memory_data = bg0_memory_data_r;

assign bg1_rready = bg1_rready_r; 
assign bg1_memory_data = bg1_memory_data_r;

reg [13:0]		b1_addr_r;
reg			b1_valid_r;

assign B1_ADDR 		 = b1_addr_r;
assign B1_VALID		 = b1_valid_r;

reg [13:0]		b2_addr_r;
reg			b2_valid_r;

assign B2_ADDR 		 = b2_addr_r;
assign B2_VALID		 = b2_valid_r;

reg [13:0]		b3_addr_r;
reg			b3_valid_r;

assign B3_ADDR 		 = b3_addr_r;
assign B3_VALID		 = b3_valid_r;

reg [13:0]		b4_addr_r;
reg			b4_valid_r;

assign B4_ADDR 		 = b4_addr_r;
assign B4_VALID		 = b4_valid_r;

always @(*) begin

	b1_addr_r 		= 16'h0000;
	b1_valid_r 		= 1'b0;
	sprite_rready_r = 1'b0;
	sprite_memory_data_r = 16'h0000;
	b2_addr_r 		= 16'h0000;
	b2_valid_r 		= 1'b0;
	b3_addr_r 		= 16'h0000;
	b3_valid_r 		= 1'b0;
	b4_addr_r 		= 16'h0000;
	b4_valid_r 		= 1'b0;
	bg0_memory_data_r = 16'h0000;
	bg0_rready_r = 1'b0;
	bg1_memory_data_r = 16'h0000;
	bg1_rready_r = 1'b0;


	
	if (sprite_rvalid == 1'b1 && sprite_memory_address[15:14] == 2'b00) begin
		b1_addr_r = sprite_memory_address;				
		b1_valid_r = sprite_rvalid;
		sprite_rready_r = B1_READY;
		sprite_memory_data_r =  B1_DOUT;
	end else
	if (bg0_rvalid == 1'b1 && bg0_memory_address[15:14] == 2'b00) begin
		b1_addr_r = bg0_memory_address;				
		b1_valid_r = bg0_rvalid;
		bg0_rready_r = B1_READY;
		bg0_memory_data_r =  B1_DOUT;
	end else
	if (bg1_rvalid == 1'b1 && bg1_memory_address[15:14] == 2'b00) begin
		b1_addr_r = bg1_memory_address;				
		b1_valid_r = bg1_rvalid;
		bg1_rready_r = B1_READY;
		bg1_memory_data_r =  B1_DOUT;
	end 

	if (sprite_rvalid == 1'b1 && sprite_memory_address[15:14] == 2'b01) begin
		b2_addr_r = sprite_memory_address;				
		b2_valid_r = sprite_rvalid;
		sprite_rready_r = B2_READY;
		sprite_memory_data_r = B2_DOUT;
	end else
	if (bg0_rvalid == 1'b1 && bg0_memory_address[15:14] == 2'b01) begin
		b2_addr_r = bg0_memory_address;				
		b2_valid_r = bg0_rvalid;
		bg0_rready_r = B2_READY;
		bg0_memory_data_r = B2_DOUT;
	end
	if (bg1_rvalid == 1'b1 && bg1_memory_address[15:14] == 2'b01) begin
		b2_addr_r = bg1_memory_address;				
		b2_valid_r = b10_rvalid;
		bg1_rready_r = B2_READY;
		bg1_memory_data_r = B2_DOUT;
	end
		
	if (sprite_rvalid == 1'b1 && sprite_memory_address[15:14] == 2'b10) begin
		b3_addr_r = sprite_memory_address;				
		b3_valid_r = sprite_rvalid;
		sprite_rready_r = B3_READY;
		sprite_memory_data_r = B3_DOUT;
	end else
 	if (bg0_rvalid == 1'b1 && bg0_memory_address[15:14] == 2'b10) begin
		b3_addr_r = bg0_memory_address;				
		b3_valid_r = bg0_rvalid;
		bg0_rready_r = B3_READY;
		bg0_memory_data_r = B3_DOUT;
	end else
 	if (bg1_rvalid == 1'b1 && bg1_memory_address[15:14] == 2'b10) begin
		b3_addr_r = bg1_memory_address;				
		b3_valid_r = bg1_rvalid;
		bg1_rready_r = B3_READY;
		bg1_memory_data_r = B3_DOUT;
	end
 	
	if (sprite_rvalid == 1'b1 && sprite_memory_address[15:14] == 2'b11) begin
		b4_addr_r = sprite_memory_address;				
		b4_valid_r = sprite_rvalid;
		sprite_rready_r = B4_READY;
		sprite_memory_data_r = B4_DOUT;
	end else
 	if (bg0_rvalid == 1'b1 && bg0_memory_address[15:14] == 2'b11) begin
		b4_addr_r = bg0_memory_address;				
		b4_valid_r = bg0_rvalid;
		bg0_rready_r = B4_READY;
		bg0_memory_data_r = B4_DOUT;
	end else
 	if (bg1_rvalid == 1'b1 && bg1_memory_address[15:14] == 2'b11) begin
		b4_addr_r = bg1_memory_address;				
		b4_valid_r = bg1_rvalid;
		bg1_rready_r = B4_READY;
		bg1_memory_data_r = B4_DOUT;
	end
 
end

endmodule
