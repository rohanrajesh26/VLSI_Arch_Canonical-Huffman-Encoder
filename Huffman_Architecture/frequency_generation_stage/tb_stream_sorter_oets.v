`timescale 1ns/1ps
module tb_stream_sorter_oets;
    parameter SYMBOLS = 16;
    parameter FREQ_WIDTH = 32;
    parameter SYMBOL_WIDTH = 5;
    parameter CLK_PERIOD = 10;
    
    reg clk;
    reg reset;
    reg [SYMBOL_WIDTH-1:0] symbol_in;
    reg valid_in;
    wire ready_in;
    wire [SYMBOLS*FREQ_WIDTH-1:0] sorted_frequencies_flat;
    wire [SYMBOLS*SYMBOL_WIDTH-1:0] sorted_symbol_flat;
    wire sorted_done;
    
    integer i;
    integer count;
    
    // Fixed input stream: 0, 0, 1, 1, 2, 2, 3, 3, 4, 5, 6, 7, 8, 9, 10, 11
    reg [SYMBOL_WIDTH-1:0] input_seq [0:15];
    
    stream_sorter_oets #(
        .SYMBOLS(SYMBOLS),
        .FREQ_WIDTH(FREQ_WIDTH),
        .SYMBOL_WIDTH(SYMBOL_WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .symbol_in(symbol_in),
        .valid_in(valid_in),
        .ready_in(ready_in),
        .sorted_frequencies_flat(sorted_frequencies_flat),
        .sorted_symbol_flat(sorted_symbol_flat),
        .sorted_done(sorted_done)
    );
    
    // Clock generation.
    always #(CLK_PERIOD/2) clk = ~clk;
    
    initial begin
        clk = 0;
        reset = 1;
        valid_in = 0;
        symbol_in = 0;
        
        // Initialize the fixed input sequence.
        input_seq[0] = 0;
        input_seq[1] = 15;
        input_seq[2] = 1;
        input_seq[3] = 1;
        input_seq[4] = 2;
        input_seq[5] = 2;
        input_seq[6] = 3;
        input_seq[7] = 3;
        input_seq[8] = 4;
        input_seq[9] = 5;
        input_seq[10] = 6;
        input_seq[11] = 7;
        input_seq[12] = 8;
        input_seq[13] = 9;
        input_seq[14] = 0;
        input_seq[15] = 0;
        
        #20;
        reset = 0;
        
        // Feed one input per clock cycle.
        for (count = 0; count < 16; count = count + 1) begin
            @(posedge clk);
            valid_in = 1;
            symbol_in = input_seq[count];
        end
        // Extra cycle so the last input (symbol 11)` is properly latched.
        @(posedge clk);
        valid_in = 0;
        
        // Wait for sorted_done
        wait (sorted_done);
        
        // Display the final sorted results.
        $display("Final Sorted Results (Ascending Order):");
        for (i = 0; i < SYMBOLS; i = i + 1) begin
            $display("Index %2d: Symbol = %2d, Frequency = %d", 
                     i,
                     sorted_symbol_flat[i*SYMBOL_WIDTH +: SYMBOL_WIDTH],
                     sorted_frequencies_flat[i*FREQ_WIDTH +: FREQ_WIDTH]);
        end
        
        $finish;
    end
    
    // Monitor key signals.
    initial begin
        $monitor("Time=%0t, reset=%b, valid_in=%b, symbol_in=%d, sorted_done=%b", 
                 $time, reset, valid_in, symbol_in, sorted_done);
    end

endmodule


/*`timescale 1ns/1ps
module tb_stream_sorter_oets;
    parameter SYMBOLS = 16;
    parameter FREQ_WIDTH = 32;
    parameter SYMBOL_WIDTH = 5;
    parameter CLK_PERIOD = 10;
    
    reg clk;
    reg reset;
    reg [SYMBOL_WIDTH-1:0] symbol_in;
    reg valid_in;
    wire ready_in;
    wire [SYMBOLS*FREQ_WIDTH-1:0] sorted_frequencies_flat;
    wire [SYMBOLS*SYMBOL_WIDTH-1:0] sorted_symbol_flat;
    
    integer i;
    integer count;
    
    // Fixed input stream:
    // 0, 0, 1, 1, 2, 2, 3, 3, 4, 5, 6, 7, 8, 9, 10, 11
    reg [SYMBOL_WIDTH-1:0] input_seq [0:15];
    
    stream_sorter_oets #(
        .SYMBOLS(SYMBOLS),
        .FREQ_WIDTH(FREQ_WIDTH),
        .SYMBOL_WIDTH(SYMBOL_WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .symbol_in(symbol_in),
        .valid_in(valid_in),
        .ready_in(ready_in),
        .sorted_frequencies_flat(sorted_frequencies_flat),
        .sorted_symbol_flat(sorted_symbol_flat)
    );
    
    // Clock generation.
    always #(CLK_PERIOD/2) clk = ~clk;
    
    initial begin
        clk = 0;
        reset = 1;
        valid_in = 0;
        symbol_in = 0;
        
        // Initialize the fixed input sequence.
        input_seq[0] = 0;
        input_seq[1] = 0;
        input_seq[2] = 1;
        input_seq[3] = 1;
        input_seq[4] = 2;
        input_seq[5] = 2;
        input_seq[6] = 3;
        input_seq[7] = 3;
        input_seq[8] = 4;
        input_seq[9] = 5;
        input_seq[10] = 6;
        input_seq[11] = 7;
        input_seq[12] = 8;
        input_seq[13] = 9;
        input_seq[14] = 10;
        input_seq[15] = 11;
        
        #20;
        reset = 0;
        
        // Feed one input per clock cycle.
        for (count = 0; count < 16; count = count + 1) begin
            @(posedge clk);
            valid_in = 1;
            symbol_in = input_seq[count];
        end
        // Extra cycle so the last input (symbol 11) is properly latched.
        @(posedge clk);
        valid_in = 0;
        
        // Allow additional cycles for sorting to settle.
        //repeat (4) @(posedge clk);
        
        // Display the final sorted results.
        $display("Final Sorted Results (Ascending Order):");
        for (i = 0; i < SYMBOLS; i = i + 1) begin
            $display("Index %2d: Symbol = %2d, Frequency = %d", 
                     i,
                     sorted_symbol_flat[i*SYMBOL_WIDTH +: SYMBOL_WIDTH],
                     sorted_frequencies_flat[i*FREQ_WIDTH +: FREQ_WIDTH]);
        end
        
        $finish;
    end
    
    // Monitor key signals.
    initial begin
        $monitor("Time=%0t, reset=%b, valid_in=%b, symbol_in=%d", 
                 $time, reset, valid_in, symbol_in);
    end

endmodule*/





/*`timescale 1ns / 1ps

module stream_sorter_oets_tb;

    parameter SYMBOLS = 8;
    parameter CODE_SIZE_WIDTH = 5;
    parameter SYMBOL_WIDTH = 5;

    // Clock and Reset
    reg clk, reset;

    // Inputs to sorter
    reg [CODE_SIZE_WIDTH-1:0] data_in;
    reg [SYMBOL_WIDTH-1:0] symbol_in;
    reg valid_in;
    wire ready_in;

    // Outputs from sorter
    wire [SYMBOLS*CODE_SIZE_WIDTH-1:0] sorted_code_size_flat;
    wire [SYMBOLS*SYMBOL_WIDTH-1:0] sorted_symbol_flat;
    wire sorted_done;

    // Instantiate the DUT
    stream_sorter_oets #(
        .SYMBOLS(SYMBOLS),
        .CODE_SIZE_WIDTH(CODE_SIZE_WIDTH),
        .SYMBOL_WIDTH(SYMBOL_WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .symbol_in(symbol_in),
        .valid_in(valid_in),
        .ready_in(ready_in),
        .sorted_code_size_flat(sorted_code_size_flat),
        .sorted_symbol_flat(sorted_symbol_flat),
        .sorted_done(sorted_done)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Test vector storage
    reg [CODE_SIZE_WIDTH-1:0] test_code_sizes [0:SYMBOLS-1];
    reg [SYMBOL_WIDTH-1:0] test_symbols [0:SYMBOLS-1];

    integer i;

    initial begin
        $display("Starting testbench...");
        clk = 0;
        reset = 1;
        valid_in = 0;
        data_in = 0;
        symbol_in = 0;

        // Initialize test values
        test_code_sizes[0] = 5;
        test_code_sizes[1] = 2;
        test_code_sizes[2] = 7;
        test_code_sizes[3] = 3;
        test_code_sizes[4] = 1;
        test_code_sizes[5] = 6;
        test_code_sizes[6] = 4;
        test_code_sizes[7] = 0;

        for (i = 0; i < SYMBOLS; i = i + 1) begin
            test_symbols[i] = i;
        end

        // Hold reset
        #20;
        reset = 0;

        // Feed data one pair per clock
        for (i = 0; i < SYMBOLS; i = i + 1) begin
            @(posedge clk);
            if (ready_in) begin
                data_in <= test_code_sizes[i];
                symbol_in <= test_symbols[i];
                valid_in <= 1;
            end
            @(posedge clk);
            valid_in <= 0;
        end

        // Wait for sorted_done
        wait (sorted_done);

        // Print results
        $display("Sorted output:");
        for (i = 0; i < SYMBOLS; i = i + 1) begin
            $display("Code size: %0d, Symbol: %0d",
                     sorted_code_size_flat[i*CODE_SIZE_WIDTH +: CODE_SIZE_WIDTH],
                     sorted_symbol_flat[i*SYMBOL_WIDTH +: SYMBOL_WIDTH]);
        end

        $finish;
    end

endmodule*/