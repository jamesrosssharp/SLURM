module cpu_debug_core2
(
	input CLK,
	input trigger,
	input [15:0] data_in,
	output [15:0] data_out,
	input rd_data,	/* assert this to read the next data block from the memory */
	input wr_enable /* assert this to write to buffer */
);

reg triggered = 1'b0;

reg [15:0] read_address;
reg [15:0] write_address;

bram 
#(.BITS(16), .ADDRESS_BITS(8)) ram0
(
	CLK,
	read_address,
	data_out,
	
	write_address,
	data_in,
	!triggered && wr_enable
);



always @(posedge CLK)
begin
	if (trigger == 1'b1 && triggered == 1'b0) begin
		triggered <= 1'b1;
		read_address <= write_address + 1;
	end

	if (triggered == 1'b0)
		write_address <= write_address + 1;

	if (rd_data == 1'b1)
		read_address <= read_address + 1;
end

endmodule
