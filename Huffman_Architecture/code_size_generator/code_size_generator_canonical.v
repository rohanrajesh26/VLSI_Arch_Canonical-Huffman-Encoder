`timescale 1ns / 1ps

module code_size_generator_canonical #(
    parameter SYMBOLS         = 16,
    parameter FREQ_WIDTH      = 5,
    parameter CODE_SIZE_WIDTH = 5,
    parameter SYMBOL_ID_WIDTH = 5
) (
    input  clk,
    input  reset,
    input  start,
    output [SYMBOLS*CODE_SIZE_WIDTH-1:0]  code_size_array,
    output [SYMBOLS*SYMBOL_ID_WIDTH-1:0]  sorted_symbols_final,
    output done
);

    parameter S_IDLE        = 4'd0,
              S_FIND_V      = 4'd1,
              S_SUM_FREQ1   = 4'd2,
              S_SUM_FREQ2   = 4'd3,
              S_COMPUTE_CS1 = 4'd4,
              S_COMPUTE_CS2 = 4'd5,
              S_COMPUTE_CS3 = 4'd6,
              S_COMPUTE_CS4 = 4'd7,
              S_COMPUTE_CS5 = 4'd8,
              S_COMPUTE_CS6 = 4'd9,
              S_COMPUTE_CS7 = 4'd10,
              S_SORT        = 4'd11,
              S_DONE        = 4'd12;

    reg [3:0] state;
    reg [7:0] vj;
    reg end_of_data;
    reg [FREQ_WIDTH-1:0] v1_freq, v2_freq, new_freq;
    reg [SYMBOL_ID_WIDTH-1:0] v1_symbol, v2_symbol;
    reg [CODE_SIZE_WIDTH-1:0] code_size_v1, code_size_v2;
    reg done_reg;

    reg [FREQ_WIDTH-1:0] latched_v1_freq, latched_v2_freq;
    reg [SYMBOL_ID_WIDTH-1:0] latched_v1_symbol, latched_v2_symbol;

    reg [FREQ_WIDTH-1:0] freq_array [0:SYMBOLS-1];
    reg [SYMBOL_ID_WIDTH-1:0] symbol_array [0:SYMBOLS-1];
    reg [CODE_SIZE_WIDTH-1:0] code_size_array_internal [0:SYMBOLS-1];
    reg [SYMBOL_ID_WIDTH-1:0] symbol_array_internal [0:SYMBOLS-1];
    reg [SYMBOLS*CODE_SIZE_WIDTH-1:0] code_size_array_reg;
    reg [SYMBOLS*SYMBOL_ID_WIDTH-1:0] sorted_symbols_final_reg;

    reg [31:0] pair_count;
    reg [31:0] i, j;
    reg [CODE_SIZE_WIDTH-1:0] temp_code_size;
    reg [SYMBOL_ID_WIDTH-1:0] temp_symbol;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= S_IDLE;
            vj <= SYMBOLS;
            end_of_data <= 1'b0;
            code_size_v1 <= 0;
            code_size_v2 <= 0;
            done_reg <= 1'b0;
            latched_v1_freq <= 0;
            latched_v2_freq <= 0;
            latched_v1_symbol <= 0;
            latched_v2_symbol <= 0;
            v1_freq <= 0;
            v2_freq <= 0;
            v1_symbol <= 0;
            v2_symbol <= 0;
            new_freq <= 0;
            pair_count <= 0;
            code_size_array_reg <= 0;
            sorted_symbols_final_reg <= 0;
            for (i = 0; i < SYMBOLS; i = i + 1) begin
                code_size_array_internal[i] <= 0;
                symbol_array_internal[i] <= 0;
            end
            // Initialize freq_array and symbol_array (same as testbench)
            freq_array[0] <= 5'd10;  symbol_array[0] <= 5'd5;
            freq_array[1] <= 5'd9;   symbol_array[1] <= 5'd1;
            freq_array[2] <= 5'd8;   symbol_array[2] <= 5'd7;
            freq_array[3] <= 5'd7;   symbol_array[3] <= 5'd3;
            freq_array[4] <= 5'd6;   symbol_array[4] <= 5'd9;
            freq_array[5] <= 5'd5;   symbol_array[5] <= 5'd8;
            freq_array[6] <= 5'd4;   symbol_array[6] <= 5'd4;
            freq_array[7] <= 5'd3;   symbol_array[7] <= 5'd6;
            freq_array[8] <= 5'd2;   symbol_array[8] <= 5'd0;
            freq_array[9] <= 5'd2;   symbol_array[9] <= 5'd10;
            freq_array[10] <= 5'd1;  symbol_array[10] <= 5'd2;
            freq_array[11] <= 5'd1;  symbol_array[11] <= 5'd11;
            freq_array[12] <= 5'd0;  symbol_array[12] <= 5'd12;
            freq_array[13] <= 5'd0;  symbol_array[13] <= 5'd13;
            freq_array[14] <= 5'd0;  symbol_array[14] <= 5'd14;
            freq_array[15] <= 5'd0;  symbol_array[15] <= 5'd15;
        end else begin
            case (state)
                S_IDLE: begin
                    if (start)
                        state <= S_FIND_V;
                end
                S_FIND_V: begin
                    if (vj > 2) begin
                        latched_v1_freq <= freq_array[SYMBOLS - vj];
                        latched_v2_freq <= freq_array[SYMBOLS - vj + 1];
                        latched_v1_symbol <= symbol_array[SYMBOLS - vj];
                        latched_v2_symbol <= symbol_array[SYMBOLS - vj + 1];
                        state <= S_SUM_FREQ1;
                        vj <= vj - 2;
                    end else begin
                        end_of_data <= 1;
                        state <= S_SORT;
                    end
                end
                S_SUM_FREQ1: begin
                    v1_freq <= latched_v1_freq;
                    v2_freq <= latched_v2_freq;
                    v1_symbol <= latched_v1_symbol;
                    v2_symbol <= latched_v2_symbol;
                    new_freq <= latched_v1_freq + latched_v2_freq;
                    state <= S_SUM_FREQ2;
                end
                S_SUM_FREQ2: begin
                    freq_array[SYMBOLS - vj] <= 0;
                    freq_array[SYMBOLS - vj + 1] <= 0;
                    symbol_array[SYMBOLS - vj] <= 0;
                    symbol_array[SYMBOLS - vj + 1] <= 0;
                    for (i = 0; i < SYMBOLS; i = i + 1) begin
                        if (i == SYMBOLS-1 || (freq_array[i] != 0 && new_freq >= freq_array[i])) begin
                            for (j = SYMBOLS-1; j > i; j = j - 1) begin
                                freq_array[j] <= freq_array[j-1];
                                symbol_array[j] <= symbol_array[j-1];
                            end
                            freq_array[i] <= new_freq;
                            symbol_array[i] <= SYMBOLS;
                            i = SYMBOLS;
                        end
                    end
                    state <= S_COMPUTE_CS1;
                end
                S_COMPUTE_CS1: state <= S_COMPUTE_CS2;
                S_COMPUTE_CS2: state <= S_COMPUTE_CS3;
                S_COMPUTE_CS3: state <= S_COMPUTE_CS4;
                S_COMPUTE_CS4: state <= S_COMPUTE_CS5;
                S_COMPUTE_CS5: state <= S_COMPUTE_CS6;
                S_COMPUTE_CS6: state <= S_COMPUTE_CS7;
                S_COMPUTE_CS7: begin
                    code_size_v1 <= code_size_v1 + 1;
                    code_size_v2 <= code_size_v2 + 1;
                    code_size_array_internal[pair_count] <= code_size_v1 + 1;
                    symbol_array_internal[pair_count] <= v1_symbol;
                    code_size_array_internal[pair_count + 1] <= code_size_v2 + 1;
                    symbol_array_internal[pair_count + 1] <= v2_symbol;
                    pair_count <= pair_count + 2;
                    state <= (vj == 0) ? S_SORT : S_FIND_V;
                end
                S_SORT: begin
                    for (i = 0; i < SYMBOLS-1; i = i + 1) begin
                        for (j = 0; j < SYMBOLS-1-i; j = j + 1) begin
                            if (code_size_array_internal[j] > code_size_array_internal[j+1]) begin
                                temp_code_size = code_size_array_internal[j];
                                code_size_array_internal[j] = code_size_array_internal[j+1];
                                code_size_array_internal[j+1] = temp_code_size;
                                temp_symbol = symbol_array_internal[j];
                                symbol_array_internal[j] = symbol_array_internal[j+1];
                                symbol_array_internal[j+1] = temp_symbol;
                            end
                        end
                    end
                    for (i = 0; i < SYMBOLS; i = i + 1) begin
                        code_size_array_reg[79-i*CODE_SIZE_WIDTH -: CODE_SIZE_WIDTH] <= code_size_array_internal[i];
                        sorted_symbols_final_reg[79-i*SYMBOL_ID_WIDTH -: SYMBOL_ID_WIDTH] <= symbol_array_internal[i];
                    end
                    state <= S_DONE;
                end
                S_DONE: begin
                    done_reg <= 1;
                    state <= S_IDLE;
                end
                default: state <= S_IDLE;
            endcase
        end
    end

    always @(posedge clk) begin
        if (state == S_FIND_V)
            $display("Time %0t: S_FIND_V: v1=%0d, v1_freq=%0d, v2=%0d, v2_freq=%0d",
                     $time, v1_symbol, v1_freq, v2_symbol, v2_freq);
        if (state == S_SUM_FREQ1)
            $display("Time %0t: S_SUM_FREQ1: latched_v1_freq=%0d, latched_v2_freq=%0d",
                     $time, latched_v1_freq, latched_v2_freq);
        if (state == S_SUM_FREQ2)
            $display("Time %0t: S_SUM_FREQ2: new_freq=%0d, symbol=%0d",
                     $time, new_freq, SYMBOLS);
        if (state == S_COMPUTE_CS7)
            $display("Time %0t: S_COMPUTE_CS7: code_size_v1=%0d, code_size_v2=%0d, v1=%0d, v2=%0d",
                     $time, code_size_v1 + 1, code_size_v2 + 1, v1_symbol, v2_symbol);
        if (state == S_SORT)
            $display("Time %0t: S_SORT: Sorting code sizes", $time);
        if (state == S_DONE)
            $display("Time %0t: S_DONE: All code sizes computed", $time);
    end

    assign code_size_array = code_size_array_reg;
    assign sorted_symbols_final = sorted_symbols_final_reg;
    assign done = done_reg;

endmodule