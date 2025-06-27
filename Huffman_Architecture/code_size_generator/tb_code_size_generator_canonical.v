`timescale 1ns / 1ps

module tb_code_size_generator_canonical;

    parameter SYMBOLS          = 16;
    parameter FREQ_WIDTH       = 5;
    parameter CODE_SIZE_WIDTH  = 5;
    parameter SYMBOL_ID_WIDTH  = 5;

    reg  tb_clk;
    reg  tb_reset;
    reg  tb_start;
    wire [SYMBOLS*CODE_SIZE_WIDTH-1:0] tb_code_size_array;
    wire [SYMBOLS*SYMBOL_ID_WIDTH-1:0] tb_sorted_symbols_final;
    wire tb_done;

    code_size_generator_canonical #(
        .SYMBOLS(SYMBOLS),
        .FREQ_WIDTH(FREQ_WIDTH),
        .CODE_SIZE_WIDTH(CODE_SIZE_WIDTH),
        .SYMBOL_ID_WIDTH(SYMBOL_ID_WIDTH)
    ) dut (
        .clk(tb_clk),
        .reset(tb_reset),
        .start(tb_start),
        .code_size_array(tb_code_size_array),
        .sorted_symbols_final(tb_sorted_symbols_final),
        .done(tb_done)
    );
    reg [31:0] i;
    always #5 tb_clk = ~tb_clk;

    initial begin
        tb_clk = 0;
        tb_reset = 1;
        tb_start = 0;

        #50000;
        tb_reset = 0;
        $display("Reset deasserted at time %t", $time);

        #10000;
        tb_start = 1;
        #10;
        tb_start = 0;
        $display("Start asserted at time %t", $time);

        #2000000;
        if (!tb_done) begin
            $display("ERROR: Simulation timed out; tb_done not asserted.");
        end else begin
            $display("Simulation completed.");
            $write("Final code_size_array = [");
            begin
    
                for (i = 0; i < SYMBOLS; i = i + 1) begin
                    $write("%0d", tb_code_size_array[79-i*CODE_SIZE_WIDTH -: CODE_SIZE_WIDTH]);
                    if (i < SYMBOLS-1) $write(", ");
                end
            end
            $display("]");
            $write("Final sorted_symbols_final = [");
            begin

                for (i = 0; i < SYMBOLS; i = i + 1) begin
                    $write("%0d", tb_sorted_symbols_final[79-i*SYMBOL_ID_WIDTH -: SYMBOL_ID_WIDTH]);
                    if (i < SYMBOLS-1) $write(", ");
                end
            end
            $display("]");
        end
        $finish;
    end

    initial begin
        $dumpfile("tb_code_size_generator_canonical.vcd");
        $dumpvars(0, tb_code_size_generator_canonical);
    end

    initial begin
        $monitor("Time=%0t | State=%d | vj=%d | v1_freq=%d | v2_freq=%d | code_size_v1=%d | code_size_v2=%d | done=%b",
                 $time, dut.state, dut.vj, dut.v1_freq, dut.v2_freq, dut.code_size_v1, dut.code_size_v2, tb_done);
    end

endmodule