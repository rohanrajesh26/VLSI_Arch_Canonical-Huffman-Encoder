module frequency_generation_stage #(
    parameter SYMBOL_WIDTH = 5,    // Width of input symbols (0-15)
    parameter FREQ_WIDTH = 32,     // Width of frequency counters
    parameter NUM_CELLS = 16       // Number of unique symbols
) (
    input  wire clk,
    input  wire reset,
    input  wire [SYMBOL_WIDTH-1:0] symbol_in,  // Input symbol
    input  wire valid_in,                      // Input valid signal
    output wire ready_in,                      // Ready to accept input
    output wire [NUM_CELLS*FREQ_WIDTH-1:0] sorted_frequencies,  // Sorted frequencies
    output wire [NUM_CELLS*SYMBOL_WIDTH-1:0] sorted_symbols,    // Sorted symbols
    output wire sorted_done                    // Sorting complete signal
);

    // Instantiate the updated stream_sorter_oets module
    stream_sorter_oets #(
        .SYMBOLS(NUM_CELLS),
        .FREQ_WIDTH(FREQ_WIDTH),
        .SYMBOL_WIDTH(SYMBOL_WIDTH)
    ) sorter_inst (
        .clk(clk),
        .reset(reset),
        .symbol_in(symbol_in),
        .valid_in(valid_in),
        .ready_in(ready_in),
        .sorted_frequencies_flat(sorted_frequencies),
        .sorted_symbol_flat(sorted_symbols),
        .sorted_done(sorted_done)
    );

endmodule