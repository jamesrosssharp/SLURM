module cpu_debug_core(
	input CLK,
	input RSTb,

	input trigger,
	
	input [31:0] debug_in,
	input tickle_watchdog,

	output debug_pin
);

wire tick;

baudgen 
#(.CLK_FREQ(25125000), .BAUD_RATE(115200)) bg0
( 
	CLK,
	tick 
);

reg [7:0] char = 8'h41;
reg go = 1'b0;
wire done_sig;

uart_tx u0
(
	CLK,
	RSTb,
	char,
	tick,
	go,
	done_sig,
	debug_pin
);

localparam st_idle 		= 4'd0;
localparam st_latch_value 	= 4'd1;
localparam st_uart_tx 		= 4'd2;
localparam st_wait_uart_done	= 4'd3;
localparam st_wait_no_done	= 4'd4;
localparam st_shift_value	= 4'd5;

reg [31:0] val;

reg [3:0] state = st_idle;
reg [3:0] count = 4'd0;

always @(posedge CLK)
begin

	case (state)
		st_idle: begin
			state <= st_latch_value;
			go <= 1'b0;
		end
		st_latch_value: begin
			if (trigger) begin
				val <= debug_in;
				state <= st_uart_tx;
			end
			count <= 4'd0;
			go <= 1'b0;
		end
		st_uart_tx: begin
			state <= st_wait_no_done;
			go <= 1'b1;
		end
		st_wait_no_done: begin
			if (!done_sig) begin
				go <= 1'b0;
				state <= st_wait_uart_done;
			end
		end
		st_wait_uart_done: begin
			if (done_sig) begin
				state <= st_shift_value;
			end
		end
		st_shift_value: begin
			count <= count + 1;
	
			val <= {val[27:0], 4'd0};
			if (count == 4'd9)
				state <= st_latch_value;
			else
				state <= st_uart_tx;
		end
	endcase
end

always @(*)
begin
	if (count == 4'd8)
		char = 8'h0a;
	else if (count == 4'd9)
		char = 8'h0d;
	else begin
		case (val[31:28])
			4'h0:
				char = 8'h30;
			4'h1:
				char = 8'h31;
			4'h2:
				char = 8'h32;
			4'h3:
				char = 8'h33;
			4'h4:
				char = 8'h34;
			4'h5:
				char = 8'h35;
			4'h6:
				char = 8'h36;
			4'h7:
				char = 8'h37;

			4'h8:
				char = 8'h38;
			4'h9:
				char = 8'h39;
			4'ha:
				char = 8'h41;
			4'hb:
				char = 8'h42;

			4'hc:
				char = 8'h43;
			4'hd:
				char = 8'h44;
			4'he:
				char = 8'h45;
			4'hf:
				char = 8'h46;
			default: char = 8'h21;
		endcase
	end
end

endmodule
