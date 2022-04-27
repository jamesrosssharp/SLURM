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
	input [9:0]   display_y,
	input         re,	// render enable
	output [7:0] color_index,

	/* memory channel to memory arbiter */
	output [15:0] memory_address,
	input  [15:0] memory_data,
	output rvalid, // memory address valid
	input  rready,  // memory data valid

	input [7:0] collision_list_address,
	output [15:0] collision_list_data
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
//	Bit 0 - 9: Y coord
//	Bit 10 - 15: width 

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
//	Bit 0 - 9: Y coord end
//	Bit 10 - 15: reserved

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

//
//	A ram: 
//
//	16 bits.
//
//	Bit 0 - 15: sprite sheet data address

wire [7:0]  aram_rd_addr;

wire [7:0]  aram_wr_addr = ADDRESS[7:0];
wire [15:0] aram_in 	 = DATA_IN;
wire [15:0] aram_out;

reg  aram_WR;

bram
#(.BITS(16), .ADDRESS_BITS(8))
aram
(
	CLK,
	aram_rd_addr,
	aram_out,
	
	aram_wr_addr,
	aram_in,
	aram_WR  
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

// Instantiate sprite collision double buffers

reg [9:0]  collision_rd_addr[1:0];
reg [9:0]  collision_wr_addr[1:0];
wire [3:0] collision_rd_data[1:0];
reg [3:0]  collision_wr_data[1:0];

reg collision_wr[1:0];
reg active_cbuffer;
wire display_cbuffer = !active_cbuffer;
reg active_cbuffer_next;

wire [3:0] collision_wr_data_act = collision_wr_data[active_cbuffer];

//assign color_index = collision_rd_data[display_buffer];

generate 
for (j = 0; j < 2; j = j + 1)
begin:	collision_buffers bram #(.BITS(4), .ADDRESS_BITS(10)) coll_br_inst
(
	CLK,
	collision_rd_addr[j],
	collision_rd_data[j],
	collision_wr_addr[j],
	collision_wr_data[j],
	collision_wr[j]
);
end
endgenerate

// Collision ram

reg [7:0]  collision_list_wr_addr;
reg [15:0] collision_list_mask_r;
reg collision_list_wr;

reg [15:0] collision_wr_list_data;

wire [15:0] collision_list_data_w;
assign collision_list_data = collision_list_data_w; //{8'h00, ADDRESS[7:0]};

wire [7:0] collision_list_rd_addr = collision_list_address;

bram_mask #(.BITS(16), .ADDRESS_BITS(8)) bm0
(
	CLK,
	collision_list_rd_addr,
	collision_list_data_w,
	collision_list_wr_addr,
	collision_wr_list_data,
	collision_list_wr,  
	collision_list_mask_r
);

//assign color_index = collision_list_data_w;

// Memory write

always @(*)
begin
	xram_WR = 1'b0;
	yram_WR = 1'b0;
	hram_WR = 1'b0;
	aram_WR = 1'b0;

	// TODO: make low two bits of address select bram, so each sprite channel has lumped registers
	case (ADDRESS[9:8])
		2'b00:	/* X ram */
			xram_WR = WR;
		2'b01: /* Y ram */
			yram_WR = WR;
		2'b10:  /* H ram */
			hram_WR = WR;
		2'b11:  /* A ram */
			aram_WR = WR;
		default: ;
	endcase
end

// Sprite render state machine

reg [3:0] r_state, r_state_next;

localparam r_idle 			  = 4'd0;
localparam r_begin			  = 4'd1;
localparam r_load_sprite_regs = 4'd2;
localparam r_load_mem_addr	  = 4'd3;
localparam r_wait_mem_0		  = 4'd4;
localparam r_wait_mem_1		  = 4'd5;
localparam r_blit_0			  = 4'd6;
localparam r_blit_1			  = 4'd7;
localparam r_blit_2			  = 4'd8;
localparam r_blit_3			  = 4'd9;
localparam r_finish			  = 4'd10;

reg [7:0] cur_sprite_r, cur_sprite_r_next;

assign xram_rd_addr = cur_sprite_r;
assign yram_rd_addr = cur_sprite_r;
assign hram_rd_addr = cur_sprite_r; 
assign aram_rd_addr = cur_sprite_r; 

reg [9:0] cur_sprite_x; 
reg [9:0] cur_sprite_x_next;

reg [7:0] cur_sprite_v; 
reg [7:0] cur_sprite_v_next;

reg [3:0] cur_sprite_palette;
reg [3:0] cur_sprite_palette_next;

reg [5:0] cur_sprite_x_count; 
reg [5:0] cur_sprite_x_count_next; 

wire [5:0] cur_sprite_u = cur_sprite_x_count;

reg [17:0] sprite_addr_r;
reg [17:0] sprite_addr_r_next;

assign memory_address = sprite_addr_r[17:2];

reg rvalid_r;
assign rvalid = rvalid_r;

reg [15:0] cur_sprite_data;
reg [15:0] cur_sprite_data_next;


// Render process

always @(CLK)
begin
	r_state_next 		= r_state;
	active_buffer_next  = active_buffer;
	cur_sprite_r_next   = cur_sprite_r;

	sprite_addr_r_next = sprite_addr_r;

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
	scanline_wr_data[display_buffer] = 8'h00;	

	cur_sprite_x_next = cur_sprite_x; 
	cur_sprite_v_next = cur_sprite_v;
	cur_sprite_x_count_next = cur_sprite_x_count;
	cur_sprite_palette_next = cur_sprite_palette;

	rvalid_r = 1'b0;

	cur_sprite_data_next = cur_sprite_data;
	
	// If we get a H tick, start next scanline
	if (H_tick == 1'b1)
	begin
		active_buffer_next = display_buffer;
		r_state_next = r_begin;
		cur_sprite_r_next = 8'd0;
	end
	else begin
		case (r_state)
			r_idle: ;
			r_begin:
				// 1 cycle delay while block ram is fetched
				r_state_next = r_load_sprite_regs;
			r_load_sprite_regs: begin
				cur_sprite_x_next = xram_out[9:0]; 
				cur_sprite_x_count_next = 0;
				cur_sprite_palette_next = xram_out[14:11];
				if ((xram_out[10] == 1'b1) && (display_y >= yram_out[9:0]) && (display_y <= hram_out[9:0])) begin
					// Sprite enabled
					cur_sprite_v_next = display_y - yram_out[9:0];
					r_state_next = r_load_mem_addr;
				end
				else begin
					cur_sprite_r_next = cur_sprite_r + 1;
					if (cur_sprite_r == 8'hff)
						r_state_next = r_idle;
					else
						r_state_next = r_begin;
				end
			end
			r_load_mem_addr: begin

				if (xram_out[15] == 1'b0)
					sprite_addr_r_next = {10'd0, cur_sprite_u} + {3'd0, cur_sprite_v, 7'd0} + {aram_out, 2'b00};
				else
					sprite_addr_r_next = {10'd0, cur_sprite_u} + {2'd0, cur_sprite_v, 8'd0} + {aram_out, 2'b00};

				r_state_next = r_wait_mem_0;
			end
			r_wait_mem_0: begin
				rvalid_r = 1'b1;
				r_state_next = r_wait_mem_1;
			end
			r_wait_mem_1: begin
				rvalid_r = 1'b1;
				if (rready == 1'b1) begin
					r_state_next = r_blit_0;
					cur_sprite_data_next = memory_data;
				end
			end	
			r_blit_0: begin
				cur_sprite_x_next = cur_sprite_x + 1;
				cur_sprite_x_count_next = cur_sprite_x_count + 1;

				scanline_wr[active_buffer] = cur_sprite_data[3:0] != 4'b000;
			
				if (cur_sprite_data[3:0] != 4'd0)
					scanline_wr_data[active_buffer] = {cur_sprite_palette, cur_sprite_data[3:0]};			

				if (cur_sprite_x_count == yram_out[15:10])
					r_state_next = r_finish;
				else
					r_state_next = r_blit_1;
			end	
			r_blit_1: begin
				cur_sprite_x_next = cur_sprite_x + 1;
				cur_sprite_x_count_next = cur_sprite_x_count + 1;

				scanline_wr[active_buffer] = cur_sprite_data[7:4] != 4'b000;
	
				if (cur_sprite_data[7:4] != 4'd0)
					scanline_wr_data[active_buffer] = {cur_sprite_palette, cur_sprite_data[7:4]};			

				if (cur_sprite_x_count == yram_out[15:10])
					r_state_next = r_finish;
				else
					r_state_next = r_blit_2;
			end
			r_blit_2: begin

				cur_sprite_x_next = cur_sprite_x + 1;
				cur_sprite_x_count_next = cur_sprite_x_count + 1;

				scanline_wr[active_buffer] = cur_sprite_data[11:8] != 4'b000;
				
				if (cur_sprite_data[11:8] != 4'd0)
					scanline_wr_data[active_buffer] = {cur_sprite_palette, cur_sprite_data[11:8]};			

				if (cur_sprite_x_count == yram_out[15:10])
					r_state_next = r_finish;
				else
					r_state_next = r_blit_3;
		
			end
			r_blit_3: begin
			
				cur_sprite_x_next = cur_sprite_x + 1;
				cur_sprite_x_count_next = cur_sprite_x_count + 1;

				scanline_wr[active_buffer] = cur_sprite_data[15:12] != 4'b000;
				
				if (cur_sprite_data[15:12] != 4'd0)
					scanline_wr_data[active_buffer] = {cur_sprite_palette, cur_sprite_data[15:12]};	

				if (cur_sprite_x_count == yram_out[15:10])
					r_state_next = r_finish;
				else
					r_state_next = r_load_mem_addr;
		
			end
			r_finish: begin
				cur_sprite_r_next = cur_sprite_r + 1;
				if (cur_sprite_r == 8'hff) 
					r_state_next = r_idle;
				else
					r_state_next = r_begin;
			end
			default: ;
		endcase
	end
end

// Collision process

reg [9:0] cur_collision_x, cur_collision_x_next;

integer k;

task collision_check;
begin
	if (collision_rd_data[active_cbuffer] != 4'hf) begin
		collision_wr_list_data = 16'hffff;
		collision_list_mask_r[collision_rd_data[active_cbuffer]] = 1'b0;
		collision_list_wr = 1'b1;
		//collision_wr_data[active_cbuffer] = 4'h1;
	end
end
endtask

always @(*)
begin
	cur_collision_x_next = cur_collision_x;

	collision_list_wr 	  = 1'b0; 
	collision_list_mask_r = 16'hffff;
	collision_list_wr_addr = cur_sprite_r;
	collision_wr_list_data = 16'h0000;

	collision_wr_addr[0] = 10'd0;
	collision_wr_addr[1] = 10'd0;

	collision_wr[0] 		= 1'b0;
	collision_wr[1] 		= 1'b0;

	collision_wr_data[0] = 8'h00;	
	collision_wr_data[1] = 8'h00;	

	collision_wr_addr[active_cbuffer] = cur_sprite_x;
	collision_wr[active_cbuffer] 	  = 1'b0;
	collision_wr_data[active_cbuffer] = cur_sprite_r[7:4];	

	// Clear display buffer as it is read		
	collision_wr[display_cbuffer] 	  = 1'b1;
	collision_wr_addr[display_cbuffer] = display_x - 1;
	collision_wr_data[display_cbuffer] = 4'hf; // sprite class 15 (sprites 240 - 255) cannot collide	

	collision_rd_addr[0]  = 10'd0;
 	collision_rd_addr[1]  = 10'd0;

	collision_rd_addr[active_cbuffer] = cur_collision_x;
	collision_rd_addr[display_cbuffer] = display_x;

	active_cbuffer_next = active_cbuffer;

	if (H_tick == 1'b1)
	begin
		active_cbuffer_next = display_cbuffer;
	end
	else begin
		case (r_state)
			r_idle: ;
			r_begin: ;
			r_load_sprite_regs: begin
				cur_collision_x_next = xram_out[9:0];
			end
			r_load_mem_addr: begin
			end
			r_wait_mem_0: begin
			end
			r_wait_mem_1: begin
				if (rready == 1'b1) 
					cur_collision_x_next = cur_collision_x + 1;
			end	
			r_blit_0: begin
				if (cur_sprite_data[3:0] != 4'b000)
					collision_check();
				cur_collision_x_next = cur_collision_x + 1;
				collision_wr[active_cbuffer] = cur_sprite_data[3:0] != 4'b000;
			end	
			r_blit_1: begin
				if (cur_sprite_data[7:4] != 4'b000)
					collision_check();
				cur_collision_x_next = cur_collision_x + 1;
				collision_wr[active_cbuffer] = cur_sprite_data[7:4] != 4'b000;
			end
			r_blit_2: begin
				if (cur_sprite_data[11:8] != 4'b000)
					collision_check();
				cur_collision_x_next = cur_collision_x + 1;
				collision_wr[active_cbuffer] = cur_sprite_data[11:8] != 4'b000;
			end
			r_blit_3: begin
				if (cur_sprite_data[15:12] != 4'b000)
					collision_check();
				collision_wr[active_cbuffer] = cur_sprite_data[15:12] != 4'b000;
			end
			r_finish: begin
			end
			default: ;
		endcase
	end

	if (display_y == 10'd0) begin
		collision_list_wr 	  = 1'b1; 
		collision_list_mask_r = 16'h0000;
		collision_list_wr_addr = display_x[7:0];
		collision_wr_list_data = 16'h0000;
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
		active_cbuffer <= 1'b0;
		r_state 	  <= r_idle;
		cur_sprite_r  <= 8'd0;
		cur_sprite_x  <= 10'd0; 
		cur_sprite_v  <= 8'd0; 
		cur_sprite_palette <= 4'd0;
		cur_sprite_x_count <= 7'd0; 
		sprite_addr_r <= 16'd0;
		cur_sprite_data <= 16'd0;
		cur_collision_x <= 10'd0;
	end else begin
		active_buffer <= active_buffer_next;
		active_cbuffer <= active_cbuffer_next;
		r_state 	  <= r_state_next;
		cur_sprite_r  <= cur_sprite_r_next;
		cur_sprite_x  <= cur_sprite_x_next; 
		cur_sprite_v  <= cur_sprite_v_next; 
		cur_sprite_palette <= cur_sprite_palette_next;
		cur_sprite_x_count <= cur_sprite_x_count_next; 
		sprite_addr_r <= sprite_addr_r_next;
		cur_sprite_data <= cur_sprite_data_next;
		cur_collision_x <= cur_collision_x_next;
	end
end

endmodule
