module System_Bus (
    input        clk,
    input        reset,
    // Processor interface
    input [31:0] address,
    input [31:0] data_in,
    input        rd_en,
    input        wr_en,
    output reg [31:0] data_out,
    // UART physical interface
    output       UART_Tx,
    input        UART_Rx
);
    // Configuration parameters
    localparam UART_BAUD_DIV = 104; // 9600 baud @ 100MHz (100000000/(16*9600))
    localparam UART_PARITY_EN = 0;
    localparam UART_TWO_STOP = 0;

    // UART interface signals
    wire [7:0] uart_rx_data;
    wire uart_tx_interrupt;
    wire uart_rx_ready;
    wire uart_tx_full, uart_tx_empty;
    wire uart_rx_full, uart_rx_empty;
    wire uart_frame_error;
    wire uart_overflow;

    // Address decoding
    wire uart_sel = (address >= 32'h0000_3000) && (address < 32'h0000_4000);
    wire uart_wr_en = uart_sel & wr_en;
    wire uart_rd_en = uart_sel & rd_en;

    // UART Transmitter instance
    UART_Tx uart_tx_inst (
        .clk(clk),
        .reset(reset),
        .wr_en(uart_wr_en),
        .data_in(data_in[7:0]),
        .interrupt(uart_tx_interrupt),
        .baud_divisor(UART_BAUD_DIV),
        .parity_sel(UART_PARITY_EN),
        .two_stop_bits(UART_TWO_STOP),
        .tx_out(UART_Tx),
        .fifo_full(uart_tx_full),
        .fifo_empty(uart_tx_empty)
    );

    // UART Receiver instance
    UART_Rx uart_rx_inst (
        .clk(clk),
        .reset(reset),
        .baud_divisor(UART_BAUD_DIV),
        .parity_en(UART_PARITY_EN),
        .two_stop_bits(UART_TWO_STOP),
        .rx_in(UART_Rx),
        .rx_data(uart_rx_data),
        .rd_en(uart_rd_en),
        .data_ready(uart_rx_ready),
        .frame_error(uart_frame_error),
        .fifo_full(uart_rx_full),
        .fifo_empty(uart_rx_empty),
        .overflow(uart_overflow)
    );

    // Read data mux
    always @(*) begin
        if (uart_sel && rd_en) begin
            data_out = {24'b0, uart_rx_data};  // Zero-extend 8-bit UART data
        end
        else begin
            data_out = 32'b0;  // Default output
        end
    end

    // Status monitoring
    always @(posedge clk) begin
        if (reset) begin
            // Reset monitoring logic if needed
        end
        else begin
            // Report UART errors
            if (uart_frame_error)
                $display("[%0t] UART Frame Error", $time);
            if (uart_overflow)
                $display("[%0t] UART Overflow", $time);
            
            // Warn about FIFO conditions
            if (uart_wr_en && uart_tx_full)
                $display("[%0t] UART Tx FIFO Full", $time);
            if (uart_rd_en && uart_rx_empty)
                $display("[%0t] UART Rx FIFO Empty", $time);
        end
    end
endmodule