module uart_tx
(
	input CLK,
	input RSTb,
	input [7:0] char,
	input tick,
	input go,
	output done_sig,
	output TX
);

reg tx_out;
reg tx_out_next;

reg done_out;
reg done_out_next;

assign TX = tx_out;
assign done_sig = done_out;

localparam idle 	  = 3'b000;
localparam latchWord  = 3'b001;
localparam startBit   = 3'b010;
localparam shiftBits  = 3'b011;
localparam stopBit    = 3'b100;
localparam done		  = 3'b101;

reg [2:0] state;
reg [2:0] state_next;

reg [7:0] txWord;
reg [7:0] txWord_next;

reg [2:0] bitCount;
reg [2:0] bitCount_next;

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		
		state <= idle;
		txWord <= 8'h00;
		bitCount <= 3'b000;
		done_out <= 1'b0;	
		tx_out <= 1'b1;
	end else begin

		state <= state_next;
		txWord <= txWord_next;
		bitCount <= bitCount_next;
		done_out <= done_out_next;
		tx_out <= tx_out_next;
	end
end

always @(*)
begin

	done_out_next 	= done_out;
	tx_out_next 			= 1;
	state_next 		= state;
	txWord_next 	= txWord;
	bitCount_next 	= bitCount; 

	case (state)
		idle: 
			begin
				if (go == 1) begin
					state_next = latchWord;
					done_out_next = 0;
				end
			end
		latchWord:
			begin
				txWord_next = char;
				if (tick)
					state_next  = startBit;
			end
		startBit:
			begin
				tx_out_next 				 = 0;
				if (tick) state_next = shiftBits;
				bitCount_next = 0;
			end
		shiftBits:
			begin
				tx_out_next = txWord[0];
				if (tick) begin
					txWord_next[6:0] = txWord[7:1];
					txWord_next[7] 	 = 0;
					bitCount_next = bitCount + 1;
					if (bitCount == 7) state_next = stopBit;
				end
			end
		stopBit:
			begin
				tx_out_next = 0;
				if (tick)
					state_next = done;
			end
		done:
			begin
				if (tick) begin
					done_out_next = 1;
					state_next = idle;
				end
			end
		default:
			state_next = idle;
	endcase

end


endmodule
