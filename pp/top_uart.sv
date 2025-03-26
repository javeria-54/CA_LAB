module UART_Top (
    input         clk,
    input         reset_n,        // Active-low reset
    // Configuration
    input  [11:0] baud_div,       // Baud rate divisor (for 16x oversampling)
    input         parity_en,      // 1: Enable parity, 0: Disable
    input         two_stop,       // 1: Two stop bits, 0: One stop bit
    // Transmitter Interface
    input  [7:0]  tx_data,        // Data to transmit
    input         tx_wr_en,       // Write enable for TX FIFO
    output        tx_full,        // TX FIFO full flag
    output        tx_empty,       // TX FIFO empty flag
    output        tx_out,         // Serial transmit output
    output        tx_interrupt,   // TX interrupt (ready for data)
    // Receiver Interface
    input         rx_in,          // Serial receive input
    output [7:0]  rx_data,        // Received data
    output        rx_full,        // RX FIFO full flag
    output        rx_empty,       // RX FIFO empty flag
    input         rx_rd_en,       // Read enable for RX FIFO
    output        rx_interrupt,   // RX interrupt (data available)
    // Error Indicators
    output        rx_frame_error, // Frame error (parity/stop bit)
    output        rx_overflow     // RX FIFO overflow
);
    // Convert reset polarity
    logic reset;
    assign reset = !reset_n;

    // Instantiate Transmitter
    UART_Tx uart_tx (
        .clk(clk),
        .reset(reset),
        // Processor Interface
        .wr_en(tx_wr_en),
        .data_in(tx_data),
        .interrupt(tx_interrupt),
        // Configuration
        .baud_divisor(baud_div),
        .parity_sel(parity_en),
        .two_stop_bits(two_stop),
        // Physical Interface
        .tx_out(tx_out),
        // Status Flags
        .fifo_full(tx_full),
        .fifo_empty(tx_empty)
    );

    // Instantiate Receiver
    UART_Rx uart_rx (
        .clk(clk),
        .reset(reset),
        // Physical Interface
        .rx_in(rx_in),
        // Processor Interface
        .data_out(rx_data),
        .rd_en(rx_rd_en),
        .interrupt(rx_interrupt),
        // Configuration
        .baud_divisor(baud_div),
        .parity_sel(parity_en),
        .two_stop_bits(two_stop),
        // Status Flags
        .fifo_full(rx_full),
        .fifo_empty(rx_empty),
        // Error Indicators
        .frame_error(rx_frame_error),
        .overflow(rx_overflow)
    );

    // Optional: Loopback mode for testing
     assign rx_in = tx_out;  // Uncomment for loopback testing

endmodule