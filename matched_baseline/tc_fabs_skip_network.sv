module tc_fabs_skip_network #(
    parameter int SCHEDULE_ENTRIES = 313,
    parameter L0_WEIGHT_FILE = "network_l0_weights.hex",
    parameter L0_MASK_FILE = "network_l0_masks.hex",
    parameter L0_THRESHOLD_FILE = "network_l0_thresholds.hex",
    parameter L0_DIRECTION_FILE = "network_l0_directions.hex",
    parameter L1_THRESHOLD_FILE = "network_l1_thresholds.hex",
    parameter L1_DIRECTION_FILE = "network_l1_directions.hex",
    parameter L2_THRESHOLD_FILE = "network_l2_thresholds.hex",
    parameter L2_DIRECTION_FILE = "network_l2_directions.hex",
    parameter SCHEDULE_WEIGHT_FILE = "network_schedule_weights.hex",
    parameter SCHEDULE_ADDRESS_FILE = "network_schedule_addresses.hex",
    parameter SCHEDULE_NEURON_FILE = "network_schedule_neurons.hex",
    parameter SCHEDULE_LAYER_FILE = "network_schedule_layers.hex",
    parameter SCHEDULE_LAST_FILE = "network_schedule_last.hex",
    parameter SCHEDULE_VALID_FILE = "network_schedule_valid.hex",
    parameter OUTPUT_THRESHOLD_FILE = "network_output_threshold.hex"
) (
    input  logic clk,
    input  logic reset_n,
    input  logic start,
    input  logic signed [391:0] features_q,
    output logic busy,
    output logic done,
    output logic attack
);
    typedef enum logic [2:0] {IDLE, L0_LOAD, L0_ACCUMULATE, STREAM_LOAD,
                              STREAM_ACTIVATION, STREAM_POPCOUNT,
                              STREAM_ACCUMULATE} state_t;
    state_t state;

    logic [63:0] l0_weight_memory [0:255];
    logic [63:0] l0_mask_memory [0:255];
    logic signed [31:0] l0_threshold_memory [0:255];
    logic l0_direction_memory [0:255];
    logic signed [31:0] l1_threshold_memory [0:127];
    logic l1_direction_memory [0:127];
    logic signed [31:0] l2_threshold_memory [0:63];
    logic l2_direction_memory [0:63];
    logic [31:0] schedule_weight_memory [0:SCHEDULE_ENTRIES-1];
    logic [7:0] schedule_address_memory [0:SCHEDULE_ENTRIES-1];
    logic [7:0] schedule_neuron_memory [0:SCHEDULE_ENTRIES-1];
    logic [1:0] schedule_layer_memory [0:SCHEDULE_ENTRIES-1];
    logic schedule_last_memory [0:SCHEDULE_ENTRIES-1];
    logic schedule_valid_memory [0:SCHEDULE_ENTRIES-1];
    logic signed [31:0] output_threshold_memory [0:0];

    logic [255:0] activation_0;
    logic [127:0] activation_1;
    logic [63:0] activation_2;
    logic [7:0] l0_neuron;
    logic [5:0] l0_feature;
    logic [63:0] l0_weight_q;
    logic [63:0] l0_mask_q;
    logic signed [31:0] accumulator;
    logic [8:0] schedule_index;
    logic [31:0] schedule_weight_q;
    logic [7:0] schedule_address_q;
    logic [7:0] schedule_neuron_q;
    logic [1:0] schedule_layer_q;
    logic schedule_last_q;
    logic schedule_valid_q;
    logic [31:0] activation_word;
    logic [31:0] activation_word_q;
    logic [31:0] schedule_weight_pipe_q;
    logic schedule_valid_pipe_q;
    logic [31:0] xnor_word;
    logic [5:0] match_count;
    logic signed [31:0] stream_contribution;
    logic signed [31:0] stream_contribution_q;
    logic signed [31:0] l0_feature_value;
    logic signed [31:0] l0_contribution;
    integer bit_index;

    initial begin
        $readmemh(L0_WEIGHT_FILE, l0_weight_memory);
        $readmemh(L0_MASK_FILE, l0_mask_memory);
        $readmemh(L0_THRESHOLD_FILE, l0_threshold_memory);
        $readmemh(L0_DIRECTION_FILE, l0_direction_memory);
        $readmemh(L1_THRESHOLD_FILE, l1_threshold_memory);
        $readmemh(L1_DIRECTION_FILE, l1_direction_memory);
        $readmemh(L2_THRESHOLD_FILE, l2_threshold_memory);
        $readmemh(L2_DIRECTION_FILE, l2_direction_memory);
        $readmemh(SCHEDULE_WEIGHT_FILE, schedule_weight_memory);
        $readmemh(SCHEDULE_ADDRESS_FILE, schedule_address_memory);
        $readmemh(SCHEDULE_NEURON_FILE, schedule_neuron_memory);
        $readmemh(SCHEDULE_LAYER_FILE, schedule_layer_memory);
        $readmemh(SCHEDULE_LAST_FILE, schedule_last_memory);
        $readmemh(SCHEDULE_VALID_FILE, schedule_valid_memory);
        $readmemh(OUTPUT_THRESHOLD_FILE, output_threshold_memory);
    end

    always_comb begin
        case (schedule_layer_q)
            2'd1: activation_word = activation_0[schedule_address_q * 32 +: 32];
            2'd2: activation_word = activation_1[schedule_address_q * 32 +: 32];
            default: activation_word = activation_2[schedule_address_q * 32 +: 32];
        endcase
        xnor_word = ~(activation_word_q ^ schedule_weight_pipe_q);
        match_count = 0;
        for (bit_index = 0; bit_index < 32; bit_index = bit_index + 1)
            match_count = match_count + xnor_word[bit_index];
        stream_contribution = schedule_valid_pipe_q ?
            $signed({1'b0, match_count, 1'b0}) - 32'sd32 : 32'sd0;
        l0_feature_value = $signed(features_q[l0_feature * 8 +: 8]);
        l0_contribution = !l0_mask_q[l0_feature] ? 0 :
                          (l0_weight_q[l0_feature] ? l0_feature_value : -l0_feature_value);
    end

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            busy <= 1'b0;
            done <= 1'b0;
            attack <= 1'b0;
            activation_0 <= '0;
            activation_1 <= '0;
            activation_2 <= '0;
            l0_neuron <= '0;
            l0_feature <= '0;
            l0_weight_q <= '0;
            l0_mask_q <= '0;
            accumulator <= '0;
            schedule_index <= '0;
            schedule_weight_q <= '0;
            schedule_address_q <= '0;
            schedule_neuron_q <= '0;
            schedule_layer_q <= '0;
            schedule_last_q <= 1'b0;
            schedule_valid_q <= 1'b0;
            stream_contribution_q <= '0;
            activation_word_q <= '0;
            schedule_weight_pipe_q <= '0;
            schedule_valid_pipe_q <= 1'b0;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: begin
                    if (start) begin
                        busy <= 1'b1;
                        attack <= 1'b0;
                        activation_0 <= '0;
                        activation_1 <= '0;
                        activation_2 <= '0;
                        l0_neuron <= '0;
                        accumulator <= '0;
                        state <= L0_LOAD;
                    end
                end
                L0_LOAD: begin
                    l0_weight_q <= l0_weight_memory[l0_neuron];
                    l0_mask_q <= l0_mask_memory[l0_neuron];
                    l0_feature <= '0;
                    accumulator <= '0;
                    state <= L0_ACCUMULATE;
                end
                L0_ACCUMULATE: begin
                    if (l0_feature == 6'd48) begin
                        if (l0_direction_memory[l0_neuron])
                            activation_0[l0_neuron] <=
                                (accumulator + l0_contribution >= l0_threshold_memory[l0_neuron]);
                        else
                            activation_0[l0_neuron] <=
                                (accumulator + l0_contribution <= l0_threshold_memory[l0_neuron]);
                        if (l0_neuron == 8'd255) begin
                            schedule_index <= '0;
                            accumulator <= '0;
                            state <= STREAM_LOAD;
                        end else begin
                            l0_neuron <= l0_neuron + 1'b1;
                            state <= L0_LOAD;
                        end
                    end else begin
                        accumulator <= accumulator + l0_contribution;
                        l0_feature <= l0_feature + 1'b1;
                    end
                end
                STREAM_LOAD: begin
                    schedule_weight_q <= schedule_weight_memory[schedule_index];
                    schedule_address_q <= schedule_address_memory[schedule_index];
                    schedule_neuron_q <= schedule_neuron_memory[schedule_index];
                    schedule_layer_q <= schedule_layer_memory[schedule_index];
                    schedule_last_q <= schedule_last_memory[schedule_index];
                    schedule_valid_q <= schedule_valid_memory[schedule_index];
                    state <= STREAM_ACTIVATION;
                end
                STREAM_ACTIVATION: begin
                    // Isolate the schedule ROM and activation-word mux from
                    // the XNOR--popcount tree.  Quartus identified this as the
                    // remaining 80 MHz critical path after the first pipeline.
                    activation_word_q <= activation_word;
                    schedule_weight_pipe_q <= schedule_weight_q;
                    schedule_valid_pipe_q <= schedule_valid_q;
                    state <= STREAM_POPCOUNT;
                end
                STREAM_POPCOUNT: begin
                    // Register the XNOR--popcount result before the accumulator
                    // and threshold comparison.  This breaks the post-fit
                    // critical path from schedule ROM through activation mux,
                    // popcount, accumulator, and comparator.
                    stream_contribution_q <= stream_contribution;
                    state <= STREAM_ACCUMULATE;
                end
                STREAM_ACCUMULATE: begin
                    if (schedule_last_q) begin
                        case (schedule_layer_q)
                            2'd1: begin
                                if (l1_direction_memory[schedule_neuron_q])
                                    activation_1[schedule_neuron_q] <=
                                        (accumulator + stream_contribution_q >=
                                         l1_threshold_memory[schedule_neuron_q]);
                                else
                                    activation_1[schedule_neuron_q] <=
                                        (accumulator + stream_contribution_q <=
                                         l1_threshold_memory[schedule_neuron_q]);
                            end
                            2'd2: begin
                                if (l2_direction_memory[schedule_neuron_q])
                                    activation_2[schedule_neuron_q] <=
                                        (accumulator + stream_contribution_q >=
                                         l2_threshold_memory[schedule_neuron_q]);
                                else
                                    activation_2[schedule_neuron_q] <=
                                        (accumulator + stream_contribution_q <=
                                         l2_threshold_memory[schedule_neuron_q]);
                            end
                            default: begin
                                attack <= (accumulator + stream_contribution_q >=
                                           output_threshold_memory[0]);
                            end
                        endcase
                        accumulator <= '0;
                    end else begin
                        accumulator <= accumulator + stream_contribution_q;
                    end
                    if (schedule_index == SCHEDULE_ENTRIES - 1) begin
                        busy <= 1'b0;
                        done <= 1'b1;
                        state <= IDLE;
                    end else begin
                        schedule_index <= schedule_index + 1'b1;
                        state <= STREAM_LOAD;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
