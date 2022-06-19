/*
 *
 *	CPU instruction FIFO: stores fetched instructions waiting to execute.
 *	FIFO will fill and drain as cpu pipeline stalls, or halts due to
 *	memory interface.
 *
 */


module cpu_instruction_cache_fifo #(
	parameter FIFO_DEPTH_BITS = 4,
	parameter FIFO_WIDTH_BITS = 32	
) (
	input CLK,
	input RSTb,

	input [FIFO_WIDTH_BITS - 1 : 0]  fifo_in,
	output [FIFO_WIDTH_BITS - 1 : 0] fifo_out,

	output fifo_empty,	/* = 1 when fifo is empty */
	output fifo_full,	/* = 1 when fifo is full */

	output fifo_almost_empty, /* = 1 when next read would empty fifo */

	input  wr_fifo,		/* 1 => load an instruction / PC combo into fifo */
	input  rd_fifo		/* 1 => read an instruction / PC combo from fifo */
);

reg [FIFO_DEPTH_BITS - 1: 0] fifo_rd_ptr, fifo_rd_ptr_next;
reg [FIFO_DEPTH_BITS - 1: 0] fifo_wr_ptr, fifo_wr_ptr_next;

reg empty, empty_next;
reg full, full_next;

assign fifo_empty = empty;
assign fifo_full = full;

wire [FIFO_DEPTH_BITS - 1 : 0] fifo_rd_ptr_succ = fifo_rd_ptr + 1;
wire [FIFO_DEPTH_BITS - 1 : 0] fifo_wr_ptr_succ = fifo_wr_ptr + 1;

assign fifo_almost_empty = (fifo_rd_ptr_succ == fifo_wr_ptr);

wire [1:0] rdwr = {rd_fifo, wr_fifo};

bram
#(.BITS(FIFO_WIDTH_BITS), .ADDRESS_BITS(FIFO_DEPTH_BITS)) mem0
(
	.CLK(CLK),
	.RD_ADDRESS(fifo_rd_ptr),
	.DATA_OUT(fifo_out),
	.WR_ADDRESS(fifo_wr_ptr),
	.DATA_IN(fifo_in),
	.WR(wr_fifo)
);

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		empty <= 1'b1;
		full  <= 1'b0;
		fifo_rd_ptr <= {FIFO_DEPTH_BITS {1'b0}};
		fifo_wr_ptr <= {FIFO_DEPTH_BITS {1'b0}};
	end else begin
		empty <= empty_next;	
		full  <= full_next;
		fifo_rd_ptr <= fifo_rd_ptr_next;
		fifo_wr_ptr <= fifo_wr_ptr_next;
	end	
end

always @(*)
begin
	fifo_rd_ptr_next = fifo_rd_ptr;
	fifo_wr_ptr_next = fifo_wr_ptr;
	empty_next = empty;
	full_next = full;

	case (rdwr)
		2'b10: begin
			/* Read */
			full_next = 1'b0;
			if (! empty) begin
				fifo_rd_ptr_next = fifo_rd_ptr_succ;
				if (fifo_rd_ptr_succ == fifo_wr_ptr)
					empty_next = 1'b1;
			end
		end
		2'b01: begin
			/* Write */
			empty_next = 1'b0;
			if (! full) begin
				fifo_wr_ptr_next = fifo_wr_ptr_succ;
				if (fifo_wr_ptr_succ == fifo_rd_ptr)
					full_next = 1'b1;
			end	
		end
		2'b11: begin
			/* Read and write */
			fifo_rd_ptr_next = fifo_rd_ptr_succ;
			fifo_wr_ptr_next = fifo_wr_ptr_succ;
		end
		default: ;
	endcase	

end

endmodule
