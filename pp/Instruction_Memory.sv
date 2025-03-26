module Instruction_Memory(
    input logic [31:0] address,
    output logic [31:0] instruction
);
    logic [31:0] instruction_memory [0:1023];

    initial begin
	$readmemh("D:/6th semester/CA LAB/single cycle/xyz/build/main.txt", instruction_memory);
	end

    assign instruction = instruction_memory[address[11:2]];

endmodule




