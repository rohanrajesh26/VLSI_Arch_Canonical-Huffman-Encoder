`timescale 1ns/1ps

module tb_code_size_sorting_parallel;

    parameter SYMBOLS = 16;
    parameter CODE_SIZE_WIDTH = 5;
    parameter SYMBOL_ID_WIDTH = 4;

    reg clk;
    reg reset;
    reg enable;
    reg [SYMBOLS*CODE_SIZE_WIDTH-1:0] code_size_flat;
    reg [SYMBOLS*SYMBOL_ID_WIDTH-1:0] symbol_id_flat;
    wire [SYMBOLS*CODE_SIZE_WIDTH-1:0] sorted_code_size_flat;
    wire [SYMBOLS*SYMBOL_ID_WIDTH-1:0] sorted_symbol_id_flat;
    wire done;

    code_size_sorting2 #(
        .SYMBOLS(SYMBOLS),
        .CODE_SIZE_WIDTH(CODE_SIZE_WIDTH),
        .SYMBOL_ID_WIDTH(SYMBOL_ID_WIDTH)
    ) uut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .code_size_flat(code_size_flat),
        .symbol_id_flat(symbol_id_flat),
        .sorted_code_size_flat(sorted_code_size_flat),
        .sorted_symbol_id_flat(sorted_symbol_id_flat),
        .done(done)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    integer i;
    reg [CODE_SIZE_WIDTH-1:0] sizes [0:SYMBOLS-1];
    reg [SYMBOL_ID_WIDTH-1:0] ids [0:SYMBOLS-1];

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_code_size_sorting_parallel);

        // Initialize signals
        reset = 1;
        enable = 0;
        code_size_flat = 0;
        symbol_id_flat = 0;
        #20;

        reset = 0;
        #10;

        // Create unsorted input
        sizes[0] = 10; ids[0] = 4;
        sizes[1] = 3;  ids[1] = 1;
        sizes[2] = 7;  ids[2] = 2;
        sizes[3] = 2;  ids[3] = 6;
        sizes[4] = 15; ids[4] = 0;
        sizes[5] = 8;  ids[5] = 8;
        sizes[6] = 5;  ids[6] = 3;
        sizes[7] = 1;  ids[7] = 9;
        sizes[8] = 14; ids[8] = 10;
        sizes[9] = 6;  ids[9] = 11;
        sizes[10] = 4; ids[10] = 5;
        sizes[11] = 12;ids[11] = 7;
        sizes[12] = 9; ids[12] = 12;
        sizes[13] = 0; ids[13] = 13;
        sizes[14] = 11;ids[14] = 14;
        sizes[15] = 13;ids[15] = 15;

        // Flatten the arrays
        for (i = 0; i < SYMBOLS; i = i + 1) begin
            code_size_flat[i*CODE_SIZE_WIDTH +: CODE_SIZE_WIDTH] = sizes[i];
            symbol_id_flat[i*SYMBOL_ID_WIDTH +: SYMBOL_ID_WIDTH] = ids[i];
        end

        // Trigger input capture
        enable = 1;
        #10;
        enable = 0;

        // Wait until sorting is complete
        wait (done == 1);
        #10;

        $display("Sorted code sizes and IDs:");
        for (i = 0; i < SYMBOLS; i = i + 1) begin
            $display("code_size[%0d] = %0d, symbol_id = %0d",
                i,
                sorted_code_size_flat[i*CODE_SIZE_WIDTH +: CODE_SIZE_WIDTH],
                sorted_symbol_id_flat[i*SYMBOL_ID_WIDTH +: SYMBOL_ID_WIDTH]
            );
        end

        $display("Done signal status: %b", done);

        #10;
        $finish;
    end

endmodule
