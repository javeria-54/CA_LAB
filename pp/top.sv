module top( 
    input logic clk, reset,
    // UART interface
    input  logic UART_Rx,
    output logic UART_Tx
);
    // =============================================
    // IF STAGE (Instruction Fetch)
    // =============================================
    logic [31:0] br_a, br_b, br_y;
    logic br_sel;
    mux_2 M_BR(br_sel, br_a, br_b, br_y);  // Branch selection mux

    logic [31:0] pc;
    Program_Counter PC0(clk, reset, br_y, pc);  // PC update

    logic [31:0] instruction;
    Instruction_Memory IM0(pc, instruction);  // Instruction memory

    // =============================================
    // IF/ID PIPELINE REGISTER
    // =============================================
    logic mim_sel;
    logic [31:0] instruction0;
    mux_2 M_IM(mim_sel, instruction, 32'h00000013, instruction0);  // NOP insertion for stalls

    logic [31:0] pc1, instruction1;
    d_flipflop D_PC1(clk, reset, pc, pc1);           // PC pipeline reg
    d_flipflop D_IR1(clk, reset, instruction0, instruction1);  // IR pipeline reg

    // =============================================
    // ID STAGE (Instruction Decode)
    // =============================================
    // Control signals generation
    logic reg_wr, rd_en, wr_en, sel_A, sel_B, sel_pA, sel_pB;
    logic [1:0] wb_sel;
    logic [2:0] br_type;
    logic [3:0] alu_op;
    logic [31:0] instruction2;
    Controller C0(
        instruction1, instruction2,  // Current and previous instructions
        reg_wr, rd_en, wr_en,       // Register/memory write enables
        sel_A, sel_B,               // ALU input select
        sel_pA, sel_pB,             // Forwarding mux selects
        wb_sel,                     // Writeback select
        br_type,                    // Branch type
        alu_op                      // ALU operation
    );

    // Immediate generation
    logic [31:0] imm_val;
    Immediate_Generator IG0(instruction1, imm_val);

    // Register file access
    logic reg_wr1;
    logic [31:0] rdata1, rdata2, rf_in;
    logic [4:0] rs1, rs2, rsd;
    Register_File RF0(
        clk, reset, reg_wr1,
        rs1, rs2, rsd,             // Read/write addresses
        rf_in,                     // Write data
        rdata1, rdata2             // Read data
    );

    // =============================================
    // FORWARDING LOGIC (Hazard Detection Unit)
    // =============================================
    logic [31:0] m_in2, pa_out, pb_out;
    mux_2 P_A(sel_pA, rdata1, m_in2, pa_out);  // Forwarding mux for operand A
    mux_2 P_B(sel_pB, rdata2, m_in2, pb_out);  // Forwarding mux for operand B

    // =============================================
    // ID/EX PIPELINE REGISTER
    // =============================================
    logic [31:0] ma_y, mb_y;
    mux_2 M_A(sel_A, pc1, pa_out, ma_y);  // ALU input A: PC or register
    mux_2 M_B(sel_B, pb_out, imm_val, mb_y);  // ALU input B: register or immediate

    // =============================================
    // EX STAGE (Execute)
    // =============================================
    logic [31:0] alu_out;
    ALU ALU0(alu_op, ma_y, mb_y, alu_out);  // Main ALU

    // Branch condition evaluation
    logic br_taken;
    Branch_Condition B0(br_type, pa_out, pb_out, br_taken);

    // =============================================
    // EX/MEM PIPELINE REGISTER
    // =============================================
    logic [31:0] pc2, alu_out1, pb_out1;
    d_flipflop D_PC2(clk, reset, pc1, pc2);            // PC pipeline reg
    d_flipflop D_ALU(clk, reset, alu_out, alu_out1);   // ALU result pipeline reg
    d_flipflop D_WD(clk, reset, pb_out, pb_out1);      // Store data pipeline reg
    d_flipflop D_IR2(clk, reset, instruction1, instruction2);  // IR pipeline reg

    // Control signals pipeline
    logic wr_en1, rd_en1;
    logic [1:0] wb_sel1;
    d_flipflop2 D_CN1(
        clk, reset, 
        reg_wr, wr_en, rd_en, wb_sel,  // Input control signals
        reg_wr1, wr_en1, rd_en1, wb_sel1  // Pipeline control signals
    );

    // =============================================
    // MEM STAGE (Memory Access)
    // =============================================
    // Memory address decoding
    logic [31:0] data_out;
    logic imem_sel, dmem_sel, uart_sel, mem_error;
    LSU LSU0(
        .address(alu_out1),
        .rd_en(rd_en1),
        .wr_en(wr_en1),
        .imem_sel(imem_sel),
        .dmem_sel(dmem_sel),
        .uart_sel(uart_sel),
        .mem_error(mem_error)
    );

    // Data memory access
    Data_Memory D0(
        clk, reset, 
        wr_en1 & dmem_sel,   // Write enable (gated with select)
        rd_en1 & dmem_sel,   // Read enable (gated with select)
        alu_out1,            // Address
        pb_out1,             // Write data
        data_out             // Read data
    );

    // UART interface
    logic [7:0] uart_rx_data;
    logic uart_wr_en = wr_en1 & uart_sel;
    System_Bus SB0(
        .clk(clk),
        .reset(reset),
        .address(alu_out1),
        .data_in(pb_out1[7:0]),  // Only lower 8 bits for UART
        .rd_en(rd_en1 & uart_sel),
        .wr_en(uart_wr_en),
        .data_out(uart_rx_data),
        .UART_Tx(UART_Tx),
        .UART_Rx(UART_Rx)
    );

    // =============================================
    // MEM/WB PIPELINE REGISTER
    // =============================================
    // Writeback stage mux
    logic [31:0] wdata;
    mux_4 M_WB(
        wb_sel1,                     // Select signal
        pc2 + 4,                     // PC+4 (for jumps)
        alu_out1,                    // ALU result
        dmem_sel ? data_out : {24'b0, uart_rx_data},  // Memory or UART data
        32'b0,                       // Zero (unused)
        wdata                        // Writeback data
    );

    // =============================================
    // WB STAGE (Writeback)
    // =============================================
    // Combinational logic
    always_comb begin
        // Next PC calculation
        br_a = pc + 4;               // Default PC+4
        br_b = alu_out;              // Branch target
        br_sel = br_taken;           // Branch select
        
        // Register file inputs
        rf_in = wdata;               // Writeback data
        rs1 = instruction1[19:15];   // rs1 field
        rs2 = instruction1[24:20];   // rs2 field
        rsd = instruction2[11:7];    // Destination register
        
        // Forwarding paths
        m_in2 = wdata;               // Forwarded writeback data
        
        // Stall insertion (bubble injection)
        mim_sel = br_taken;          // Insert NOP on branch
    end

endmodule