module bram_mask
#(parameter BITS = 16, ADDRESS_BITS = 8)
(
    input CLK,
    input [ADDRESS_BITS - 1 : 0]  RD_ADDRESS,
    output [BITS - 1 : 0] DATA_OUT,

    input [ADDRESS_BITS - 1 : 0] WR_ADDRESS,
    input [BITS - 1 : 0] DATA_IN,
    input WR,  
    input [15:0] WR_mask
);


SB_RAM40_4K SB_RAM40_4K_inst(
      .RDATA(DATA_OUT), 
	  .RADDR(RD_ADDRESS), 
	  .WADDR(WR_ADDRESS), 
	  .MASK(WR_mask), 
	  .WDATA(DATA_IN), 
	  .RCLKE(1'b1), 
	  .RCLK(CLK), 
	  .RE(1'b1), 
	  .WCLKE(1'b1), 
	  .WCLK(CLK), 
	  .WE(WR)
   );

endmodule
