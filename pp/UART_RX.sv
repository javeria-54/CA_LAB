module Rx_Baud_Counter (
    input  logic clk, reset,
    input  logic [11:0] baud_div,  // 16x oversampling rate              
    output logic baud_comp
);
    logic [11:0] counter;

    always_ff @(posedge clk) begin
        if (reset) begin       
            baud_comp <= 1'b0;
            counter <= 12'b0;
        end
        else begin
            if (counter == baud_div[11:1]) begin  // Count to half for mid-bit sampling
                baud_comp <= 1'b1;
                counter <= 12'b0;
            end
            else begin            
                baud_comp <= 1'b0;
                counter <= counter + 1;
            end
        end
    end
endmodule
module Rx_Controller (
    input  logic clk, reset,
    input  logic start_detected, rx_done,
    input  logic parity_error, stop_bit_error,
    output logic rx_start, rx_sel, store_en,
    output logic frame_error  // New error output
);
    typedef enum logic [1:0] {
        IDLE,
        START,
        RECEIVE,
        STORE
    } state_t;
    
    state_t c_state, n_state;
    logic error_detected;

    // State transition
    always_comb begin
        n_state = c_state;
        case (c_state)
            IDLE:    if (start_detected) n_state = START;
            START:   n_state = RECEIVE;
            RECEIVE: if (rx_done) n_state = error_detected ? IDLE : STORE;
            STORE:   n_state = IDLE;
        endcase
    end

    // Output logic
    always_comb begin
        rx_start = 1'b0;
        rx_sel = 1'b1;
        store_en = 1'b0;
        frame_error = 1'b0;
        
        case (c_state)
            START:   rx_start = 1'b1;
            RECEIVE: if (error_detected) frame_error = 1'b1;
            STORE:   begin
                rx_sel = 1'b0;
                store_en = 1'b1;
            end
        endcase
    end

    // Error detection
    assign error_detected = parity_error || stop_bit_error;

    // State register
    always_ff @(posedge clk) begin
        if (reset) c_state <= IDLE;
        else c_state <= n_state;
    end
endmodule
module Shift_Register_RX (
    input  logic clk, reset,
    input  logic rx_in,
    input  logic [11:0] baud_divisor,
    input  logic parity_sel, two_stop_bits, rx_start, rx_sel,
    output logic rx_done, start_detected,
    output logic parity_error, stop_bit_error,
    output logic [7:0] data_out
);
    logic [10:0] shift_reg;  // Reduced to 11 bits (1 start + 8 data + 1 parity + 1 stop)
    logic [3:0] bit_counter;
    logic rx_shift_en, sampled_bit;
    
    // Sampling at mid-bit (16x oversampling)
    always_ff @(posedge clk) begin
        if (rx_shift_en)
            sampled_bit <= rx_in;
    end

    // Shift register control
    always_ff @(posedge clk) begin
        if (reset || rx_start) begin
            shift_reg <= '0;
            bit_counter <= two_stop_bits ? 4'd10 : 4'd9;
            rx_done <= 1'b0;
        end
        else if (rx_shift_en) begin
            if (bit_counter == 0) begin
                rx_done <= 1'b1;
            end
            else begin
                shift_reg <= {sampled_bit, shift_reg[10:1]};
                bit_counter <= bit_counter - 1;
            end
        end
    end

    // Error detection
    always_comb begin
        parity_error = parity_sel ? (^shift_reg[8:1] != shift_reg[9]) : 0;
        stop_bit_error = !shift_reg[0];  // First stop bit
        if (two_stop_bits) stop_bit_error |= !shift_reg[10];  // Second stop bit
    end

    // Outputs
    assign start_detected = !rx_in;  // Start bit detection
    assign data_out = shift_reg[8:1];
    
    // Baud counter (now with 16x oversampling)
    Rx_Baud_Counter baud_counter (
        .clk(clk),
        .reset(reset | rx_start),
        .baud_div(baud_divisor),
        .baud_comp(rx_shift_en)
    );
endmodule
module Rx_FIFO (
    input  logic clk, reset,
    input  logic [7:0] data_in,
    input  logic wr_en, rd_en,
    output logic [7:0] data_out,
    output logic full, empty,
    output logic overflow  // New overflow indicator
);
    logic [7:0] fifo [7:0];
    logic [2:0] wr_ptr, rd_ptr;
    logic [3:0] count;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
            data_out <= 0;
            full <= 0;
            empty <= 1;
            overflow <= 0;
        end
        else begin
            overflow <= wr_en && full;  // Capture overflow events
            
            if (wr_en && !full) begin
                fifo[wr_ptr] <= data_in;
                wr_ptr <= wr_ptr + 1;
                count <= count + 1;
            end
            
            if (rd_en && !empty) begin
                data_out <= fifo[rd_ptr];
                rd_ptr <= rd_ptr + 1;
                count <= count - 1;
            end
            
            full <= (count == 8);
            empty <= (count == 0);
        end
    end
endmodule
module UART_Rx (
    input  logic clk, reset,
    // Configuration
    input  logic [11:0] baud_divisor,
    input  logic parity_en, two_stop_bits,
    // Physical Interface
    input  logic rx_in,
    // Processor Interface
    output logic [7:0] rx_data,
    input  logic rd_en,
    output logic data_ready,
    output logic frame_error,
    output logic fifo_full,
    output logic fifo_empty,
    output logic overflow
);
    // Internal signals
    logic [7:0] fifo_data_in;
    logic fifo_wr;
    logic parity_error, stop_bit_error;
    logic start_detected, rx_done;

    // FIFO Instantiation
    Rx_FIFO rx_fifo (
        .clk(clk),
        .reset(reset),
        .data_in(fifo_data_in),
        .wr_en(fifo_wr),
        .rd_en(rd_en),
        .data_out(rx_data),
        .full(fifo_full),
        .empty(fifo_empty),
        .overflow(overflow)
    );

    // Datapath
    Shift_Register_RX datapath (
        .clk(clk),
        .reset(reset),
        .rx_in(rx_in),
        .baud_divisor(baud_divisor),
        .parity_sel(parity_en),
        .two_stop_bits(two_stop_bits),
        .rx_start(),
        .rx_sel(1'b1),
        .rx_done(rx_done),
        .start_detected(start_detected),
        .parity_error(parity_error),
        .stop_bit_error(stop_bit_error),
        .data_out(fifo_data_in)
    );

    // Controller
    Rx_Controller controller (
        .clk(clk),
        .reset(reset),
        .start_detected(start_detected),
        .rx_done(rx_done),
        .parity_error(parity_error),
        .stop_bit_error(stop_bit_error),
        .rx_start(),
        .rx_sel(),
        .store_en(fifo_wr),
        .frame_error(frame_error)
    );

    // Status
    assign data_ready = !fifo_empty;
endmodule