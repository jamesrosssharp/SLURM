/*
 *
 *	interrupt controller
 *
 */

module interrupt_controller 
#(parameter BITS = 16)
(
	input  CLK,	
	input  RSTb,
	input  [3 : 0]  ADDRESS,
	input  [BITS - 1 : 0] 	DATA_IN,
	output [BITS - 1 : 0] 	DATA_OUT,
	input  WR,  /* write to port  */

	input irq_hsync,
	input irq_vsync,
	input irq_audio,
	input irq_spi_flash,
	input irq_gpio,

	output interrupt,	// On interrupt, this signal is asserted to CPU
	output [3:0] irq	// This vector contains (priority encoded) IRQ to assert
);

localparam N_INTERRUPTS = 5;

reg [N_INTERRUPTS - 1:0] irq_pending, irq_pending_next;
reg [N_INTERRUPTS - 1:0] irq_clear_pending, irq_clear_pending_next;
reg [N_INTERRUPTS - 1:0] irq_enabled, irq_enabled_next;

wire [N_INTERRUPTS - 1:0] irq_in = {irq_gpio, irq_spi_flash, irq_audio, irq_vsync, irq_hsync};

reg [3:0] irq_out, irq_out_next;
reg interrupt_out, interrupt_out_next;

assign interrupt = interrupt_out;
assign irq = irq_out;

// Sequential logic

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		irq_pending 		<= {N_INTERRUPTS{1'b0}};
		irq_clear_pending 	<= {N_INTERRUPTS{1'b0}};
		irq_enabled 		<= {N_INTERRUPTS{1'b0}};
		interrupt_out 	<= 1'b0;
		irq_out 		<= 4'd0;
	end else begin
		irq_pending 		<= irq_pending_next;
		irq_clear_pending 	<= irq_clear_pending_next;
		irq_enabled 		<= irq_enabled_next;
		interrupt_out	<= interrupt_out_next;
		irq_out			<= irq_out_next;
	end
end

// Port interface 

reg [15:0] dout_r;
assign DATA_OUT = dout_r;

always @(CLK)
begin
	irq_enabled_next = irq_enabled;
	dout_r = 16'h0000;
	irq_clear_pending_next = {N_INTERRUPTS{1'b0}};

	case (ADDRESS)
		4'h0: begin	/* IRQ Enabled reg */
			if (WR == 1'b1) begin
				irq_enabled_next = DATA_IN[N_INTERRUPTS - 1:0];
			end
			dout_r[N_INTERRUPTS - 1:0] = irq_enabled;
		end
		4'h1: begin	/* clear or read pending reg */
			if (WR == 1'b1) begin
				irq_clear_pending_next = DATA_IN[N_INTERRUPTS - 1:0];
			end
		end
		4'h2: begin /* read out pending - separate reg to prevent logic loop */
			dout_r[N_INTERRUPTS - 1:0] = irq_pending;
		end
		default:;
	endcase
end

// Pending

always @(*)
begin
	irq_pending_next = (irq_pending & ~irq_clear_pending) | irq_in;
end

// Priority encoded interrupts

integer i;

always @(*)
begin
	irq_out_next 		= 4'd0;
	interrupt_out_next  = 1'b1;

	casex (irq_pending & irq_enabled)
		5'bxxxx1:
			irq_out_next = 4'd1;
		5'bxxx10:
			irq_out_next = 4'd2;
		5'bxx100:
			irq_out_next = 4'd3;
		5'bx1000:
			irq_out_next = 4'd4;
		5'b10000:
			irq_out_next = 4'd5;
		default: 
			interrupt_out_next = 1'b0;
	endcase

end


endmodule
