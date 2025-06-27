/*module stream_sorter_oets #(
    parameter SYMBOLS = 16,
    parameter DATA_WIDTH = 5,
    parameter SYMBOL_WIDTH = 5
)(
    input  wire clk,
    input  wire reset,

    // Input stream interface
    input  wire [DATA_WIDTH-1:0] data_in,
    input  wire [SYMBOL_WIDTH-1:0]    symbol_in,
    input  wire                       valid_in,
    output reg                        ready_in,

    // Output sorted flat arrays
    output reg [SYMBOLS*DATA_WIDTH-1:0]      sorted_data_flat,
    output reg [SYMBOLS*SYMBOL_WIDTH-1:0]    sorted_symbol_flat,
    output reg                               sorted_done
);

    localparam PAIR_WIDTH = DATA_WIDTH + SYMBOL_WIDTH;
    localparam COUNT_WIDTH = $clog2(SYMBOLS + 1);

    // Buffer to store sorted {code_size, symbol} pairs
    reg [DATA_WIDTH-1:0] code_size_buffer [0:SYMBOLS-1];
    reg [SYMBOL_WIDTH-1:0]    symbol_buffer [0:SYMBOLS-1];
    reg [COUNT_WIDTH-1:0]     input_count;
    reg                       sorting;
    reg [COUNT_WIDTH-1:0]     insert_pos;
    reg [COUNT_WIDTH-1:0]     shift_count;

    // States for insertion sort
    localparam [1:0]
        S_IDLE   = 2'd0,
        S_INSERT = 2'd1,
        S_SHIFT  = 2'd2,
        S_DONE   = 2'd3;

    reg [1:0] state, next_state;

    // Handshake: ready when not shifting or done
    always @(*) begin
        ready_in = (state == S_IDLE || state == S_INSERT) && input_count < SYMBOLS;
    end

    // FSM state transition
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= S_IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Next state logic
    always @(*) begin
        case (state)
            S_IDLE: begin
                if (valid_in && ready_in && input_count < SYMBOLS) begin
                    next_state = S_INSERT;
                end else begin
                    next_state = S_IDLE;
                end
            end
            S_INSERT: begin
                if (insert_pos == input_count || code_size_buffer[insert_pos] >= data_in) begin
                    next_state = S_SHIFT;
                end else begin
                    next_state = S_INSERT;
                end
            end
            S_SHIFT: begin
                if (shift_count == 0) begin
                    if (input_count == SYMBOLS) begin
                        next_state = S_DONE;
                    end else begin
                        next_state = S_IDLE;
                    end
                end else begin
                    next_state = S_SHIFT;
                end
            end
            S_DONE: begin
                next_state = S_DONE; // Stay until reset
            end
            default: next_state = S_IDLE;
        endcase
    end

    // Main logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            input_count <= 0;
            sorting <= 0;
            sorted_done <= 0;
            insert_pos <= 0;
            shift_count <= 0;
            for (integer i = 0; i < SYMBOLS; i = i + 1) begin
                code_size_buffer[i] <= 0;
                symbol_buffer[i] <= 0;
            end
            sorted_data_flat <= 0;
            sorted_symbol_flat <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    if (valid_in && ready_in && input_count < SYMBOLS) begin
                        sorting <= 1;
                        insert_pos <= 0;
                        input_count <= input_count + 1;
                    end
                end
                S_INSERT: begin
                    if (insert_pos < input_count) begin
                        if (code_size_buffer[insert_pos] < data_in) begin
                            insert_pos <= insert_pos + 1;
                        end else begin
                            shift_count <= input_count - insert_pos;
                        end
                    end else begin
                        shift_count <= 0; // Insert at end
                    end
                end
                S_SHIFT: begin
                    if (shift_count > 0) begin
                        // Shift elements to make room
                        for (integer i = input_count - 1; i > insert_pos; i = i - 1) begin
                            code_size_buffer[i] <= code_size_buffer[i-1];
                            symbol_buffer[i] <= symbol_buffer[i-1];
                        end
                        // Insert new data
                        code_size_buffer[insert_pos] <= data_in;
                        symbol_buffer[insert_pos] <= symbol_in;
                        shift_count <= shift_count - 1;
                    end else begin
                        // Insert at end if no shift needed
                        code_size_buffer[insert_pos] <= data_in;
                        symbol_buffer[insert_pos] <= symbol_in;
                        sorting <= (input_count < SYMBOLS);
                    end
                end
                S_DONE: begin
                    sorted_done <= 1;
                    // Flatten outputs
                    for (integer i = 0; i < SYMBOLS; i = i + 1) begin
                        sorted_data_flat[i*DATA_WIDTH +: DATA_WIDTH] <= code_size_buffer[i];
                        sorted_symbol_flat[i*SYMBOL_WIDTH +: SYMBOL_WIDTH] <= symbol_buffer[i];
                    end
                end
            endcase
        end
    end

endmodule*/



module stream_sorter_oets #(
    parameter SYMBOLS = 16,
    parameter FREQ_WIDTH = 32,
    parameter SYMBOL_WIDTH = 5
)(
    input wire clk,
    input wire reset,
    input wire [SYMBOL_WIDTH-1:0] symbol_in,
    input wire valid_in,
    output wire ready_in,
    output reg [SYMBOLS*FREQ_WIDTH-1:0] sorted_frequencies_flat,
    output reg [SYMBOLS*SYMBOL_WIDTH-1:0] sorted_symbol_flat,
    output reg sorted_done
);
    // Total width for a frequency-symbol pair.
    localparam PAIR_WIDTH = FREQ_WIDTH + SYMBOL_WIDTH;

    // Buffer stores each element as { frequency, symbol }.
    reg [PAIR_WIDTH-1:0] buffer [0:SYMBOLS-1];
    // Combinational next-state buffer.
    reg [PAIR_WIDTH-1:0] buffer_next [0:SYMBOLS-1];
    // Temporary register for swapping.
    reg [PAIR_WIDTH-1:0] temp;
    // Counter for input symbols and total passes.
    reg [4:0] input_count; // Tracks actual number of valid inputs
    reg [5:0] pass_count;  // Tracks sorting passes
    reg [5:0] idle_count;  // Counts cycles with no new input
    integer i;
    
    // Always ready for an update.
    assign ready_in = 1;
    
    // Helper function: returns the lower SYMBOL_WIDTH bits of an integer.
    function [SYMBOL_WIDTH-1:0] lower_bits;
        //input integer value;
        input [31:0] value;
        begin
            lower_bits = value & ((1 << SYMBOL_WIDTH) - 1);
        end
    endfunction

    // Combinational block: compute next state by copying current state, 
    // updating the frequency (if valid_in is high) and performing one 
    // odd–even pass for ascending order.
    always @* begin
        // Start by copying the current state.
        for (i = 0; i < SYMBOLS; i = i + 1)
            buffer_next[i] = buffer[i];
            
        // Update: If valid, increment the frequency for the matching symbol.
        if (valid_in) begin
            for (i = 0; i < SYMBOLS; i = i + 1) begin
                if (buffer_next[i][SYMBOL_WIDTH-1:0] == symbol_in)
                    buffer_next[i][PAIR_WIDTH-1:SYMBOL_WIDTH] = 
                        buffer_next[i][PAIR_WIDTH-1:SYMBOL_WIDTH] + 1;
            end
        end
        
        // Odd phase: compare pairs (0,1), (2,3), ... and swap if left frequency > right.
        for (i = 0; i < SYMBOLS-1; i = i + 2) begin
            if (buffer_next[i][PAIR_WIDTH-1:SYMBOL_WIDTH] > buffer_next[i+1][PAIR_WIDTH-1:SYMBOL_WIDTH]) begin
                temp = buffer_next[i];
                buffer_next[i] = buffer_next[i+1];
                buffer_next[i+1] = temp;
            end
        end
        
        // Even phase: compare pairs (1,2), (3,4), ... and swap if left frequency > right.
        for (i = 1; i < SYMBOLS-1; i = i + 2) begin
            if (buffer_next[i][PAIR_WIDTH-1:SYMBOL_WIDTH] > buffer_next[i+1][PAIR_WIDTH-1:SYMBOL_WIDTH]) begin
                temp = buffer_next[i];
                buffer_next[i] = buffer_next[i+1];
                buffer_next[i+1] = temp;
            end
        end
    end

    // Sequential block: update the buffer and counters on each posedge of clk.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize: frequency=0, symbol = lower bits of the index.
            for (i = 0; i < SYMBOLS; i = i + 1)
                buffer[i] <= { {FREQ_WIDTH{1'b0}}, lower_bits(i) };
            input_count <= 0;
            pass_count <= 0;
            idle_count <= 0;
            sorted_done <= 0;
        end else begin
            for (i = 0; i < SYMBOLS; i = i + 1)
                buffer[i] <= buffer_next[i];
            if (valid_in) begin
                input_count <= input_count + 1;
                idle_count <= 0; // Reset idle count when new input arrives
            end else begin
                idle_count <= idle_count + 1; // Increment idle count when no input
            end
            pass_count <= pass_count + 1;
            // Set sorted_done when no new input for SYMBOLS + 4 cycles after last input
            if (idle_count >= SYMBOLS + 4 && input_count > 0) begin
                sorted_done <= 1;
            end
        end
    end

    // Continuously drive the flattened outputs.
    always @* begin
        for (i = 0; i < SYMBOLS; i = i + 1) begin
            sorted_frequencies_flat[i*FREQ_WIDTH +: FREQ_WIDTH] = 
                buffer[i][PAIR_WIDTH-1:SYMBOL_WIDTH];
            sorted_symbol_flat[i*SYMBOL_WIDTH +: SYMBOL_WIDTH] = 
                buffer[i][SYMBOL_WIDTH-1:0];
        end
    end

endmodule