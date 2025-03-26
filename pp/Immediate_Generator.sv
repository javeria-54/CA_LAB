module Immediate_Generator(
    input logic [31:0] instruction,
    output logic [31:0] imm_value
    );
    logic [6:0] opcode;
    
always_comb begin
    opcode = instruction[6:0];
    case(opcode)
        //S-TYPE
        7'b0100011 : imm_value = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
        //R-TYPE
        7'b0110011 : imm_value = 32'b0;
        //J-TYPE
        7'b1101111 : imm_value = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
        //B-TYPE
        7'b1100011 : imm_value = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
        //U-TYPE
        7'b0110111 : imm_value = {instruction[31:12], 12'b0};
        //AUPIC
        7'b0010111 : imm_value = {instruction[31:12], 12'b0};
        //I-TYPE(Load)
        7'b0000011 : imm_value = {{20{instruction[31]}},instruction[31:20]};
        //I-TYPE
        7'b0010011 : imm_value = {{20{instruction[31]}},instruction[31:20]};
    endcase
end


endmodule