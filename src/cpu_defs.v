/*
 *	Misc definitions
 *
 *
 */

localparam NOP_INSTRUCTION = {BITS{1'b0}};
localparam LINK_REGISTER   = 5'd15;

// To do: put instruction casex masks in this file

localparam INSTRUCTION_CASEX_NOP			  = NOP_INSTRUCTION;
localparam INSTRUCTION_CASEX_RET_IRET		  = 16'h01xx;
localparam INSTRUCTION_CASEX_ALUOP_SINGLE_REG = 16'h04xx;
localparam INSTRUCTION_CASEX_ALUOP_REG_REG    = 16'h2xxx;
localparam INSTRUCTION_CASEX_ALUOP_REG_IMM    = 16'h3xxx;
localparam INSTRUCTION_CASEX_BRANCH    		  = 16'h4xxx;
localparam INSTRUCTION_CASEX_LOAD_STORE		  = 16'b110xxxxxxxxxxxxx;
localparam INSTRUCTION_CASEX_PEEK_POKE		  = 16'b111xxxxxxxxxxxxx;


