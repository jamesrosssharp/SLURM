module gfx_memory_arbiter
(
	input  CLK,
	input  RSTb,
	
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

	/* background controller 2 */
	input  [15:0] 	bg2_memory_address,
	output [15:0] 	bg2_memory_data,
	input 			bg2_rvalid, // memory address valid
	output  		bg2_rready,  // memory data valid

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

reg [15:0] 	bg2_memory_data_r;
reg 		bg2_rready_r;



assign sprite_rready = sprite_rready_r; 
assign sprite_memory_data = sprite_memory_data_r;

assign bg0_rready = bg0_rready_r; 
assign bg0_memory_data = bg0_memory_data_r;

assign bg1_rready = bg1_rready_r; 
assign bg1_memory_data = bg1_memory_data_r;

assign bg2_rready = bg2_rready_r; 
assign bg2_memory_data = bg2_memory_data_r;

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

localparam s_idle = 3'd0;
localparam s_grant_sp = 3'd1;
localparam s_grant_bg0 = 3'd2;
localparam s_grant_bg1 = 3'd3;
localparam s_grant_bg2 = 3'd4;
localparam s_grant_ov  = 3'd5;

reg [2:0] state_r_0;
reg [2:0] state_r_0_next;

reg [2:0] state_r_1;
reg [2:0] state_r_1_next;

reg [2:0] state_r_2;
reg [2:0] state_r_2_next;

reg [2:0] state_r_3;
reg [2:0] state_r_3_next;


always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		state_r_0 = s_idle;
		state_r_1 = s_idle;
		state_r_2 = s_idle;
		state_r_3 = s_idle;
	end else begin
		state_r_0 = state_r_0_next;
		state_r_1 = state_r_1_next;
		state_r_2 = state_r_2_next;
		state_r_3 = state_r_3_next;
	end
end

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
	bg2_memory_data_r = 16'h0000;
	bg2_rready_r = 1'b0;

	state_r_0_next = state_r_0;
	state_r_1_next = state_r_1;
	state_r_2_next = state_r_2;
	state_r_3_next = state_r_3;

	case (state_r_0)
		s_idle: begin
			if (sprite_rvalid == 1'b1 && sprite_memory_address[15:14] == 2'b00) begin
				b1_addr_r = sprite_memory_address;				
				b1_valid_r = 1'b1;
				state_r_0_next = s_grant_sp; 
			end else
			if (bg0_rvalid == 1'b1 && bg0_memory_address[15:14] == 2'b00) begin
				b1_addr_r = bg0_memory_address;				
				b1_valid_r = 1'b1;
				state_r_0_next = s_grant_bg0;
			end else
			if (bg1_rvalid == 1'b1 && bg1_memory_address[15:14] == 2'b00) begin
				b1_addr_r = bg1_memory_address;				
				b1_valid_r = 1'b1;
				state_r_0_next = s_grant_bg1;	
			end  else
			if (bg2_rvalid == 1'b1 && bg2_memory_address[15:14] == 2'b00) begin
				b1_addr_r = bg2_memory_address;				
				b1_valid_r = 1'b1;
				state_r_0_next = s_grant_bg2;
			end 
		end
		s_grant_sp: begin
			b1_addr_r = sprite_memory_address;				
			b1_valid_r = 1'b1;
			if (sprite_rvalid == 1'b0)
				state_r_0_next = s_idle;
			sprite_memory_data_r = B1_DOUT;
			sprite_rready_r = 1'b1;
		end
		s_grant_bg0: begin
			b1_addr_r = bg0_memory_address;				
			b1_valid_r = 1'b1;
			if (bg0_rvalid == 1'b0)
				state_r_0_next = s_idle;
			bg0_memory_data_r = B1_DOUT;
			bg0_rready_r = 1'b1;
		end
		s_grant_bg1: begin
			b1_addr_r = bg1_memory_address;				
			b1_valid_r = 1'b1;
			if (bg1_rvalid == 1'b0)
				state_r_0_next = s_idle;
			bg1_memory_data_r = B1_DOUT;
			bg1_rready_r = 1'b1;
		end
		s_grant_bg2: begin
			b1_addr_r = bg2_memory_address;				
			b1_valid_r = 1'b1;
			if (bg2_rvalid == 1'b0)
				state_r_0_next = s_idle;
			bg2_memory_data_r = B1_DOUT;
			bg2_rready_r = 1'b1;
		end
		default: ;
	endcase

	case (state_r_1)
		s_idle: begin
			if (sprite_rvalid == 1'b1 && sprite_memory_address[15:14] == 2'b01) begin
				b2_addr_r = sprite_memory_address;				
				b2_valid_r = 1'b1;
				state_r_1_next = s_grant_sp; 
			end else
			if (bg0_rvalid == 1'b1 && bg0_memory_address[15:14] == 2'b01) begin
				b2_addr_r = bg0_memory_address;				
				b2_valid_r = 1'b1;
				state_r_1_next = s_grant_bg0;
			end else
			if (bg1_rvalid == 1'b1 && bg1_memory_address[15:14] == 2'b01) begin
				b2_addr_r = bg1_memory_address;				
				b2_valid_r = 1'b1;
				state_r_1_next = s_grant_bg1;	
			end  else
			if (bg2_rvalid == 1'b1 && bg2_memory_address[15:14] == 2'b01) begin
				b2_addr_r = bg2_memory_address;				
				b2_valid_r = 1'b1;
				state_r_1_next = s_grant_bg2;
			end 
		end
		s_grant_sp: begin
			b2_addr_r = sprite_memory_address;				
			b2_valid_r = 1'b1;
			if (sprite_rvalid == 1'b0)
				state_r_1_next = s_idle;
			sprite_memory_data_r = B2_DOUT;
			sprite_rready_r = 1'b1;
		end
		s_grant_bg0: begin
			b2_addr_r = bg0_memory_address;				
			b2_valid_r = 1'b1;
			if (bg0_rvalid == 1'b0)
				state_r_1_next = s_idle;
			bg0_memory_data_r = B2_DOUT;
			bg0_rready_r = 1'b1;
		end
		s_grant_bg1: begin
			b2_addr_r = bg1_memory_address;				
			b2_valid_r = 1'b1;
			if (bg1_rvalid == 1'b0)
				state_r_1_next = s_idle;
			bg1_memory_data_r = B2_DOUT;
			bg1_rready_r = 1'b1;
		end
		s_grant_bg2: begin
			b2_addr_r = bg2_memory_address;				
			b2_valid_r = 1'b1;
			if (bg2_rvalid == 1'b0)
				state_r_1_next = s_idle;
			bg2_memory_data_r = B2_DOUT;
			bg2_rready_r = 1'b1;
		end
		default: ;
	endcase

	case (state_r_2)
		s_idle: begin
			if (sprite_rvalid == 1'b1 && sprite_memory_address[15:14] == 2'b10) begin
				b3_addr_r = sprite_memory_address;				
				b3_valid_r = 1'b1;
				state_r_2_next = s_grant_sp; 
			end else
			if (bg0_rvalid == 1'b1 && bg0_memory_address[15:14] == 2'b10) begin
				b3_addr_r = bg0_memory_address;				
				b3_valid_r = 1'b1;
				state_r_2_next = s_grant_bg0;
			end else
			if (bg1_rvalid == 1'b1 && bg1_memory_address[15:14] == 2'b10) begin
				b3_addr_r = bg1_memory_address;				
				b3_valid_r = 1'b1;
				state_r_2_next = s_grant_bg1;	
			end  else
			if (bg2_rvalid == 1'b1 && bg2_memory_address[15:14] == 2'b10) begin
				b3_addr_r = bg2_memory_address;				
				b3_valid_r = 1'b1;
				state_r_2_next = s_grant_bg2;
			end 
		end
		s_grant_sp: begin
			b3_addr_r = sprite_memory_address;				
			b3_valid_r = 1'b1;
			if (sprite_rvalid == 1'b0)
				state_r_2_next = s_idle;
			sprite_memory_data_r = B3_DOUT;
			sprite_rready_r = 1'b1;
		end
		s_grant_bg0: begin
			b3_addr_r = bg0_memory_address;				
			b3_valid_r = 1'b1;
			if (bg0_rvalid == 1'b0)
				state_r_2_next = s_idle;
			bg0_memory_data_r = B3_DOUT;
			bg0_rready_r = 1'b1;
		end
		s_grant_bg1: begin
			b3_addr_r = bg1_memory_address;				
			b3_valid_r = 1'b1;
			if (bg1_rvalid == 1'b0)
				state_r_2_next = s_idle;
			bg1_memory_data_r = B3_DOUT;
			bg1_rready_r = 1'b1;
		end
		s_grant_bg2: begin
			b3_addr_r = bg2_memory_address;				
			b3_valid_r = 1'b1;
			if (bg2_rvalid == 1'b0)
				state_r_2_next = s_idle;
			bg2_memory_data_r = B3_DOUT;
			bg2_rready_r = 1'b1;
		end
		default: ;
	endcase

	case (state_r_3)
		s_idle: begin
			if (sprite_rvalid == 1'b1 && sprite_memory_address[15:14] == 2'b11) begin
				b4_addr_r = sprite_memory_address;				
				b4_valid_r = 1'b1;
				state_r_3_next = s_grant_sp; 
			end else
			if (bg0_rvalid == 1'b1 && bg0_memory_address[15:14] == 2'b11) begin
				b4_addr_r = bg0_memory_address;				
				b4_valid_r = 1'b1;
				state_r_3_next = s_grant_bg0;
			end else
			if (bg1_rvalid == 1'b1 && bg1_memory_address[15:14] == 2'b11) begin
				b4_addr_r = bg1_memory_address;				
				b4_valid_r = 1'b1;
				state_r_3_next = s_grant_bg1;	
			end  else
			if (bg2_rvalid == 1'b1 && bg2_memory_address[15:14] == 2'b11) begin
				b4_addr_r = bg2_memory_address;				
				b4_valid_r = 1'b1;
				state_r_3_next = s_grant_bg2;
			end 
		end
		s_grant_sp: begin
			b4_addr_r = sprite_memory_address;				
			b4_valid_r = 1'b1;
			if (sprite_rvalid == 1'b0)
				state_r_3_next = s_idle;
			sprite_memory_data_r = B4_DOUT;
			sprite_rready_r = 1'b1;
		end
		s_grant_bg0: begin
			b4_addr_r = bg0_memory_address;				
			b4_valid_r = 1'b1;
			if (bg0_rvalid == 1'b0)
				state_r_3_next = s_idle;
			bg0_memory_data_r = B4_DOUT;
			bg0_rready_r = 1'b1;
		end
		s_grant_bg1: begin
			b4_addr_r = bg1_memory_address;				
			b4_valid_r = 1'b1;
			if (bg1_rvalid == 1'b0)
				state_r_3_next = s_idle;
			bg1_memory_data_r = B4_DOUT;
			bg1_rready_r = 1'b1;
		end
		s_grant_bg2: begin
			b4_addr_r = bg2_memory_address;				
			b4_valid_r = 1'b1;
			if (bg2_rvalid == 1'b0)
				state_r_3_next = s_idle;
			bg2_memory_data_r = B4_DOUT;
			bg2_rready_r = 1'b1;
		end
		default: ;
	endcase 
end

endmodule
