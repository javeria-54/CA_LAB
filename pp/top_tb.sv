`timescale 1ns/1ps

module tb_top();
    // Clock and Reset
    logic clk;
    logic reset;
    
    // UART Interface
    logic UART_Rx;
    logic UART_Tx;
    
    // Instantiate the processor
    top DUT (
        .clk(clk),
        .reset(reset),
        .UART_Rx(UART_Rx),
        .UART_Tx(UART_Tx)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end
    
    // Test sequence
    initial begin
        // Initialize inputs
        reset = 1;
        UART_Rx = 1; // UART idle state
        
        // Reset sequence
        #20;
        reset = 0;
        #10;
        
        $display("Starting simulation at time %0t", $time);
        
        // Monitor important signals
        $monitor("Time=%0t PC=%h Instruction=%h", $time, DUT.pc, DUT.instruction);
        
        // Run for enough cycles to complete the program
        #2000; // Adjust based on your program length
        
        // Check final register values
        $display("Final Register Values:");
        $display("a (x10) = %d", DUT.RF0.registers[10]);
        $display("b (x11) = %d", DUT.RF0.registers[11]);
        $display("c (x12) = %d", DUT.RF0.registers[12]);
        $display("d (x13) = %d", DUT.RF0.registers[13]);
        $display("e (x14) = %d", DUT.RF0.registers[14]);
        $display("f (x15) = %d", DUT.RF0.registers[15]);
        
        // Check memory contents if needed
        $display("Memory[0] = %h", DUT.D0.data_memory[0]);
        
        $finish;
    end
    
    // VCD dumping for waveform viewing
    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_top);
    end
    
    // UART Receiver Simulation
    initial begin
        // Wait for processor to initialize
        #100;
        
        // Simulate UART receive if needed
        // Example: Send character 'A' (0x41)
        UART_Rx = 0; // Start bit
        #8680;       // 115200 baud rate = 8.68us per bit
        
        // Data bits (LSB first)
        UART_Rx = 1; // Bit 0
        #8680;
        UART_Rx = 0; // Bit 1
        #8680;
        UART_Rx = 0; // Bit 2
        #8680;
        UART_Rx = 0; // Bit 3
        #8680;
        UART_Rx = 0; // Bit 4
        #8680;
        UART_Rx = 1; // Bit 5
        #8680;
        UART_Rx = 0; // Bit 6
        #8680;
        UART_Rx = 0; // Bit 7
        #8680;
        
        UART_Rx = 1; // Stop bit
        #8680;
    end
    
    // Automatic checking of results
    always @(posedge clk) begin
        // Add specific checks here
        // Example: When instruction is at specific address, check values
        if (DUT.pc == 32'h40) begin
            if (DUT.RF0.registers[10] != 5)
                $error("Register a (x10) should be 5");
        end
        
        // Check for program completion (infinite loop)
        if (DUT.instruction1 == 32'h0000006f) begin // JAL x0, 0
            $display("Program entered infinite loop at time %0t", $time);
            // Add final checks here
        end
    end
endmodule