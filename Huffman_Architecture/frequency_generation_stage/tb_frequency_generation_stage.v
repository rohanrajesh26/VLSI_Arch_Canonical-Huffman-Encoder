`timescale 1ns/1ps

module tb_frequency_generation_stage;

    //----------------------------------------------------------------------------
    // Dump for GTKWave
    //----------------------------------------------------------------------------
    initial begin
        // Name of the VCD file
        $dumpfile("frequency_generation_stage.vcd");
        // Dump everything in this module hierarchy
        $dumpvars(0, tb_frequency_generation_stage);
    end

    // Parameters
    parameter SYMBOL_WIDTH = 5;
    parameter FREQ_WIDTH   = 32;
    parameter NUM_CELLS    = 16;
    parameter CLK_PERIOD   = 10;

    // Signals
    reg clk;
    reg reset;
    reg [SYMBOL_WIDTH-1:0] symbol_in;
    reg valid_in;
    wire ready_in;
    wire [NUM_CELLS*FREQ_WIDTH-1:0]   sorted_frequencies;
    wire [NUM_CELLS*SYMBOL_WIDTH-1:0] sorted_symbols;
    wire sorted_done;

    // Instantiate the DUT
    frequency_generation_stage #(
        .SYMBOL_WIDTH(SYMBOL_WIDTH),
        .FREQ_WIDTH(FREQ_WIDTH),
        .NUM_CELLS(NUM_CELLS)
    ) dut (
        .clk(clk),
        .reset(reset),
        .symbol_in(symbol_in),
        .valid_in(valid_in),
        .ready_in(ready_in),
        .sorted_frequencies(sorted_frequencies),
        .sorted_symbols(sorted_symbols),
        .sorted_done(sorted_done)
    );

    // Clock generation
    always #(CLK_PERIOD/2) clk = ~clk;

    // Test stimulus
    initial begin
        // Initialize signals
        clk       = 0;
        reset     = 1;
        valid_in  = 0;
        symbol_in = 0;
        #20;
        reset = 0;
        #10;

        // mississippi sequence
        symbol_in = 0; valid_in = 1; #10; valid_in = 0; #10; // m
        symbol_in = 1; valid_in = 1; #10; valid_in = 0; #10; // i
        symbol_in = 2; valid_in = 1; #10; valid_in = 0; #10; // s
        symbol_in = 2; valid_in = 1; #10; valid_in = 0; #10; // s
        symbol_in = 1; valid_in = 1; #10; valid_in = 0; #10; // i
        symbol_in = 2; valid_in = 1; #10; valid_in = 0; #10; // s
        symbol_in = 2; valid_in = 1; #10; valid_in = 0; #10; // s
        symbol_in = 1; valid_in = 1; #10; valid_in = 0; #10; // i
        symbol_in = 3; valid_in = 1; #10; valid_in = 0; #10; // p
        symbol_in = 3; valid_in = 1; #10; valid_in = 0; #10; // p
        symbol_in = 1; valid_in = 1; #10; valid_in = 0; #10; // i

        // Wait for sorting to complete
        wait (sorted_done);
        #50;

        // Display results
        $display("Sorting completed. Sorted Symbols and Frequencies:");
        for (integer i = 0; i < NUM_CELLS; i = i + 1) begin
            $display("Cell %2d: Symbol=%2d, Freq=%d",
                     i,
                     sorted_symbols[i*SYMBOL_WIDTH +: SYMBOL_WIDTH],
                     sorted_frequencies[i*FREQ_WIDTH +: FREQ_WIDTH]);
        end
        $finish;
    end

    // Monitor
    initial begin
        $monitor("Time=%0t reset=%b valid_in=%b ready_in=%b symbol_in=%d sorted_done=%b",
                 $time, reset, valid_in, ready_in, symbol_in, sorted_done);
    end

endmodule
