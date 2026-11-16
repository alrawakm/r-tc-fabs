module r_tc_fabs_folded_network_top (
    input logic clk,
    input logic reset_n,
    input logic start,
    input logic signed [391:0] features_q,
    output logic busy,
    output logic done,
    output logic attack
);
    tc_fabs_folded_network #(
        .SCHEDULE_ENTRIES(417),
        .L0_WEIGHT_FILE("../../rtl/generated/r_tc_fabs_nfbot/network/network_l0_weights.hex"),
        .L0_MASK_FILE("../../rtl/generated/r_tc_fabs_nfbot/network/network_l0_masks.hex"),
        .L0_THRESHOLD_FILE("../../rtl/generated/r_tc_fabs_nfbot/network/network_l0_thresholds.hex"),
        .L0_DIRECTION_FILE("../../rtl/generated/r_tc_fabs_nfbot/network/network_l0_directions.hex"),
        .L1_THRESHOLD_FILE("../../rtl/generated/r_tc_fabs_nfbot/network/network_l1_thresholds.hex"),
        .L1_DIRECTION_FILE("../../rtl/generated/r_tc_fabs_nfbot/network/network_l1_directions.hex"),
        .L2_THRESHOLD_FILE("../../rtl/generated/r_tc_fabs_nfbot/network/network_l2_thresholds.hex"),
        .L2_DIRECTION_FILE("../../rtl/generated/r_tc_fabs_nfbot/network/network_l2_directions.hex"),
        .SCHEDULE_WEIGHT_FILE("../../rtl/generated/r_tc_fabs_nfbot/network/network_schedule_weights.hex"),
        .SCHEDULE_ADDRESS_FILE("../../rtl/generated/r_tc_fabs_nfbot/network/network_schedule_addresses.hex"),
        .SCHEDULE_NEURON_FILE("../../rtl/generated/r_tc_fabs_nfbot/network/network_schedule_neurons.hex"),
        .SCHEDULE_LAYER_FILE("../../rtl/generated/r_tc_fabs_nfbot/network/network_schedule_layers.hex"),
        .SCHEDULE_LAST_FILE("../../rtl/generated/r_tc_fabs_nfbot/network/network_schedule_last.hex"),
        .SCHEDULE_VALID_FILE("../../rtl/generated/r_tc_fabs_nfbot/network/network_schedule_valid.hex"),
        .OUTPUT_THRESHOLD_FILE("../../rtl/generated/r_tc_fabs_nfbot/network/network_output_threshold.hex")
    ) engine (.*);
endmodule
