`include "controller_defs.svh"

module Controller (
    input  logic [31:0] inst,
    input  logic [31:0] inst1,
    output logic reg_wr,
    output logic rd_en,
    output logic wr_en,
    output logic sel_A,
    output logic sel_B,
    output logic sel_pA,
    output logic sel_pB,
    output wb_sel_t wb_sel,
    output br_type_t br_type,
    output alu_op_t alu_op
);
    // Instruction fields
    logic [6:0] opcode = inst[6:0];
    logic [4:0] rs1 = inst[19:15];
    logic [4:0] rs2 = inst[24:20];
    logic [2:0] func3 = inst[14:12];
    logic [6:0] func7 = inst[31:25];

    // Forwarding logic
    assign sel_pA = (inst1[11:7] == rs1) && (inst1[11:7] != 0);
    assign sel_pB = (inst1[11:7] == rs2) && (inst1[11:7] != 0);

    always_comb begin
        // Default values
        reg_wr = 0;
        rd_en = 0;
        wr_en = 0;
        sel_A = 1;  // Default to RS1
        sel_B = 0;  // Default to RS2
        wb_sel = WB_ALU;
        br_type = BR_NONE;
        alu_op = ALU_ADD;

        case(opcode)
            // R-Type Instructions
            OPCODE_ARI_R: begin
                reg_wr = 1;
                sel_B = 0;  // Use RS2
                
                case(func3)
                    F3_ADD_SUB: alu_op = func7[5] ? ALU_SUB : ALU_ADD;
                    F3_SLL:     alu_op = ALU_SLL;
                    F3_SLT:     alu_op = ALU_SLT;
                    F3_SLTU:    alu_op = ALU_SLTU;
                    F3_XOR:     alu_op = ALU_XOR;
                    F3_SR:      alu_op = func7[5] ? ALU_SRA : ALU_SRL;
                    F3_OR:      alu_op = ALU_OR;
                    F3_AND:     alu_op = ALU_AND;
                endcase
            end

            // I-Type Instructions
            OPCODE_ARI_I: begin
                reg_wr = 1;
                sel_B = 1;  // Use immediate
                
                case(func3)
                    F3_ADD_SUB: alu_op = ALU_ADD;
                    F3_SLL:     alu_op = ALU_SLL;
                    F3_SLT:     alu_op = ALU_SLT;
                    F3_SLTU:    alu_op = ALU_SLTU;
                    F3_XOR:     alu_op = ALU_XOR;
                    F3_SR:      alu_op = func7[5] ? ALU_SRA : ALU_SRL;
                    F3_OR:      alu_op = ALU_OR;
                    F3_AND:     alu_op = ALU_AND;
                endcase
            end

            // Load Instructions
            OPCODE_LOAD: begin
                reg_wr = 1;
                rd_en = 1;
                sel_B = 1;  // Use immediate
                wb_sel = WB_MEM;
                alu_op = ALU_ADD;  // Address calculation
            end

            // Store Instructions
            OPCODE_STORE: begin
                wr_en = 1;
                sel_B = 1;  // Use immediate
                alu_op = ALU_ADD;  // Address calculation
            end

            // Branch Instructions
            OPCODE_BRANCH: begin
                sel_A = 0;  // Use PC
                sel_B = 1;  // Use immediate
                
                case(func3)
                    3'b000: br_type = BR_EQ;   // BEQ
                    3'b001: br_type = BR_NE;   // BNE
                    3'b100: br_type = BR_LT;   // BLT
                    3'b101: br_type = BR_GE;   // BGE
                    3'b110: br_type = BR_LTU;  // BLTU
                    3'b111: br_type = BR_GEU;  // BGEU
                endcase
            end

            // LUI
            OPCODE_LUI: begin
                reg_wr = 1;
                sel_B = 1;  // Use immediate
                alu_op = ALU_PASS;  // Pass-through
            end

            // AUIPC
            OPCODE_AUIPC: begin
                reg_wr = 1;
                sel_A = 0;  // Use PC
                sel_B = 1;  // Use immediate
                alu_op = ALU_ADD;  // PC + imm
            end

            // JAL
            OPCODE_JAL: begin
                reg_wr = 1;
                sel_A = 0;  // Use PC
                sel_B = 1;  // Use immediate
                wb_sel = WB_PC;
                br_type = BR_JUMP;
                alu_op = ALU_ADD;  // PC + imm
            end

            // JALR
            OPCODE_JALR: begin
                reg_wr = 1;
                sel_B = 1;  // Use immediate
                wb_sel = WB_PC;
                br_type = BR_JUMP;
                alu_op = ALU_ADD;  // RS1 + imm
            end
        endcase
    end
endmodule