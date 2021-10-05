/*
 *
 *	SPI master for flash
 *
 */

module spi_flash
#(parameter BITS = 16, ADDRESS_BITS = 8, CLK_FREQ = 25125000)
(
	input CLK,	
	input RSTb,
	input [ADDRESS_BITS - 1 : 0]  ADDRESS,
	input [BITS - 1 : 0] DATA_IN,
	output [BITS - 1 : 0] DATA_OUT,
	input WR,  /* write memory */
	output MO,
	output MO_OE,
	input  MI,
	output SO,
	output SO_OE,
	input  SI,
	output SSb,
	output SSb_OE,
	output SCK_O,
	input  SCK_I,
	output SCK_OE
);

localparam idle = 3'b000;
localparam read = 3'b001;
localparam read_done  = 3'b010;
localparam write 	  = 3'b011;
localparam write_done = 3'b100;

reg [7:0] address_r;
reg [7:0] address_r_next;

reg [7:0] data_in_r;
reg [7:0] data_in_r_next;

reg [BITS - 1 : 0] dout_r;

reg [2:0] state_r = idle;
reg [2:0] state_r_next;

reg go_read_r;
reg go_read_r_next;

reg go_write_r;
reg go_write_r_next;

assign DATA_OUT = dout_r;

reg spi_stb;
reg spi_rw;

wire spi_ack;

wire [7:0] spi_data_out;

reg [7:0] spi_data_out_r;
reg [7:0] spi_data_out_r_next;

reg read_done_r, read_done_r_next;
reg write_done_r, write_done_r_next;

SB_SPI #(.BUS_ADDR74("0b0000")) 
	SB_SPI_inst( .SBCLKI(CLK), 
					.SBSTBI(spi_stb), 
					.SBRWI(spi_rw),
					/* address bus */
      				.SBADRI0(address_r[0]), 
					.SBADRI1(address_r[1]), 
					.SBADRI2(address_r[2]), 
					.SBADRI3(address_r[3]), 
					.SBADRI4(address_r[4]), 
					.SBADRI5(address_r[5]), 
					.SBADRI6(address_r[6]), 
					.SBADRI7(address_r[7]),
					/* data in */
      				.SBDATI0(data_in_r[0]), 
					.SBDATI1(data_in_r[1]), 
					.SBDATI2(data_in_r[2]), 
					.SBDATI3(data_in_r[3]), 
					.SBDATI4(data_in_r[4]), 
					.SBDATI5(data_in_r[5]), 
					.SBDATI6(data_in_r[6]), 
					.SBDATI7(data_in_r[7]),
      				/* data out */
					.SBDATO0(spi_data_out[0]), 
					.SBDATO1(spi_data_out[1]), 
					.SBDATO2(spi_data_out[2]), 
					.SBDATO3(spi_data_out[3]), 
					.SBDATO4(spi_data_out[4]), 
					.SBDATO5(spi_data_out[5]), 
					.SBDATO6(spi_data_out[6]), 
					.SBDATO7(spi_data_out[7]),
      				.SBACKO(spi_ack),
      				.MI(MI), 
      				.MO(MO), 
					.MOE(MO_OE),
					.SI(SI),
					.SO(SO),
					.SOE(SO_OE),
					.SCKI(SCK_I),
					.SCKO(SCK_O),
					.SCKOE(SCK_OE),
					.SCSNI(1'b1),
					.MCSNO1(SSb),
					.MCSNOE1(SSb_OE)
   );


always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		address_r  <= 8'h00;
		data_in_r <= 8'h00;
		state_r <= idle;
		go_read_r <= 1'b0;
		go_write_r <= 1'b0;
		spi_data_out_r <= 8'h00;
		read_done_r <= 1'b0;
		write_done_r <= 1'b0;
	end else begin
		address_r  <= address_r_next;
		data_in_r  <= data_in_r_next;
		state_r    <= state_r_next;
		go_read_r  <= go_read_r_next;
		go_write_r <= go_write_r_next;
		spi_data_out_r <= spi_data_out_r_next;
		read_done_r <= read_done_r_next;
		write_done_r <= write_done_r_next;
	
	end
end

always @(*)
begin

	address_r_next = address_r;
	data_in_r_next = data_in_r;

	dout_r = {BITS{1'b0}};

	go_write_r_next = 1'b0;
	go_read_r_next = 1'b0;

	case (ADDRESS)
		8'h00:	/* Address reg */
			if (WR == 1'b1) begin
				address_r_next = DATA_IN[7:0];
			end
		8'h01: /* Data out reg */
			dout_r = {8'h00, spi_data_out_r};
		8'h02: /* Data in reg */
			if (WR == 1'b1) begin
				data_in_r_next = DATA_IN[7:0];
			end
		8'h03: /* Command bits reg */
			if (WR == 1'b1) begin
				go_write_r_next = DATA_IN[0];
				go_read_r_next  = DATA_IN[1];
			end
		8'h04: /* Status bits reg */
			dout_r = {14'd0, read_done_r, write_done_r};
		default:;
	endcase
end

// Glue logic state machine to talk to IP

always @(*)
begin
	state_r_next = state_r;	
	spi_data_out_r_next = spi_data_out_r;
	read_done_r_next = read_done_r;
	write_done_r_next = write_done_r;

	spi_stb = 1'b0;
	spi_rw = 1'b0;

	case (state_r)
		idle:
			if (go_write_r == 1'b1) begin
				spi_stb = 1'b1;
				spi_rw = 1'b1;
				state_r_next 		= write;
				write_done_r_next 	= 1'b0;
			end
			else if (go_read_r == 1'b1) begin
				spi_stb = 1'b1;
				spi_rw = 1'b0;
				state_r_next 		= read;
				read_done_r_next 	= 1'b0;
			end
		read: begin
			spi_stb = 1'b1;
			spi_rw = 1'b0;

			if (spi_ack == 1'b1) begin
				state_r_next 		= read_done;
				spi_data_out_r_next = spi_data_out;  
			end

		end
		read_done: begin
			read_done_r_next = 1'b1;
			state_r_next = idle;
		end
		write: begin
			spi_stb = 1'b1;
			spi_rw = 1'b1;

			if (spi_ack == 1'b1) begin
				state_r_next 		= write_done;
			end
		end
		write_done: begin
			write_done_r_next = 1'b1;
			state_r_next = idle;
		end
		default: ;

	endcase
end

endmodule
