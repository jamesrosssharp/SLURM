/*
 *
 *	Port interface: handle io ports
 *
 *
 */

module cpu_port_interface #(parameter BITS = 16, ADDRESS_BITS = 16)  (
	input CLK,
	input RSTb,

	input [ADDRESS_BITS - 1:0] port_address_in,
	input [BITS - 1:0] port_data_in,
	input port_rd_in,
	input port_wr_in,

	output [ADDRESS_BITS - 1:0] port_address,
	output [BITS - 1:0] port_data,
	output port_rd,
	output port_wr
);

reg [ADDRESS_BITS - 1:0] port_address_r;
reg [BITS - 1:0] port_data_r;
reg port_rd_r;
reg port_wr_r;

assign port_address = port_address_r;
assign port_data 	= port_data_r;
assign port_rd 		= port_rd_r;
assign port_wr 		= port_wr_r;

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		port_address_r <= {ADDRESS_BITS{1'b0}};
		port_data_r <= {BITS{1'b0}};
		port_rd_r   <= 1'b0;
		port_wr_r   <= 1'b0;		
	end else begin
		port_address_r <= port_address_in;
		port_data_r <= port_data_in;
		port_rd_r   <= port_rd_in;
		port_wr_r   <= port_wr_in;		
	end
end
 
endmodule
