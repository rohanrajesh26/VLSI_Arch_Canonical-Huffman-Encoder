module fsm_2 #(
    parameter SYMBOLS    = 4,
    parameter MAX_BITS   = 16
) (
    input  wire                     clk,
    input  wire                     rst,
    input  wire                     start,
    input  wire [8*MAX_BITS-1:0]    BITS_packed,
    input  wire [8*SYMBOLS-1:0]     HUFFMANVAL_packed,
    output reg                      done,
    output wire [16*SYMBOLS-1:0]    HUFFMAN_CODE_packed
);

  // unpacked arrays
  reg [7:0]  BITS_array      [1:MAX_BITS];
  reg [7:0]  HUFFMANVAL_array[0:SYMBOLS-1];
  reg [15:0] HUFFMAN_CODE_array[0:SYMBOLS-1];
  reg [15:0] next_code       [0:MAX_BITS];
  
  // working variables
  integer i, j, k;
  integer move_count;            // <-- moved here
  integer total = 0;
  integer excess;
  reg [15:0] code;
  reg [7:0]  MAX_CODE_LENGTH = 4;

  // Unpack inputs
  always @(*) begin
    for (i = 1; i <= MAX_BITS; i = i + 1)
      BITS_array[i] = BITS_packed[8*i-1 -: 8];
    for (i = 0; i < SYMBOLS; i = i + 1)
      HUFFMANVAL_array[i] = HUFFMANVAL_packed[8*i+7 -: 8];
  end

  // FSM
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      done <= 0;
      for (i = 0; i < SYMBOLS; i = i + 1)
        HUFFMAN_CODE_array[i] <= 0;
    end else if (start) begin
      // compute total
      total = 0;
      for (i = 1; i <= MAX_BITS; i = i + 1)
        total = total + BITS_array[i];

      // limit to MAX_CODE_LENGTH bits
      excess = (total > (1 << MAX_CODE_LENGTH)) 
               ? (total - (1 << MAX_CODE_LENGTH)) 
               : 0;

      // single‑pass adjust
      for (i = MAX_BITS; i > 1 && excess > 0; i = i - 1) begin
        if (BITS_array[i] > 0) begin
          move_count = (BITS_array[i] < excess) 
                       ? BITS_array[i] 
                       : excess;
          BITS_array[i]     = BITS_array[i] - move_count;
          BITS_array[i-1]   = BITS_array[i-1] + (move_count * 2);
          total             = total - move_count;
          excess            = excess - move_count;
        end
      end

      // generate canonical codes
      code = 0;
      for (i = 1; i <= MAX_BITS; i = i + 1) begin
        next_code[i] = code;
        code = (code + BITS_array[i]) << 1;
      end

      k = 0;
      for (i = 1; i <= MAX_BITS; i = i + 1) begin
        for (j = 0; j < BITS_array[i]; j = j + 1) begin
          HUFFMAN_CODE_array[k] = next_code[i];
          next_code[i]          = next_code[i] + 1;
          k = k + 1;
        end
      end

      done <= 1;
    end else begin
      done <= 0;
    end
  end

  // Pack outputs
  genvar idx;
  generate
    for (idx = 0; idx < SYMBOLS; idx = idx + 1) begin : pack_codes
      assign HUFFMAN_CODE_packed[16*idx+15:16*idx] = HUFFMAN_CODE_array[idx];
    end
  endgenerate

endmodule
