`timescale 1ns/1ps

module fsm_2_tb;

  // -------------------------------------------------------------------------
  // VCD dump for GTKWave
  // -------------------------------------------------------------------------
  initial begin
    $dumpfile("fsm_2_tb.vcd");
    $dumpvars(0, fsm_2_tb);
  end

  // -------------------------------------------------------------------------
  // Parameters
  // -------------------------------------------------------------------------
  parameter SYMBOLS   = 6;
  parameter MAX_BITS  = 16;

  // -------------------------------------------------------------------------
  // DUT I/Os
  // -------------------------------------------------------------------------
  reg                      clk;
  reg                      rst;
  reg                      start;
  reg  [8*MAX_BITS-1:0]    BITS_packed;
  reg  [8*SYMBOLS-1:0]     HUFFMANVAL_packed;
  wire                     done;
  wire [16*SYMBOLS-1:0]    HUFFMAN_CODE_packed;

  // -------------------------------------------------------------------------
  // DUT Instantiation
  // -------------------------------------------------------------------------
  fsm_2 #(
    .SYMBOLS   (SYMBOLS),
    .MAX_BITS  (MAX_BITS)
  ) dut (
    .clk                 (clk),
    .rst                 (rst),
    .start               (start),
    .BITS_packed         (BITS_packed),
    .HUFFMANVAL_packed   (HUFFMANVAL_packed),
    .done                (done),
    .HUFFMAN_CODE_packed (HUFFMAN_CODE_packed)
  );

  // -------------------------------------------------------------------------
  // Clock Generation
  // -------------------------------------------------------------------------
  initial clk = 0;
  always #5 clk = ~clk;  // 100 MHz

  // -------------------------------------------------------------------------
  // Test Sequence
  // -------------------------------------------------------------------------
  integer i;
  initial begin
    $display("Starting fsm_2 Testbench…");

    // Initialize
    rst               = 1;
    start             = 0;
    BITS_packed       = {8*MAX_BITS{1'b0}};
    HUFFMANVAL_packed = {8*SYMBOLS{1'b0}};

    // Hold reset for two clocks
    repeat (2) @(posedge clk);
    rst = 0;

    // ---- TEST: Force total symbols = 20 @ length=5 (should trigger limiting) ----
    BITS_packed[8*5-1 -: 8] = 8'd20;

    // Assign 6 symbol values: 'A','B','C','D','E','F'
    HUFFMANVAL_packed[   7:   0] = "A";
    HUFFMANVAL_packed[  15:   8] = "B";
    HUFFMANVAL_packed[  23:  16] = "C";
    HUFFMANVAL_packed[  31:  24] = "D";
    HUFFMANVAL_packed[  39:  32] = "E";
    HUFFMANVAL_packed[  47:  40] = "F";

    // Kick off the FSM on one clock
    @(posedge clk);
    start = 1;
    @(posedge clk);
    start = 0;

    // Wait for 'done' to go high
    wait (done == 1);
    @(posedge clk);

    // Display the results
    $display("Symbol | Huffman Code");
    $display("-------+--------------");
    for (i = 0; i < SYMBOLS; i = i + 1) begin
      $display("   %c   | %b",
        HUFFMANVAL_packed[8*i +: 8],
        HUFFMAN_CODE_packed[16*i +: 16]
      );
    end

    $display("Test complete.");
    $finish;
  end

endmodule
