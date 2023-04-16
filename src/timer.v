module timer #(parameter BITS = 16, parameter ADDRESS_BITS = 4)
(
	input CLK,
	input RSTb,
	input  [ADDRESS_BITS - 1 : 0]  ADDRESS,
	input  [BITS - 1 : 0] DATA_IN,
	output [BITS - 1 : 0] DATA_OUT,
	input  WR,	/* port write */
	output irq
);

localparam COUNTER_BITS = 23;

reg [COUNTER_BITS - 1 : 0] count;
reg [BITS - 1 : 0] count_out;
reg [BITS - 1 : 0] match;


/* all reads return count */
assign DATA_OUT = count_out;

reg enable  = 1'b0;

assign irq = (match == count); /* leave for future expansion */

always @(posedge CLK)
begin
	case (ADDRESS)
		4'h0:	/* Control register */
			if (WR == 1'b1) begin
				enable <= DATA_IN[0];
			end
		4'h1: 
			if (WR == 1'b1)
				match <= DATA_IN;
		default:;
	endcase
end

always @(posedge CLK)
begin
	
	if (enable == 1'b1) begin
			count <= count + 1;
	end

	count_out <= count[BITS + 6:7];
end


endmodule
