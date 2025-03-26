module d_flipflop(
    input logic clk,reset,
    input logic [31:0] q_in,
    output logic [31:0] q_out
);

always_ff @(posedge clk) begin
    if(reset)
        q_out <= 32'b0;
    else 
        q_out <= q_in;
end


endmodule