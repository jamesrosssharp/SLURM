/*
 *	Sprite controller: based on Dan Rodrigues' icestation 
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


//
//	X ram: 
//
//	16 bits.
//
//	Bit 0 - 9: X coord
//	Bit 10: sprite en
//				0 = disabled
//				1 = enabled
//	Bit 11 - 14: pal high
//  Bit 15: stride
//  		0 = 128 nibbles
//  		1 = 256 nibbles

wire [7:0] xram_rd_addr;

wire [7:0] xram_wr_addr = ADDRESS[7:0];
wire [15:0] xram_in 	= DATA_IN;
wire [15:0] xram_out;

reg xram_WR;

bram
#(.BITS(16), .ADDRESS_BITS(8))
xram
(
	CLK,
	xram_rd_addr,
	xram_out,
	
	xram_wr_addr,
	xram_in,
	xram_WR  
);

//
//	Y ram: 
//
//	16 bits.
//
//	Bit 0 - 8: Y coord
//	Bit 9 - 15: width 

wire [7:0] yram_rd_addr;

wire [7:0]  yram_wr_addr = ADDRESS[7:0];
wire [15:0] yram_in = DATA_IN;
wire [15:0] yram_out;

reg yram_WR;

bram
#(.BITS(16), .ADDRESS_BITS(8))
yram
(
	CLK,
	yram_rd_addr,
	yram_out,
	
	yram_wr_addr,
	yram_in,
	yram_WR  
);

//
//	H ram: 
//
//	16 bits.
//
//	Bit 0 - 8: Y coord end
//	Bit 9 - 15: reserved

wire [7:0]  hram_rd_addr;

wire [7:0]  hram_wr_addr = ADDRESS[7:0];
wire [15:0] hram_in = DATA_IN;
wire [15:0] hram_out;

reg  hram_WR;

bram
#(.BITS(16), .ADDRESS_BITS(8))
hram
(
	CLK,
	hram_rd_addr,
	hram_out,
	
	hram_wr_addr,
	hram_in,
	hram_WR  
);

// Instantiate scanline double buffers

genvar j;

reg [9:0]  scanline_rd_addr[1:0];
reg [9:0]  scanline_wr_addr[1:0];
wire [7:0] scanline_rd_data[1:0];
reg [7:0]  scanline_wr_data[1:0];
reg scanline_wr[1:0];
reg active_buffer;
wire display_buffer = !active_buffer;
reg active_buffer_next;

assign color_index = scanline_rd_data[display_buffer];

generate 
for (j = 0; j < 2; j = j + 1)
begin:	scanline_buffers bram #(.BITS(8), .ADDRESS_BITS(10)) br_inst
(
	CLK,
	scanline_rd_addr[j],
	scanline_rd_data[j],
	scanline_wr_addr[j],
	scanline_wr_data[j],
	scanline_wr[j]
);
end
endgenerate


// Memory write

always @(*)
begin
	xram_WR = 1'b0;
	yram_WR = 1'b0;
	hram_WR = 1'b0;

	case (ADDRESS[9:8])
		2'b00:	/* X ram */
			xram_WR = WR;
		2'b01: /* Y ram */
			yram_WR = WR;
		2'b10:  /* H ram */
			hram_WR = WR;
		default: ;
	endcase
end

// Y count

reg [8:0] y_count = 9'd0;

always @(posedge CLK)
begin
	if (V_tick == 1'b1)
		y_count <= 9'd0;
	else if (H_tick == 1'b1)
		y_count <= y_count + 1;
end


// Sprite render state machine

reg [3:0] r_state, r_state_next;

localparam r_idle 			  = 4'd0;
localparam r_load_sprite_regs = 4'd1;
localparam r_wait_mem_0		  = 4'd2;
localparam r_blit_0			  = 4'd3;
localparam r_blit_1			  = 4'd4;
localparam r_blit_2			  = 4'd5;
localparam r_blit_3			  = 4'd6;
localparam r_finish			  = 4'd7;

reg [7:0] cur_sprite_r, cur_sprite_r_next;

assign xram_rd_addr = cur_sprite_r;
assign yram_rd_addr = cur_sprite_r;
assign hram_rd_addr = cur_sprite_r; 

reg [9:0] cur_sprite_x; 
reg [9:0] cur_sprite_x_next;
reg [3:0] cur_sprite_palette;
reg [3:0] cur_sprite_palette_next;

reg [6:0] cur_sprite_x_count; 
reg [6:0] cur_sprite_x_count_next; 


always @(*)
begin
	r_state_next 		= r_state;
	active_buffer_next  = active_buffer;
	cur_sprite_r_next   = cur_sprite_r;

	scanline_wr_addr[0] = 10'd0;
	scanline_wr_addr[1] = 10'd0;

	scanline_wr[0] 		= 1'b0;
	scanline_wr[1] 		= 1'b0;

	scanline_wr_data[0] = 8'h00;	
	scanline_wr_data[1] = 8'h00;	

	scanline_wr_addr[active_buffer] = cur_sprite_x;
	scanline_wr[active_buffer] 		= 1'b0;
	scanline_wr_data[active_buffer] = 8'h00;	

	// Clear display buffer as it is read		
	scanline_wr[display_buffer] 	= 1'b1;
	scanline_wr_addr[display_buffer] = display_x == 10'd0 ? 10'd799 : display_x - 1;
	scanline_wr_data[display_buffer] = 8'h0f;	

	cur_sprite_x_next = cur_sprite_x; 
	cur_sprite_x_count_next = cur_sprite_x_count;
	
	case (r_state)
		r_idle: ;
		r_load_sprite_regs: begin
			cur_sprite_r_next = cur_sprite_r + 1;
			cur_sprite_x_next = xram_out[9:0]; 
			cur_sprite_x_count_next = yram_out[15:9];
	
			if (xram_out[10] == 1'b1 && y_count >= yram_out[8:0] && y_count <= hram_out[8:0]) begin
				// Sprite enabled
				r_state_next = r_wait_mem_0;
			end
		end
		r_wait_mem_0:
			r_state_next = r_blit_0;
		r_blit_0: begin
			cur_sprite_x_next = cur_sprite_x + 1;
			cur_sprite_x_count_next = cur_sprite_x_count - 1;

			scanline_wr[active_buffer] = 1'b1;
			scanline_wr_data[active_buffer] = 8'hff;			

			if (cur_sprite_x_count == 7'd0)
				r_state_next = r_finish;
			else
				r_state_next = r_blit_1;
		end	
		r_blit_1: begin
			cur_sprite_x_next = cur_sprite_x + 1;
			cur_sprite_x_count_next = cur_sprite_x_count - 1;

			scanline_wr[active_buffer] = 1'b1;
			scanline_wr_data[active_buffer] = 8'hff;			

			if (cur_sprite_x_count == 7'd0)
				r_state_next = r_finish;
			else
				r_state_next = r_blit_2;
		end
		r_blit_2: begin

			cur_sprite_x_next = cur_sprite_x + 1;
			cur_sprite_x_count_next = cur_sprite_x_count - 1;

			scanline_wr[active_buffer] = 1'b1;
			scanline_wr_data[active_buffer] = 8'hff;			

			if (cur_sprite_x_count == 7'd0)
				r_state_next = r_finish;
			else
				r_state_next = r_blit_3;
	
		end
		r_blit_3: begin
		
			cur_sprite_x_next = cur_sprite_x + 1;
			cur_sprite_x_count_next = cur_sprite_x_count - 1;

			scanline_wr[active_buffer] = 1'b1;
			scanline_wr_data[active_buffer] = 8'hff;			

			if (cur_sprite_x_count == 7'd0)
				r_state_next = r_finish;
			else
				r_state_next = r_wait_mem_0;
	
		end
		r_finish: begin
			if (cur_sprite_r == 8'hff) 
				r_state_next = r_idle;
			else
				r_state_next = r_load_sprite_regs;
		end
	endcase

	// If we get a H tick, start next scanline
	if (H_tick == 1'b1)
	begin
		active_buffer_next = display_buffer;
		r_state_next = r_load_sprite_regs;
		cur_sprite_r_next = 8'd0;
	end

end


// Read out scanline buffer

always @(*)
begin
	scanline_rd_addr[0]  = 10'd0;
 	scanline_rd_addr[1]  = 10'd0;
  	
	scanline_rd_addr[active_buffer]  = 10'd0;
  	scanline_rd_addr[display_buffer] = display_x;
end


// Sequential logic

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		active_buffer <= 1'b0;
		r_state 	  <= r_idle;
		cur_sprite_r  <= 8'd0;
		cur_sprite_x  <= 10'd0; 
		cur_sprite_palette <= 4'd0;
		cur_sprite_x_count <= 7'd0; 
	end else begin
		active_buffer <= active_buffer_next;
		r_state 	  <= r_state_next;
		cur_sprite_r  <= cur_sprite_r_next;
		cur_sprite_x  <= cur_sprite_x_next; 
		cur_sprite_palette <= cur_sprite_palette_next;
		cur_sprite_x_count <= cur_sprite_x_count_next; 
	end
end

endmodule
