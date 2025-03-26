module d_flipflop2(
    input logic clk,reset,a1,a2,a3,
    input logic[1:0] a4,
    output logic b1,b2,b3,
    output logic[1:0] b4
);
always_ff @( posedge clk ) begin
    if(reset) begin
        b1 <= 1'b0;
        b2 <= 1'b0;
        b3 <= 1'b0;
        b4 <= 2'b0; 
    end
    else begin   
        b1 <= a1;
        b2 <= a2;
        b3 <= a3;
        b4 <= a4;
    end
end


endmodule