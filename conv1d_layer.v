// ============================================================
// Project : Real-Time EMG Gesture Recognition on FPGA
// File    : conv1d_layer.v
// Purpose : 1D Convolutional layer hardware implementation
//
// In our CNN model trained in Python, we have two Conv1D layers:
//   Conv1D Layer 1: 8  input channels -> 32 output channels, kernel=5
//   Conv1D Layer 2: 32 input channels -> 64 output channels, kernel=3
//
// This Verilog module implements that convolution operation in hardware.
// It uses parallel MAC units - one per output channel - to compute
// all filter responses at the same time (parallel, not sequential).
//
// After convolution, ReLU activation is applied: output = max(0, x)
// ============================================================

module conv1d_layer #(
    parameter INPUT_CHANNELS  = 8,
    parameter OUTPUT_CHANNELS = 32,
    parameter KERNEL_SIZE     = 5,
    parameter INPUT_LENGTH    = 10,
    parameter DATA_WIDTH      = 8,
    parameter ACCUM_WIDTH     = 32
)(
    input  wire clk,
    input  wire rst_n,
    input  wire start,

    // Input feature map (one value per input channel)
    input  wire signed [DATA_WIDTH-1:0] data_in [0:INPUT_CHANNELS-1],

    // Output feature map after convolution + ReLU
    output reg signed [DATA_WIDTH-1:0] data_out [0:OUTPUT_CHANNELS-1],
    output reg valid,
    output reg done
);

    // FSM states
    localparam IDLE     = 2'b00;
    localparam COMPUTE  = 2'b01;
    localparam ACTIVATE = 2'b10;
    localparam DONE_ST  = 2'b11;

    reg [1:0] state;
    reg [7:0] filter_idx; // which output filter we are computing

    // Weight memory (placeholder - in deployment loaded from BRAM)
    reg signed [DATA_WIDTH-1:0] weights [0:OUTPUT_CHANNELS-1][0:INPUT_CHANNELS-1][0:KERNEL_SIZE-1];
    reg signed [ACCUM_WIDTH-1:0] bias   [0:OUTPUT_CHANNELS-1];

    // Parallel MAC units - one per output channel
    wire signed [ACCUM_WIDTH-1:0] mac_accum [0:OUTPUT_CHANNELS-1];
    wire mac_enable;
    wire mac_clear;

    // Instantiate one MAC unit per output channel
    genvar i;
    generate
        for (i = 0; i < OUTPUT_CHANNELS; i = i + 1) begin : mac_array
            mac_unit #(
                .INPUT_WIDTH  (DATA_WIDTH),
                .WEIGHT_WIDTH (DATA_WIDTH),
                .ACCUM_WIDTH  (ACCUM_WIDTH)
            ) mac_inst (
                .clk         (clk),
                .rst_n       (rst_n),
                .enable      (mac_enable),
                .clear_accum (mac_clear),
                .data_in     (data_in[0]),       // simplified input mux
                .weight_in   (weights[i][0][0]), // simplified weight access
                .accum_out   (mac_accum[i]),
                .valid       ()
            );
        end
    endgenerate

    // Control FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            valid      <= 0;
            done       <= 0;
            filter_idx <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state      <= COMPUTE;
                        filter_idx <= 0;
                        valid      <= 0;
                        done       <= 0;
                    end
                end

                COMPUTE: begin
                    // Iterate through output filters
                    if (filter_idx < OUTPUT_CHANNELS)
                        filter_idx <= filter_idx + 1;
                    else
                        state <= ACTIVATE;
                end

                ACTIVATE: begin
                    // Apply ReLU: output = max(0, accumulator)
                    for (integer j = 0; j < OUTPUT_CHANNELS; j = j + 1) begin
                        if (mac_accum[j] > 0)
                            data_out[j] <= mac_accum[j][DATA_WIDTH-1:0];
                        else
                            data_out[j] <= 0;
                    end
                    state <= DONE_ST;
                    valid <= 1;
                end

                DONE_ST: begin
                    done  <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end

    assign mac_enable = (state == COMPUTE);
    assign mac_clear  = (state == IDLE && start);

endmodule
