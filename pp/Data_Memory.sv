module Data_Memory(
    input logic clk,reset,wr_en,rd_en,
    input logic [31:0] address,wdata,
    output logic [31:0] rdata
    );

    logic [31:0] data_memory [0:1023];
    
    always_ff @ (negedge clk) begin
        if (wr_en)
            data_memory[address] <= wdata;
    end

    always_comb begin
        if (rd_en)
            rdata = data_memory[address];
        else 
            rdata <= 32'b0;
    end

endmodule