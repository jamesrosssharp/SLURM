/*
 *	Trace port - only used for simulation, so that there is an easy way to "print" to the simulation
 *	output.
 *
 *  Used to verify / regression test CPU.
 */

module trace (
	input CLK,
	input RSTb,
	input [3 : 0]   ADDRESS,
	input [15 : 0]  DATA_IN,
	output [15 : 0] DATA_OUT,
	input memWR,  /* write memory */
	input memRD  /* read request */
);

reg signed [15:0] traceVal_r; 
reg [7:0]  traceChar_r;
reg [15:0] traceHex_r;

wire signed [15:0] signed_data = DATA_IN;


always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		traceVal_r = 16'h0;
		traceChar_r = 8'h0;
		traceHex_r = 16'h0;
	end else
	if (memWR == 1'b1) begin
		case (ADDRESS)
			4'd0:  begin 
				traceVal_r <= DATA_IN;
				$write("%0d", signed_data);
			end
			4'd1:  begin
				traceChar_r <= DATA_IN[7:0]; 
				$write("%c", DATA_IN[7:0]);
			end
			4'd2:  begin
				traceHex_r <= DATA_IN;
				$write("%h", DATA_IN);
			end
			default: ;
		endcase
	end
end

endmodule
