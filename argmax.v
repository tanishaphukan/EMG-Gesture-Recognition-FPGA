// ============================================================
// Project : Real-Time EMG Gesture Recognition on FPGA
// File    : argmax.v
// Purpose : Find which gesture has the highest score
//
// After the neural network outputs a score for each of the
// 8 gesture classes, this module scans through all scores
// and returns the index (0-7) of the highest one.
//
// Example:
//   Scores: [5, 2, 8, 1, 0, 3, 6, 2]
//   Output: class_id = 2 (index of maximum value 8)
//   Meaning: the model thinks the user made gesture #2 (Hand Close)
//
// Uses a simple sequential comparator FSM (8 comparisons, 8 cycles)
// ============================================================

module argmax #(
    parameter NUM_CLASSES = 8,
    parameter DATA_WIDTH  = 8
)(
    input  wire clk,
    input  wire rst_n,
    input  wire start,  // Pulse high to begin a new argmax search

    // All 8 class scores from the neural network
    input  wire signed [DATA_WIDTH-1:0] data0, data1, data2, data3,
    input  wire signed [DATA_WIDTH-1:0] data4, data5, data6, data7,

    output reg [2:0] class_id,  // Index of the winning gesture (0-7)
    output reg valid             // High for 1 cycle when result is ready
);

    // FSM states
    localparam IDLE   = 1'b0;
    localparam SEARCH = 1'b1;

    reg state;
    reg [2:0] idx;                         // current comparison index
    reg signed [DATA_WIDTH-1:0] max_val;   // running maximum score
    reg [2:0] max_idx;                     // index of current maximum

    // Store all scores in an array for easy iteration
    reg signed [DATA_WIDTH-1:0] data_arr [0:NUM_CLASSES-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= IDLE;
            class_id <= 3'd0;
            valid    <= 1'b0;
            idx      <= 3'd0;
            max_val  <= 8'sh80; // Most negative INT8 value (-128)
            max_idx  <= 3'd0;
        end else begin
            case (state)
                IDLE: begin
                    valid <= 1'b0;
                    if (start) begin
                        // Capture all 8 scores
                        data_arr[0] <= data0; data_arr[1] <= data1;
                        data_arr[2] <= data2; data_arr[3] <= data3;
                        data_arr[4] <= data4; data_arr[5] <= data5;
                        data_arr[6] <= data6; data_arr[7] <= data7;
                        // Reset search state
                        idx     <= 3'd0;
                        max_val <= 8'sh80;
                        max_idx <= 3'd0;
                        state   <= SEARCH;
                    end
                end

                SEARCH: begin
                    if (idx < NUM_CLASSES) begin
                        // Compare current score with running maximum
                        if (data_arr[idx] > max_val) begin
                            max_val <= data_arr[idx];
                            max_idx <= idx;
                        end
                        idx <= idx + 3'd1;
                    end else begin
                        // Done - output the winning class
                        class_id <= max_idx;
                        valid    <= 1'b1;
                        state    <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
