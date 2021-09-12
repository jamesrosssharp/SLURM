
module baudgen 
#(parameter CLK_FREQ = 12000000, parameter BAUD_RATE = 9600)
( 
	input CLK,
	output tick 
);

reg tickOut = 0;

reg [31:0] baudCtr = 0;

assign tick = tickOut;

always @(posedge CLK)
begin
	
	tickOut <= 0;

	baudCtr <= baudCtr + 1;

	if (baudCtr == (CLK_FREQ / BAUD_RATE) - 1)
	begin
		baudCtr <= 0;
		tickOut <= 1;
	end

end

endmodule
