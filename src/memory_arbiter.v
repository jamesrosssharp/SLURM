module memory_arbiter
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

	/* overlay controller */
	input  [15:0] 	ov_memory_address,
	output [15:0] 	ov_memory_data,
	input 			ov_rvalid, // memory address valid
	output  		ov_rready,  // memory data valid

	/* flash controller */
	input  [15:0] 	fl_memory_address,
	input [15:0] 	fl_memory_data,
	input 			fl_wvalid, // memory address valid
	output  		fl_wready,  // memory data valid
	
	/* audio controller */
	input  [15:0] 	au_memory_address,
	output [15:0] 	au_memory_data,
	input 			au_rvalid, // memory address valid
	output  		au_rready,  // memory data valid

	/* CPU */
	input  [15:0] 	cpu_memory_address,
	input  [15:0]   cpu_memory_data_in,
	output [15:0] 	cpu_memory_data,
	input 			cpu_valid, // memory address valid
	input			cpu_wr, // CPU is writing to memory
	output  		cpu_ready,  // memory access granted

	output [13 : 0] B1_ADDR,
	input  [15 : 0] B1_DOUT,
	output [15 : 0] B1_DIN,
	output B1_WR,

	output [13 : 0] B2_ADDR,
	input  [15 : 0] B2_DOUT,
	output [15 : 0] B2_DIN,
	output B2_WR,

	output [13 : 0] B3_ADDR,
	input  [15 : 0] B3_DOUT,
	output [15 : 0] B3_DIN,
	output B3_WR,

	output [13 : 0] B4_ADDR,
	input  [15 : 0] B4_DOUT,
	output [15 : 0] B4_DIN,
	output B4_WR
);

reg [15:0] 	sprite_memory_data_r;
reg 		sprite_rready_r;

reg [15:0] 	bg0_memory_data_r;
reg 		bg0_rready_r;

reg [15:0] 	bg1_memory_data_r;
reg 		bg1_rready_r;

reg [15:0] 	ov_memory_data_r;
reg 		ov_rready_r;

reg [15:0] 	au_memory_data_r;
reg 		au_rready_r;

reg [15:0] 	cpu_memory_data_r;
reg 		cpu_rready_r;

reg 		fl_wready_r;

assign sprite_rready = sprite_rready_r; 
assign sprite_memory_data = sprite_memory_data_r;

assign bg0_rready = bg0_rready_r; 
assign bg0_memory_data = bg0_memory_data_r;

assign bg1_rready = bg1_rready_r; 
assign bg1_memory_data = bg1_memory_data_r;

assign ov_rready = ov_rready_r; 
assign ov_memory_data = ov_memory_data_r;

assign au_rready = au_rready_r;
assign au_memory_data = au_memory_data_r;

assign cpu_rready 		= cpu_rready_r;
assign cpu_memory_data 	= cpu_memory_data_r;

assign fl_wready = fl_wready_r;

reg [13:0]		b1_addr_r;
reg			b1_wr_r;
reg [15:0]  b1_data_r;

assign B1_ADDR 		 = b1_addr_r;
assign B1_WR		 = b1_wr_r;
assign B1_DIN		 = b1_data_r;

reg [13:0]		b2_addr_r;
reg				b2_wr_r;
reg [15:0]  	b2_data_r;

assign B2_ADDR 		 = b2_addr_r;
assign B2_WR		 = b2_wr_r;
assign B2_DIN		 = b2_data_r;

reg [13:0]		b3_addr_r;
reg				b3_wr_r;
reg [15:0]  	b3_data_r;

assign B3_ADDR 		 = b3_addr_r;
assign B3_WR		 = b3_wr_r;
assign B3_DIN		 = b3_data_r;

reg [13:0]		b4_addr_r;
reg				b4_wr_r;
reg [15:0]  	b4_data_r;

assign B4_ADDR 		 = b4_addr_r;
assign B4_WR		 = b4_wr_r;
assign B4_DIN		 = b4_data_r;

localparam s_idle = 3'd0;
localparam s_grant_sp = 3'd1;
localparam s_grant_bg0 = 3'd2;
localparam s_grant_bg1 = 3'd3;
localparam s_grant_ov  = 3'd4;
localparam s_grant_fl  = 3'd5;
localparam s_grant_au  = 3'd6;
localparam s_grant_cpu = 3'd7;

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
	b1_wr_r 		= 1'b0;
	b2_addr_r 		= 16'h0000;
	b2_wr_r 		= 1'b0;
	b3_addr_r 		= 16'h0000;
	b3_wr_r 		= 1'b0;
	b4_addr_r 		= 16'h0000;
	b4_wr_r 		= 1'b0;
	b1_data_r		= 16'h0000;
	b2_data_r		= 16'h0000;
	b3_data_r		= 16'h0000;
	b4_data_r		= 16'h0000;

	sprite_rready_r = 1'b0;
	sprite_memory_data_r = 16'h0000;
	bg0_memory_data_r 	 = 16'h0000;
	bg0_rready_r		 = 1'b0;
	bg1_memory_data_r 	 = 16'h0000;
	bg1_rready_r 		 = 1'b0;
	ov_memory_data_r 	 = 16'h0000;
	ov_rready_r 		 = 1'b0;

	fl_wready_r 		 = 1'b0;

	state_r_0_next = state_r_0;
	state_r_1_next = state_r_1;
	state_r_2_next = state_r_2;
	state_r_3_next = state_r_3;

	case (state_r_0)
		s_idle: begin
			if (sprite_rvalid == 1'b1 && sprite_memory_address[15:14] == 2'b00) begin
				b1_addr_r = sprite_memory_address;				
				state_r_0_next = s_grant_sp; 
			end else
			if (bg0_rvalid == 1'b1 && bg0_memory_address[15:14] == 2'b00) begin
				b1_addr_r = bg0_memory_address;				
				state_r_0_next = s_grant_bg0;
			end else
			if (bg1_rvalid == 1'b1 && bg1_memory_address[15:14] == 2'b00) begin
				b1_addr_r = bg1_memory_address;				
				state_r_0_next = s_grant_bg1;	
			end else
			if (ov_rvalid == 1'b1 && ov_memory_address[15:14] == 2'b00) begin
				b1_addr_r = ov_memory_address;				
				state_r_0_next = s_grant_ov;	
			end else
			if (fl_wvalid == 1'b1 && fl_memory_address[15:14] == 2'b00) begin
				b1_addr_r = fl_memory_address;				
				b1_data_r = fl_memory_data;				
				b1_wr_r = 1'b1;
				state_r_0_next = s_grant_fl;	
			end else if (au_rvalid == 1'b1 && au_memory_address[15:14] == 2'b00) begin
				b1_addr_r = au_memory_address;				
				state_r_0_next = s_grant_au;	
			end else if (cpu_valid == 1'b1 && cpu_memory_address[15:14] == 2'b00) begin
				b1_addr_r = cpu_memory_address;				
				b1_data_r = cpu_memory_data;				
				b1_wr_r = cpu_wr;
				state_r_0_next = s_grant_cpu;	
			end
		end
		s_grant_sp: begin
			b1_addr_r = sprite_memory_address;				
			if (sprite_rvalid == 1'b0)
				state_r_0_next = s_idle;
			sprite_memory_data_r = B1_DOUT;
			sprite_rready_r = 1'b1;
		end
		s_grant_bg0: begin
			b1_addr_r = bg0_memory_address;				
			if (bg0_rvalid == 1'b0)
				state_r_0_next = s_idle;
			bg0_memory_data_r = B1_DOUT;
			bg0_rready_r = 1'b1;
		end
		s_grant_bg1: begin
			b1_addr_r = bg1_memory_address;				
			if (bg1_rvalid == 1'b0)
				state_r_0_next = s_idle;
			bg1_memory_data_r = B1_DOUT;
			bg1_rready_r = 1'b1;
		end
		s_grant_ov: begin
			b1_addr_r = ov_memory_address;				
			if (ov_rvalid == 1'b0)
				state_r_0_next = s_idle;
			ov_memory_data_r = B1_DOUT;
			ov_rready_r = 1'b1;
		end
		s_grant_fl: begin
			b1_addr_r = fl_memory_address;				
			b1_wr_r = 1'b1;
			if (fl_wvalid == 1'b0) begin
				state_r_0_next = s_idle;
				b1_wr_r 	   = 1'b0;
			end
			b1_data_r   = fl_memory_data;
			fl_wready_r = 1'b1;
		end
		s_grant_au: begin
			b1_addr_r = au_memory_address;				
			if (au_rvalid == 1'b0)
				state_r_0_next = s_idle;
			au_memory_data_r = B1_DOUT;
			au_rready_r = 1'b1;
		end
		s_grant_cpu: begin
			b1_addr_r = cpu_memory_address;				
			b1_wr_r = cpu_wr;
			if (cpu_valid == 1'b0) begin
				state_r_0_next = s_idle;
				b1_wr_r 	   = 1'b0;
			end
			b1_data_r   = cpu_memory_data_in;
			cpu_memory_data_r = B1_DOUT;
			cpu_ready_r = 1'b1;
		end
	default: ;
	endcase

	case (state_r_1)
		s_idle: begin
			if (sprite_rvalid == 1'b1 && sprite_memory_address[15:14] == 2'b01) begin
				b2_addr_r = sprite_memory_address;				
				state_r_1_next = s_grant_sp; 
			end else
			if (bg0_rvalid == 1'b1 && bg0_memory_address[15:14] == 2'b01) begin
				b2_addr_r = bg0_memory_address;				
				state_r_1_next = s_grant_bg0;
			end else
			if (bg1_rvalid == 1'b1 && bg1_memory_address[15:14] == 2'b01) begin
				b2_addr_r = bg1_memory_address;				
				state_r_1_next = s_grant_bg1;	
			end
			if (ov_rvalid == 1'b1 && ov_memory_address[15:14] == 2'b01) begin
				b2_addr_r = ov_memory_address;				
				state_r_1_next = s_grant_ov;	
			end
			if (fl_wvalid == 1'b1 && fl_memory_address[15:14] == 2'b01) begin
				b2_addr_r = fl_memory_address;				
				b2_data_r = fl_memory_data;				
				b2_wr_r = 1'b1;
				state_r_1_next = s_grant_fl;	
			end else if (au_rvalid == 1'b1 && au_memory_address[15:14] == 2'b01) begin
				b2_addr_r = au_memory_address;				
				state_r_1_next = s_grant_au;	
			end else if (cpu_valid == 1'b1 && cpu_memory_address[15:14] == 2'b01) begin
				b2_addr_r = cpu_memory_address;				
				b2_data_r = cpu_memory_data;				
				b2_wr_r = cpu_wr;
				state_r_1_next = s_grant_cpu;	
			end
		end
		s_grant_sp: begin
			b2_addr_r = sprite_memory_address;				
			if (sprite_rvalid == 1'b0)
				state_r_1_next = s_idle;
			sprite_memory_data_r = B2_DOUT;
			sprite_rready_r = 1'b1;
		end
		s_grant_bg0: begin
			b2_addr_r = bg0_memory_address;				
			if (bg0_rvalid == 1'b0)
				state_r_1_next = s_idle;
			bg0_memory_data_r = B2_DOUT;
			bg0_rready_r = 1'b1;
		end
		s_grant_bg1: begin
			b2_addr_r = bg1_memory_address;				
			if (bg1_rvalid == 1'b0)
				state_r_1_next = s_idle;
			bg1_memory_data_r = B2_DOUT;
			bg1_rready_r = 1'b1;
		end
		s_grant_ov: begin
			b2_addr_r = ov_memory_address;				
			if (ov_rvalid == 1'b0)
				state_r_1_next = s_idle;
			ov_memory_data_r = B2_DOUT;
			ov_rready_r = 1'b1;
		end
		s_grant_fl: begin
			b2_addr_r = fl_memory_address;				
			b2_data_r = fl_memory_data;				
			b2_wr_r  = 1'b1;
			if (fl_wvalid == 1'b0) begin
				state_r_1_next = s_idle;
				b2_wr_r = 1'b0;
			end
			fl_wready_r = 1'b1;
		end
		s_grant_au: begin
			b2_addr_r = au_memory_address;				
			if (au_rvalid == 1'b0)
				state_r_1_next = s_idle;
			au_memory_data_r = B2_DOUT;
			au_rready_r = 1'b1;
		end
		s_grant_cpu: begin
			b2_addr_r = cpu_memory_address;				
			b2_wr_r = cpu_wr;
			if (cpu_valid == 1'b0) begin
				state_r_1_next = s_idle;
				b2_wr_r 	   = 1'b0;
			end
			b2_data_r   = cpu_memory_data_in;
			cpu_memory_data_r = B2_DOUT;
			cpu_ready_r = 1'b1;
		end
		default: ;
	endcase

	case (state_r_2)
		s_idle: begin
			if (sprite_rvalid == 1'b1 && sprite_memory_address[15:14] == 2'b10) begin
				b3_addr_r = sprite_memory_address;				
				state_r_2_next = s_grant_sp; 
			end else
			if (bg0_rvalid == 1'b1 && bg0_memory_address[15:14] == 2'b10) begin
				b3_addr_r = bg0_memory_address;				
				state_r_2_next = s_grant_bg0;
			end else
			if (bg1_rvalid == 1'b1 && bg1_memory_address[15:14] == 2'b10) begin
				b3_addr_r = bg1_memory_address;				
				state_r_2_next = s_grant_bg1;	
			end else
			if (ov_rvalid == 1'b1 && ov_memory_address[15:14] == 2'b10) begin
				b3_addr_r = ov_memory_address;				
				state_r_2_next = s_grant_ov;	
			end else
			if (fl_wvalid == 1'b1 && fl_memory_address[15:14] == 2'b10) begin
				b3_addr_r = fl_memory_address;				
				b3_wr_r = 1'b1;
				b3_data_r = fl_memory_data; 
				state_r_2_next = s_grant_fl;	
			end else if (au_rvalid == 1'b1 && au_memory_address[15:14] == 2'b10) begin
				b3_addr_r = au_memory_address;				
				state_r_2_next = s_grant_au;	
			end else if (cpu_valid == 1'b1 && cpu_memory_address[15:14] == 2'b10) begin
				b3_addr_r = cpu_memory_address;				
				b3_data_r = cpu_memory_data;				
				b3_wr_r = cpu_wr;
				state_r_2_next = s_grant_cpu;	
			end
		end
		s_grant_sp: begin
			b3_addr_r = sprite_memory_address;				
			if (sprite_rvalid == 1'b0)
				state_r_2_next = s_idle;
			sprite_memory_data_r = B3_DOUT;
			sprite_rready_r = 1'b1;
		end
		s_grant_bg0: begin
			b3_addr_r = bg0_memory_address;				
			if (bg0_rvalid == 1'b0)
				state_r_2_next = s_idle;
			bg0_memory_data_r = B3_DOUT;
			bg0_rready_r = 1'b1;
		end
		s_grant_bg1: begin
			b3_addr_r = bg1_memory_address;				
			if (bg1_rvalid == 1'b0)
				state_r_2_next = s_idle;
			bg1_memory_data_r = B3_DOUT;
			bg1_rready_r = 1'b1;
		end
		s_grant_ov: begin
			b3_addr_r = ov_memory_address;				
			if (ov_rvalid == 1'b0)
				state_r_2_next = s_idle;
			ov_memory_data_r = B3_DOUT;
			ov_rready_r = 1'b1;
		end
		s_grant_fl: begin
			b3_addr_r = fl_memory_address;				
			b3_wr_r = 1'b1;
			if (fl_wvalid == 1'b0) begin
				state_r_2_next = s_idle;
				b3_wr_r = 1'b0;
			end
			fl_wready_r = 1'b1;
			b3_data_r = fl_memory_data;
		end
		s_grant_au: begin
			b3_addr_r = au_memory_address;				
			if (au_rvalid == 1'b0)
				state_r_2_next = s_idle;
			au_memory_data_r = B3_DOUT;
			au_rready_r = 1'b1;
		end
		s_grant_cpu: begin
			b3_addr_r = cpu_memory_address;				
			b3_wr_r = cpu_wr;
			if (cpu_valid == 1'b0) begin
				state_r_2_next = s_idle;
				b2_wr_r 	   = 1'b0;
			end
			b3_data_r   = cpu_memory_data_in;
			cpu_memory_data_r = B3_DOUT;
			cpu_ready_r = 1'b1;
		end
		default: ;
	endcase

	case (state_r_3)
		s_idle: begin
			if (sprite_rvalid == 1'b1 && sprite_memory_address[15:14] == 2'b11) begin
				b4_addr_r = sprite_memory_address;				
				state_r_3_next = s_grant_sp; 
			end else
			if (bg0_rvalid == 1'b1 && bg0_memory_address[15:14] == 2'b11) begin
				b4_addr_r = bg0_memory_address;				
				state_r_3_next = s_grant_bg0;
			end else
			if (bg1_rvalid == 1'b1 && bg1_memory_address[15:14] == 2'b11) begin
				b4_addr_r = bg1_memory_address;				
				state_r_3_next = s_grant_bg1;	
			end else
 			if (ov_rvalid == 1'b1 && ov_memory_address[15:14] == 2'b11) begin
				b4_addr_r = ov_memory_address;				
				state_r_3_next = s_grant_ov;	
			end else
 			if (fl_wvalid == 1'b1 && fl_memory_address[15:14] == 2'b11) begin
				b4_addr_r = fl_memory_address;				
				b4_data_r = fl_memory_data;
				b4_wr_r = 1'b1;
				state_r_3_next = s_grant_fl;	
			end else if (au_rvalid == 1'b1 && au_memory_address[15:14] == 2'b11) begin
				b4_addr_r = au_memory_address;				
				state_r_3_next = s_grant_au;	
			end else if (cpu_valid == 1'b1 && cpu_memory_address[15:14] == 2'b11) begin
				b4_addr_r = cpu_memory_address;				
				b4_data_r = cpu_memory_data;				
				b4_wr_r = cpu_wr;
				state_r_3_next = s_grant_cpu;	
			end
		end
		s_grant_sp: begin
			b4_addr_r = sprite_memory_address;				
			if (sprite_rvalid == 1'b0)
				state_r_3_next = s_idle;
			sprite_memory_data_r = B4_DOUT;
			sprite_rready_r = 1'b1;
		end
		s_grant_bg0: begin
			b4_addr_r = bg0_memory_address;				
			if (bg0_rvalid == 1'b0)
				state_r_3_next = s_idle;
			bg0_memory_data_r = B4_DOUT;
			bg0_rready_r = 1'b1;
		end
		s_grant_bg1: begin
			b4_addr_r = bg1_memory_address;				
			if (bg1_rvalid == 1'b0)
				state_r_3_next = s_idle;
			bg1_memory_data_r = B4_DOUT;
			bg1_rready_r = 1'b1;
		end
		s_grant_ov: begin
			b4_addr_r = ov_memory_address;				
			if (ov_rvalid == 1'b0)
				state_r_3_next = s_idle;
			ov_memory_data_r = B4_DOUT;
			ov_rready_r = 1'b1;
		end
		s_grant_fl: begin
			b4_addr_r = fl_memory_address;				
			b4_wr_r = 1'b1;
			if (fl_wvalid == 1'b0) begin
				state_r_3_next = s_idle;
				b4_wr_r = 1'b0;
			end
			b4_data_r = fl_memory_daya;
			fl_wready_r = 1'b1;
		end
		s_grant_au: begin
			b4_addr_r = au_memory_address;				
			if (au_rvalid == 1'b0)
				state_r_3_next = s_idle;
			au_memory_data_r = B4_DOUT;
			au_rready_r = 1'b1;
		end
		s_grant_cpu: begin
			b4_addr_r = cpu_memory_address;				
			b4_wr_r = cpu_wr;
			if (cpu_valid == 1'b0) begin
				state_r_3_next = s_idle;
				b4_wr_r 	   = 1'b0;
			end
			b4_data_r   = cpu_memory_data_in;
			cpu_memory_data_r = B4_DOUT;
			cpu_ready_r = 1'b1;
		end
		default: ;

	endcase 
end

endmodule
