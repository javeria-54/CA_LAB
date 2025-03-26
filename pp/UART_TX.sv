module Tx_Baud_Counter (
    input  logic clk, reset,
    input  logic [11:0] baud_div,
    output logic baud_comp
);
    logic [11:0] counter;

    always_ff @(posedge clk) begin
        if (reset) begin
            baud_comp <= 1'b0;
            counter <= 12'b0;
        end
        else begin
            if (counter == baud_div) begin
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
module Tx_FIFO (
    input  logic clk, reset,
    input  logic [7:0] data_in,
    input  logic wr_en, rd_en,
    output logic [7:0] data_out,
    output logic FIFO_full, FIFO_empty
);
    logic [7:0] fifo [7:0];  // 8-entry FIFO
    logic [2:0] wr_ptr, rd_ptr;
    logic [3:0] count;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
            data_out <= 0;
            FIFO_full <= 0;
            FIFO_empty <= 1;
        end
        else begin
            // Write operation
            if (wr_en && !FIFO_full) begin
                fifo[wr_ptr] <= data_in;
                wr_ptr <= wr_ptr + 1;
                count <= count + 1;
            end
            
            // Read operation
            if (rd_en && !FIFO_empty) begin
                data_out <= fifo[rd_ptr];
                rd_ptr <= rd_ptr + 1;
                count <= count - 1;
            end
            
            // Update flags
            FIFO_full <= (count == 8);
            FIFO_empty <= (count == 0);
        end
    end
endmodule
module Tx_Controller (
    input  logic clk, reset,
    input  logic data_available,
    input  logic tx_done,
    output logic tx_start,
    output logic tx_sel
);
    typedef enum logic [1:0] {
        IDLE,
        LOAD,
        TRANSMIT
    } state_t;
    
    state_t current_state, next_state;

    // State transition logic
    always_comb begin
        case (current_state)
            IDLE:     next_state = data_available ? LOAD : IDLE;
            LOAD:     next_state = TRANSMIT;
            TRANSMIT: next_state = tx_done ? IDLE : TRANSMIT;
            default:  next_state = IDLE;
        endcase
    end

    // Output logic
    always_comb begin
        tx_start = 1'b0;
        tx_sel = 1'b0;
        
        case (current_state)
            LOAD:     tx_start = 1'b1;
            TRANSMIT: tx_sel = 1'b1;
        endcase
    end

    // State register
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
        end
        else begin
            current_state <= next_state;
        end
    end
endmodule
module Shift_Register_Tx (
    input  logic clk, reset,
    input  logic [7:0] data,
    input  logic [11:0] baud_div,
    input  logic parity_sel,
    input  logic two_stop_bits,
    input  logic tx_start,
    input  logic tx_sel,
    output logic tx_done,
    output logic tx_out
);
    logic [11:0] shift_reg;
    logic [3:0] bit_counter;
    logic tx_shift_en;
    logic parity_bit;
    
    // Baud counter reset
    logic baud_counter_reset = reset | tx_start;
    
    // Packet configuration
    localparam START_BIT = 1'b0;
    localparam STOP_BIT = 1'b1;
    
    // Parity calculation
    assign parity_bit = parity_sel ? ~(^data) : ^data;
    
    // Packet size
    wire [3:0] packet_size = two_stop_bits ? 4'd12 : 4'd11;
    
    // Shift register control
    always_ff @(posedge clk) begin
        if (reset) begin
            shift_reg <= {12{STOP_BIT}};
            bit_counter <= 0;
            tx_done <= 0;
        end
        else if (tx_start) begin
            shift_reg <= {2'b00, parity_bit, data, START_BIT};
            bit_counter <= 0;
            tx_done <= 0;
        end
        else if (tx_shift_en && tx_sel) begin
            if (bit_counter == packet_size) begin
                tx_done <= 1'b1;
            end
            else begin
                shift_reg <= {STOP_BIT, shift_reg[11:1]};
                bit_counter <= bit_counter + 1;
            end
        end
    end
    
    // Output
    assign tx_out = tx_sel ? shift_reg[0] : STOP_BIT;
    
    // Baud counter instantiation
    Tx_Baud_Counter baud_counter (
        .clk(clk),
        .reset(baud_counter_reset),
        .baud_div(baud_div),
        .baud_comp(tx_shift_en)
    );
endmodule
module UART_Tx (
    input  logic clk,
    input  logic reset,
    // Processor Interface
    input  logic wr_en,
    input  logic [7:0] data_in,
    output logic interrupt,
    // Configuration
    input  logic [11:0] baud_divisor,
    input  logic parity_sel,
    input  logic two_stop_bits,
    // Physical Interface
    output logic tx_out,
    // Status Flags
    output logic fifo_full,
    output logic fifo_empty
);
    // Internal signals
    logic [7:0] fifo_data_out;
    logic tx_start, tx_sel, tx_done;
    logic data_available;
    logic tx_fifo_rd;
    
    // FIFO Instantiation
    Tx_FIFO fifo (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .wr_en(wr_en),
        .rd_en(tx_fifo_rd),
        .data_out(fifo_data_out),
        .FIFO_full(fifo_full),
        .FIFO_empty(fifo_empty)
    );
    
    // Controller Instantiation
    Tx_Controller controller (
        .clk(clk),
        .reset(reset),
        .data_available(data_available),
        .tx_done(tx_done),
        .tx_start(tx_start),
        .tx_sel(tx_sel)
    );
    
    // Shift Register Instantiation
    Shift_Register_Tx shift_reg (
        .clk(clk),
        .reset(reset),
        .data(fifo_data_out),
        .baud_div(baud_divisor),
        .parity_sel(parity_sel),
        .two_stop_bits(two_stop_bits),
        .tx_start(tx_start),
        .tx_sel(tx_sel),
        .tx_done(tx_done),
        .tx_out(tx_out)
    );
    
    // Interrupt Logic
    assign data_available = !fifo_empty;
    assign tx_fifo_rd = tx_start;
    assign interrupt = fifo_empty | tx_done;
endmodule