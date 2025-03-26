module LSU (
    input [31:0] address,
    input rd_en, wr_en,
    output logic imem_sel, dmem_sel, uart_sel,
    output logic mem_error
);

    // Address ranges using enum
    typedef enum logic [31:0] {
        IMEM_START = 32'h0000_0000,
        IMEM_END   = 32'h0000_0FFF,
        DMEM_START = 32'h0000_1000,
        DMEM_END   = 32'h0000_2FFF,
        UART_START = 32'h0000_3000,
        UART_END   = 32'h0000_3FFF
    } mem_map_t;

    always_comb begin
        // Default values
        imem_sel = 1'b0;
        dmem_sel = 1'b0;
        uart_sel = 1'b0;
        mem_error = 1'b0;

        // Address decoding using enum values
        if (address >= IMEM_START && address <= IMEM_END) begin
            imem_sel = 1'b1;
        end
        else if (address >= DMEM_START && address <= DMEM_END) begin
            dmem_sel = 1'b1;
        end
        else if (address >= UART_START && address <= UART_END) begin
            uart_sel = 1'b1;
        end

        // Error check
        mem_error = (rd_en | wr_en) & !(imem_sel | dmem_sel | uart_sel);
    end
endmodule