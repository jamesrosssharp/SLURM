/*
 *	SPI flash with DMA
 *
 */

module spi_flash
#(parameter BITS = 16, ADDRESS_BITS = 4, CLK_FREQ = 25125000)
(
	input CLK,	
	input RSTb,
	input [ADDRESS_BITS - 1 : 0]  ADDRESS,
	input [BITS - 1 : 0] DATA_IN,
	output [BITS - 1 : 0] DATA_OUT,
	input WR,  /* write memory */
	output MOSI,
	input MISO,
	output SCK,
	output CSb,

	// DMA memory write port

	output wvalid,
	input  wready,
	output [15:0] memory_address,
	output [15:0] memory_data,

	output irq

);

localparam idle		= 3'b000;
localparam send_cmd = 3'b001;
localparam send_address = 3'b010;
localparam get_data = 3'b011;
localparam mem_wr1	= 3'b100;
localparam mem_wr2	= 3'b101;
localparam done		= 3'b110;
localparam send_wake_cmd = 3'b111;

reg [2:0] state_r;
reg [2:0] state_r_next;

reg [15:0] address_lo_r;
reg [15:0] address_lo_r_next;

reg [15:0] address_hi_r;
reg [15:0] address_hi_r_next;

reg [15:0] data_out_r;
reg [15:0] data_out_r_next;

reg [2:0] tick_counter_r;
reg [2:0] tick_counter_r_next;
reg [4:0] bit_counter_r;
reg [4:0] bit_counter_r_next;

reg [15:0] dma_memory_address_r;
reg [15:0] dma_memory_address_r_next;

reg [15:0] dma_count_r;
reg [15:0] dma_count_r_next;

reg [15:0] dma_memory_address2_r;
reg [15:0] dma_memory_address2_r_next;

reg [15:0] dma_count2_r;
reg [15:0] dma_count2_r_next;

assign memory_address = dma_memory_address2_r;
assign memory_data = {data_out_r[7:0], data_out_r[15:8]};

reg irq_r;
assign irq = irq_r;

reg wvalid_r;
assign wvalid = wvalid_r; 

reg MOSI_r;
assign MOSI = MOSI_r;

reg SCK_r;
reg SCK_r_next;
assign SCK = SCK_r;

reg CSb_r, CSb_r_next;
assign CSb = CSb_r;

reg [23:0] serialOut_r;
reg [23:0] serialOut_r_next;

reg go_r;
reg go_r_next;

reg wake_r;
reg wake_r_next;

reg done_r;
reg done_r_next;

reg [BITS - 1 : 0] dout_r;

assign DATA_OUT = dout_r;

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		address_lo_r	<= 16'h0000;
		address_hi_r	<= 16'h0000;
		go_r		<= 1'b0;
		wake_r		<= 1'b0;
		done_r		<= 1'b0;
		data_out_r	<= 16'h0000;
		state_r		<= idle;
		tick_counter_r	<= 3'd0;
		bit_counter_r 	<= 5'd0;
		serialOut_r	<= 24'd0;
		SCK_r		<= 1'b0;
		dma_memory_address_r	<= 16'h0000;
		dma_count_r		<= 16'h0000;
		dma_memory_address2_r 	<= 16'h0000;
		dma_count2_r		<= 16'h0000;
		CSb_r 			<= 1'b1;
	end else begin
		address_lo_r  	<= address_lo_r_next;
		address_hi_r  	<= address_hi_r_next;
		go_r		<= go_r_next;
		wake_r		<= wake_r_next;
		done_r		<= done_r_next;
		data_out_r	<= data_out_r_next;
		state_r		<= state_r_next;
		serialOut_r	<= serialOut_r_next;
		tick_counter_r	<= tick_counter_r_next;
		bit_counter_r 	<= bit_counter_r_next;
		SCK_r		<= SCK_r_next;
		dma_memory_address_r	<= dma_memory_address_r_next;
		dma_count_r		<= dma_count_r_next;
		dma_memory_address2_r 	<= dma_memory_address2_r_next;
		dma_count2_r		<= dma_count2_r_next;
		CSb_r 			<= CSb_r_next;
	end
end

always @(*)
begin

	address_lo_r_next = address_lo_r;
	address_hi_r_next = address_hi_r;
	go_r_next 	= 1'b0;
	wake_r_next 	= 1'b0;

	dma_memory_address_r_next 	= dma_memory_address_r;
	dma_count_r_next		= dma_count_r;

	dout_r 				= {BITS{1'b0}};

	case (ADDRESS)
		4'h0:	/* Flash Address lo reg */
			if (WR == 1'b1) begin
				address_lo_r_next = DATA_IN;
			end
		4'h1: /* Flash Address hi reg */
			if (WR == 1'b1) begin
				address_hi_r_next = DATA_IN;
			end
		4'h2: /* CMD reg */
			if (WR == 1'b1) begin
				go_r_next 	= DATA_IN[0];
				wake_r_next 	= DATA_IN[1];
			end
		4'h3: /* Data reg */
			dout_r = {data_out_r[7:0], data_out_r[15:8]};
		4'h4: /* Status bits reg */
			dout_r = {15'd0, done_r};
		4'h5:  /* DMA memory address */
			if (WR == 1'b1) begin
				dma_memory_address_r_next = DATA_IN;
			end
		4'h6:  /* DMA transfer count (16-bit words) */
			if (WR == 1'b1) begin 
				dma_count_r_next = DATA_IN;
			end
		default:;
	endcase
end

localparam readCmd = 24'h030000;
localparam wakeCmd = 24'hab0000;

always @(*)
begin
	state_r_next		= state_r;
	done_r_next		= done_r;
	serialOut_r_next	= serialOut_r;
	tick_counter_r_next 	= tick_counter_r;
	bit_counter_r_next	= bit_counter_r;
	SCK_r_next		= SCK_r;
	CSb_r_next		= CSb_r;
	MOSI_r			= 1'b0;
	data_out_r_next		= data_out_r;
	irq_r 			= 1'b0;

	dma_memory_address2_r_next 	= dma_memory_address2_r;
	dma_count2_r_next		= dma_count2_r;

	wvalid_r 	= 1'b0;

	case (state_r)
		idle:
			if (go_r == 1'b1) begin
				state_r_next	= send_cmd;
				done_r_next	= 1'b0;
				serialOut_r_next 	= readCmd; 
				tick_counter_r_next 	= 3'd0;
				bit_counter_r_next	= 5'd0;
				CSb_r_next		= 1'b0;
				SCK_r_next		= 1'b0;
				dma_memory_address2_r_next = dma_memory_address_r;
				dma_count2_r_next 	= dma_count_r;	
			end else if (wake_r == 1'b1) begin
				state_r_next		= send_wake_cmd;
				done_r_next		= 1'b0;
				serialOut_r_next 	= wakeCmd; 
				tick_counter_r_next 	= 3'd0;
				bit_counter_r_next	= 5'd0;
				CSb_r_next		= 1'b0;
				SCK_r_next		= 1'b0;
			end
		send_wake_cmd: begin
			tick_counter_r_next 	= tick_counter_r + 1;	
			MOSI_r			= serialOut_r[23];

			if (tick_counter_r == 3'b100)
				SCK_r_next = 1'b1;

			if (tick_counter_r == 3'b111)
			begin
				bit_counter_r_next 	= bit_counter_r + 1;
				serialOut_r_next 	= {serialOut_r[22:0], 1'b0};
				SCK_r_next 		= 1'b0;

				if (bit_counter_r == 5'd7) begin
					state_r_next = done;
				end
			end
		end
		send_cmd: begin
			tick_counter_r_next 	= tick_counter_r + 1;	
			MOSI_r			= serialOut_r[23];

			if (tick_counter_r == 3'b100)
				SCK_r_next = 1'b1;

			if (tick_counter_r == 3'b111)
			begin
				bit_counter_r_next 	= bit_counter_r + 1;
				serialOut_r_next 	= {serialOut_r[22:0], 1'b0};
				SCK_r_next = 1'b0;

				if (bit_counter_r == 5'd7) begin
					state_r_next 		= send_address;
					serialOut_r_next 	= {address_hi_r[6:0], address_lo_r[15:0], 1'b0}; 
					tick_counter_r_next 	= 3'd0;
					bit_counter_r_next	= 5'd0;
				end
			end
		end
		send_address: begin
			tick_counter_r_next = tick_counter_r + 1;	
			MOSI_r		= serialOut_r[23];

			if (tick_counter_r == 3'b100)
				SCK_r_next = 1'b1;

			if (tick_counter_r == 3'b111)
			begin
				bit_counter_r_next = bit_counter_r + 1;
				serialOut_r_next = {serialOut_r[22:0], 1'b0};
				SCK_r_next = 1'b0;

				if (bit_counter_r == 5'd23) begin
					state_r_next = get_data;
					tick_counter_r_next 	= 3'd0;
					bit_counter_r_next	= 5'd0;
				end
			end
		end
		get_data: begin
			tick_counter_r_next = tick_counter_r + 1;	

			if (tick_counter_r == 3'b100) begin
				SCK_r_next = 1'b1;
				data_out_r_next = {data_out_r[14:0], MISO};
			end

			if (tick_counter_r == 3'b111)
			begin
				bit_counter_r_next = bit_counter_r + 1;
				SCK_r_next = 1'b0;

				if (bit_counter_r == 5'd15) begin
					state_r_next = mem_wr1;
				end
			end
		end
		mem_wr1: begin
			wvalid_r = 1'b1;
			state_r_next = mem_wr2;
			end
		mem_wr2: begin
			wvalid_r = 1'b1;
			if (wready == 1'b1) begin
				//wvalid_r = 1'b0;
				dma_memory_address2_r_next = dma_memory_address2_r + 1;
				dma_count2_r_next = dma_count2_r - 1;
				if (dma_count2_r == 16'd0)
					state_r_next = done;
				else begin
					tick_counter_r_next 	= 3'd0;
					bit_counter_r_next	= 5'd0;
					state_r_next = get_data;
				end
			end
		end
		done: begin
			CSb_r_next 	= 1'b1;
			done_r_next 	= 1'b1;
			state_r_next 	= idle;
			SCK_r_next 	= 1'b1;
			irq_r 		= 1'b1;		// Assert interrupt
		end
		default:
			state_r_next = idle;
	endcase
end


endmodule
