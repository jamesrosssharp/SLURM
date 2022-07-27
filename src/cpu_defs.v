/*
 *	Misc definitions
 *
 *
 */

localparam NOP_INSTRUCTION = {BITS{1'b0}};
localparam LINK_REGISTER   			 = 4'd15;
localparam INTERRUPT_LINK_REGISTER   = 4'd14;
localparam R0 = {REGISTER_BITS{1'b0}};

// To do: put instruction casex masks in this file

localparam INSTRUCTION_CASEX_NOP			= NOP_INSTRUCTION;
localparam INSTRUCTION_CASEX_RET_IRET			= 16'h01xx;
localparam INSTRUCTION_CASEX_ALUOP_SINGLE_REG		= 16'h04xx;
localparam INSTRUCTION_CASEX_INTERRUPT			= 16'h05xx;
localparam INSTRUCTION_CASEX_INTERRUPT_EN		= 16'h06xx;
localparam INSTRUCTION_CASEX_SLEEP			= 16'h07xx;
localparam INSTRUCTION_CASEX_IMM			= 16'h1xxx;
localparam INSTRUCTION_CASEX_ALUOP_REG_REG		= 16'h2xxx;
localparam INSTRUCTION_CASEX_ALUOP_REG_IMM		= 16'h3xxx;
localparam INSTRUCTION_CASEX_BRANCH			= 16'h4xxx;
localparam INSTRUCTION_CASEX_COND_MOV			= 16'h5xxx;
localparam INSTRUCTION_CASEX_BYTE_LOAD_SX		= 16'h8xxx;
localparam INSTRUCTION_CASEX_BYTE_LOAD_STORE		= 16'b101xxxxxxxxxxxxx;
localparam INSTRUCTION_CASEX_LOAD_STORE			= 16'b110xxxxxxxxxxxxx;
localparam INSTRUCTION_CASEX_PEEK_POKE			= 16'b111xxxxxxxxxxxxx;


