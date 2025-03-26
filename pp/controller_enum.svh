`ifndef CONTROLLER_DEFS_SVH
`define CONTROLLER_DEFS_SVH

// ALU Operations
typedef enum logic [3:0] {
    ALU_ADD    = 4'b0000,
    ALU_SUB    = 4'b0001,
    ALU_SLL    = 4'b0010,
    ALU_SRL    = 4'b0011,
    ALU_SRA    = 4'b0100,
    ALU_SLT    = 4'b0101,
    ALU_SLTU   = 4'b0110,
    ALU_XOR    = 4'b0111,
    ALU_OR     = 4'b1000,
    ALU_AND    = 4'b1001,
    ALU_PASS   = 4'b1010
} alu_op_t;

// Branch Types
typedef enum logic [2:0] {
    BR_NONE    = 3'b000,
    BR_EQ      = 3'b001,
    BR_NE      = 3'b010,
    BR_LT      = 3'b011,
    BR_GE      = 3'b100,
    BR_LTU     = 3'b101,
    BR_GEU     = 3'b110,
    BR_JUMP    = 3'b111
} br_type_t;

// Writeback Sources
typedef enum logic [1:0] {
    WB_PC      = 2'b00,
    WB_ALU     = 2'b01,
    WB_IMM     = 2'b10,
    WB_MEM     = 2'b11
} wb_sel_t;

// Opcodes (RV32I Base Set)
localparam OPCODE_LOAD    = 7'b0000011;
localparam OPCODE_STORE   = 7'b0100011;
localparam OPCODE_BRANCH  = 7'b1100011;
localparam OPCODE_JALR    = 7'b1100111;
localparam OPCODE_JAL     = 7'b1101111;
localparam OPCODE_AUIPC   = 7'b0010111;
localparam OPCODE_LUI     = 7'b0110111;
localparam OPCODE_ARI_I   = 7'b0010011;  // Arithmetic I-type
localparam OPCODE_ARI_R   = 7'b0110011;  // Arithmetic R-type

// Function3 Codes
localparam F3_ADD_SUB    = 3'b000;
localparam F3_SLL        = 3'b001;
localparam F3_SLT        = 3'b010;
localparam F3_SLTU       = 3'b011;
localparam F3_XOR        = 3'b100;
localparam F3_SR         = 3'b101;  // SRL/SRA
localparam F3_OR         = 3'b110;
localparam F3_AND        = 3'b111;

`endif // CONTROLLER_DEFS_SVH