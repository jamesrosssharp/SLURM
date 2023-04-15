/*
 *
 *	Peripheral memory aribiter
 *
 *
 */

module slurm16_peripheral_memory_arbiter
(
	input CLK,
	input RSTb,
	output [1:0] mux_sel,
	output reg [13:0] periph_addr,
	output reg [15:0] periph_din,
	output reg periph_wr,
	output reg [1:0] periph_wr_mask,
	input sprite_valid,	/* sprite valid */ 
	input bg0_valid,   	/* background valid */
	input fl_valid, 	/* flash valid */
	input [15:0] sprite_memory_address, /* sprite address */
	input [15:0] bg0_memory_address, /* background address */
	input [15:0] fl_memory_address, /* flash address */
	input [15:0] fl_memory_data, /* flash write data */
	input [15:0] cpu_memory_address,
	input [15:0] cpu_memory_data_in,
	input cpu_wr,
	input [1:0] cpu_wr_mask

);

/* keep these states in synch with the mux sel values */
localparam st_idle_cpu = 2'd0;
localparam st_flash    = 2'd1;
localparam st_bg0      = 2'd2;
localparam st_sprite   = 2'd3;

reg [1:0] state_r;

assign mux_sel = state_r;

always @(*)
begin
	case (state_r)
		st_idle_cpu: begin
			periph_addr = cpu_memory_address[13:0];
			periph_din = cpu_memory_data_in;
			periph_wr = cpu_wr;
			periph_wr_mask = cpu_wr_mask;
		end
		st_flash: begin
			periph_addr = fl_memory_address[13:0];
			periph_din = fl_memory_data;
			periph_wr = 1'b1;
			periph_wr_mask = 2'b11;
		end
		st_bg0: begin
			periph_addr = bg0_memory_address[13:0];
			periph_din = cpu_memory_data_in;
			periph_wr = 1'b0;
			periph_wr_mask = cpu_wr_mask;
		end
		st_sprite: begin
			periph_addr = sprite_memory_address[13:0];
			periph_din = cpu_memory_data_in;
			periph_wr = 1'b0;
			periph_wr_mask = cpu_wr_mask;
		end
	endcase
end

always @(posedge CLK)
begin
	if (RSTb == 1'b0) 
		state_r <= st_idle_cpu;
	else begin
		case (state_r)
			st_idle_cpu:
				if (sprite_valid == 1'b1)
					state_r <= st_sprite;
				else if (bg0_valid == 1'b1)
					state_r <= st_bg0;
				else if (fl_valid == 1'b1)
					state_r <= st_flash;
			st_sprite:
				if (sprite_valid == 1'b0)
					state_r <= st_idle_cpu;
			st_bg0:
				if (bg0_valid == 1'b0)
					state_r <= st_idle_cpu;
			st_flash:
				if (fl_valid == 1'b0)
					state_r <= st_idle_cpu;
		endcase
	end
end


endmodule
