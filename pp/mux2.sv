module mux_2(
    input logic s,
    input logic [31:0] a0,a1,
    output logic [31:0] y
);
    always_comb begin
        case(s)
        1'h0:  y = a0;
        1'h1:  y = a1;
        endcase
    end 

endmodule