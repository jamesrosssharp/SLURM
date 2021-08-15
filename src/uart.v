module uart 
#(parameter CLK_FREQ = 12000000, parameter BAUD_RATE = 115200, parameter BITS = 16)
(
	input CLK,	
	input RSTb,
	input [7 : 0]  ADDRESS,
	inout [BITS - 1 : 0] DATA,
	input OEb,  /* output enable */
	input WRb,  /* write memory  */
	output TX   /* UART output   */
);

reg [7:0] tx_reg; 
reg [7:0] tx_reg_next; 

reg go_reg;
reg go_reg_next;

wire tick;

reg [BITS - 1 : 0] data_reg;

assign DATA = (OEb == 1'b0) ? data_reg : {BITS{1'bz}};

baudgen #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) bd0
( 
	CLK,
	tick 
);

wire done_sig;

uart_tx u0
(
	CLK,
	RSTb,
	tx_reg,
	tick,
	go_reg,
	done_sig,
	TX
);

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		tx_reg <= 8'h00;
		go_reg <= 1'b0;
	end else begin
		tx_reg <= tx_reg_next;
		go_reg <= go_reg_next;
	end
end

always @(*)
begin
	go_reg_next = 1'b0;
	tx_reg_next = tx_reg;
	data_reg = {BITS{1'b0}};

	casex (ADDRESS)
		8'h00:	/* TX register */
			if (WRb == 1'b0) begin
				tx_reg_next = DATA;
				go_reg_next = 1'b1;	
			end
		8'h01:  /* TX status register */
			data_reg[0] = done_sig; 
	endcase
end

endmodule
