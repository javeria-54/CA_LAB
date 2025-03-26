module ALU(
	input logic [3:0] alu_op,
	input logic [31:0] A,B,
	output logic [31:0] C
);

	always_comb begin
        case (alu_op)
            4'b0000: C = A + B; // ADD
            4'b0001: C = A - B; // SUB
            4'b0010: C = A << B[4:0]; // SLL    
            4'b0011: C = A >> B[4:0]; // SRL
            4'b0100: C = $signed(A) >>> B[4:0]; // SRA
            4'b0101: C = ($signed(A) < $signed(B)) ? 1 : 0; // SLT
            4'b0110: C = (A < B) ? 1 : 0; // SLTU
            4'b0111: C = A ^ B; // XOR
            4'b1000: C = A | B; // OR
            4'b1001: C = A & B; // AND
            4'b1010: C = B; // Just Pass B
        
            default: C = 32'b0;
        endcase
    end

endmodule