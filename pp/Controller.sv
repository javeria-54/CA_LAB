module Controller (
    input logic [31:0] inst,        // Current instruction
    input logic [31:0] inst1,       // Previous instruction (for forwarding)
    output logic reg_wr,            // Register write enable
    output logic rd_en,             // Memory read enable
    output logic wr_en,             // Memory write enable
    output logic sel_A,             // ALU input A select
    output logic sel_B,             // ALU input B select
    output logic sel_pA,            // Forwarding for operand A
    output logic sel_pB,            // Forwarding for operand B
    output logic [1:0] wb_sel,      // Writeback source select
    output logic [2:0] br_type,     // Branch type
    output logic [3:0] alu_op       // ALU operation
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
        sel_A = 0;
        sel_B = 0;
        wb_sel = 2'b00;
        br_type = 3'b000;
        alu_op = 4'b0000;


        case(opcode)
            // R-Type Instructions
            7'b0110011: begin
                reg_wr = 1;
                sel_A = 1;
                sel_B = 0;
                wb_sel = 2'b01;
                
                case(func3)
                    3'b000: alu_op = func7[5] ? 4'b0001 : 4'b0000; // SUB/ADD
                    3'b001: alu_op = 4'b0010; // SLL
                    3'b010: alu_op = 4'b0101; // SLT
                    3'b011: alu_op = 4'b0110; // SLTU
                    3'b100: alu_op = 4'b0111; // XOR
                    3'b101: alu_op = func7[5] ? 4'b0100 : 4'b0011; // SRA/SRL
                    3'b110: alu_op = 4'b1000; // OR
                    3'b111: alu_op = 4'b1001; // AND
                endcase
            end

            // I-Type Instructions
            7'b0010011: begin
                reg_wr = 1;
                sel_A = 1;
                sel_B = 1;
                wb_sel = 2'b01;
                
                case(func3)
                    3'b000: alu_op = 4'b0000; // ADDI
                    3'b001: alu_op = 4'b0010; // SLLI
                    3'b010: alu_op = 4'b0101; // SLTI
                    3'b011: alu_op = 4'b0110; // SLTIU
                    3'b100: alu_op = 4'b0111; // XORI
                    3'b101: alu_op = func7[5] ? 4'b0100 : 4'b0011; // SRAI/SRLI
                    3'b110: alu_op = 4'b1000; // ORI
                    3'b111: alu_op = 4'b1001; // ANDI
                endcase
            end

            // Load Instructions
            7'b0000011: begin
                reg_wr = 1;
                rd_en = 1;
                sel_A = 1;
                sel_B = 1;
                wb_sel = 2'b11;
       
                alu_op = 4'b0000; // ADD for address calculation
            end

            // Store Instructions
            7'b0100011: begin
                wr_en = 1;
                sel_A = 1;
                sel_B = 1;
       
                alu_op = 4'b0000; // ADD for address calculation
            end

            // Branch Instructions
            7'b1100011: begin
                sel_A = 0; // PC
                sel_B = 1; // Immediate
                alu_op = 4'b0000;
                
                case(func3)
                    3'b000: br_type = 3'b001; // BEQ
                    3'b001: br_type = 3'b010; // BNE
                    3'b100: br_type = 3'b011; // BLT
                    3'b101: br_type = 3'b100; // BGE
                    3'b110: br_type = 3'b101; // BLTU
                    3'b111: br_type = 3'b110; // BGEU
                endcase
            end

            // LUI
            7'b0110111: begin
                reg_wr = 1;
                sel_B = 1;
                wb_sel = 2'b01;
                alu_op = 4'b1010; // Pass-through
            end

            // AUIPC
            7'b0010111: begin
                reg_wr = 1;
                sel_A = 0; // PC
                sel_B = 1; // Immediate
                wb_sel = 2'b01;
                alu_op = 4'b0000; // ADD
            end

            // JAL
            7'b1101111: begin
                reg_wr = 1;
                sel_A = 0; // PC
                sel_B = 1; // Immediate
                wb_sel = 2'b00;
                br_type = 3'b111; // Jump
                alu_op = 4'b0000; // ADD
            end

            // JALR
            7'b1100111: begin
                reg_wr = 1;
                sel_A = 1; // RS1
                sel_B = 1; // Immediate
                wb_sel = 2'b00;
                br_type = 3'b111; // Jump
                alu_op = 4'b0000; // ADD
            end
        endcase
    end
endmodule