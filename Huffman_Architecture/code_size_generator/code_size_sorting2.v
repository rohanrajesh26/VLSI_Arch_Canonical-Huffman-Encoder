// Uses odd-even transposition sort for parallel computing
`timescale 1ns/1ps // For testbench, comment out later bhaijaan

module code_size_sorting2 #(
    parameter SYMBOLS = 16,
    parameter CODE_SIZE_WIDTH = 5,
    parameter SYMBOL_ID_WIDTH = 4  // log2(16) = 4
)(
    input wire clk,
    input wire reset,
    input wire enable,
    input wire [SYMBOLS*CODE_SIZE_WIDTH-1:0] code_size_flat,
    input wire [SYMBOLS*SYMBOL_ID_WIDTH-1:0] symbol_id_flat,
    output reg [SYMBOLS*CODE_SIZE_WIDTH-1:0] sorted_code_size_flat,
    output reg [SYMBOLS*SYMBOL_ID_WIDTH-1:0] sorted_symbol_id_flat,
    output reg done
);

    reg [CODE_SIZE_WIDTH-1:0] code_size_array [0:SYMBOLS-1];
    reg [SYMBOL_ID_WIDTH-1:0] symbol_id_array [0:SYMBOLS-1];

    reg [CODE_SIZE_WIDTH-1:0] temp_code_size [0:SYMBOLS-1];
    reg [SYMBOL_ID_WIDTH-1:0] temp_symbol_id [0:SYMBOLS-1];

    integer i, pass, j;
    reg [CODE_SIZE_WIDTH-1:0] temp_cs;
    reg [SYMBOL_ID_WIDTH-1:0] temp_id;

    // FSM states
    reg [3:0] pass_count;
    reg sorting;
    reg stage1_done;
    reg stage2_done;

    // Stage 1: Capture input arrays
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < SYMBOLS; i = i + 1) begin
                code_size_array[i] <= 0;
                symbol_id_array[i] <= 0;
            end
            stage1_done <= 0;
        end else if (enable) begin
            for (i = 0; i < SYMBOLS; i = i + 1) begin
                code_size_array[i] <= code_size_flat[i*CODE_SIZE_WIDTH +: CODE_SIZE_WIDTH];
                symbol_id_array[i] <= symbol_id_flat[i*SYMBOL_ID_WIDTH +: SYMBOL_ID_WIDTH];
            end
            stage1_done <= 1;
        end else begin
            stage1_done <= 0;
        end
    end

    // Stage 2: Sorting using FSM and odd-even transposition
    always @(posedge clk) begin
        if (reset) begin
            pass_count <= 0;
            sorting <= 0;
            stage2_done <= 0;
        end else if (stage1_done && !sorting) begin
            // Copy input to temporary arrays
            for (i = 0; i < SYMBOLS; i = i + 1) begin
                temp_code_size[i] <= code_size_array[i];
                temp_symbol_id[i] <= symbol_id_array[i];
            end
            sorting <= 1;
            pass_count <= 0;
            stage2_done <= 0;
        end else if (sorting) begin
            for (j = pass_count[0]; j < SYMBOLS - 1; j = j + 2) begin
                if (temp_code_size[j] > temp_code_size[j+1]) begin
                    // Swap code sizes
                    temp_cs = temp_code_size[j];
                    temp_code_size[j] <= temp_code_size[j+1];
                    temp_code_size[j+1] <= temp_cs;

                    // Swap symbol IDs
                    temp_id = temp_symbol_id[j];
                    temp_symbol_id[j] <= temp_symbol_id[j+1];
                    temp_symbol_id[j+1] <= temp_id;
                end
            end

            if (pass_count == SYMBOLS - 1) begin
                sorting <= 0;
                stage2_done <= 1;
            end else begin
                pass_count <= pass_count + 1;
            end
        end
    end

    // Stage 3: Output flattened sorted results
    always @(posedge clk) begin
        if (reset) begin
            sorted_code_size_flat <= 0;
            sorted_symbol_id_flat <= 0;
            done <= 0;
        end else if (stage2_done) begin
            for (i = 0; i < SYMBOLS; i = i + 1) begin
                sorted_code_size_flat[i*CODE_SIZE_WIDTH +: CODE_SIZE_WIDTH] <= temp_code_size[i];
                sorted_symbol_id_flat[i*SYMBOL_ID_WIDTH +: SYMBOL_ID_WIDTH] <= temp_symbol_id[i];
            end
            done <= 1;
        end else begin
            done <= 0;
        end
    end

endmodule
