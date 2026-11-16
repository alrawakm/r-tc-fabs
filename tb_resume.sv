`timescale 1ns/1ps

module tb_skip;
    localparam int VECTOR_COUNT = 10000;
    logic clk = 0;
    logic reset_n = 0;
    logic start = 0;
    logic signed [391:0] features_q;
    logic busy, done, attack;
    logic [391:0] vectors [0:VECTOR_COUNT-1];
    logic expected [0:VECTOR_COUNT-1];
    integer vector_count = 100;
    integer index, cycles, mismatches = 0; integer start_index=0;

    always #6.25 clk = ~clk;

    tc_fabs_skip_network #(
        .SCHEDULE_ENTRIES(417),
        .L0_WEIGHT_FILE("generated/r_tc_fabs_nfbot/network/network_l0_weights.hex"),
        .L0_MASK_FILE("generated/r_tc_fabs_nfbot/network/network_l0_masks.hex"),
        .L0_THRESHOLD_FILE("generated/r_tc_fabs_nfbot/network/network_l0_thresholds.hex"),
        .L0_DIRECTION_FILE("generated/r_tc_fabs_nfbot/network/network_l0_directions.hex"),
        .L1_THRESHOLD_FILE("generated/r_tc_fabs_nfbot/network/network_l1_thresholds.hex"),
        .L1_DIRECTION_FILE("generated/r_tc_fabs_nfbot/network/network_l1_directions.hex"),
        .L2_THRESHOLD_FILE("generated/r_tc_fabs_nfbot/network/network_l2_thresholds.hex"),
        .L2_DIRECTION_FILE("generated/r_tc_fabs_nfbot/network/network_l2_directions.hex"),
        .SCHEDULE_WEIGHT_FILE("generated/r_tc_fabs_nfbot/network/network_schedule_weights.hex"),
        .SCHEDULE_ADDRESS_FILE("generated/r_tc_fabs_nfbot/network/network_schedule_addresses.hex"),
        .SCHEDULE_NEURON_FILE("generated/r_tc_fabs_nfbot/network/network_schedule_neurons.hex"),
        .SCHEDULE_LAYER_FILE("generated/r_tc_fabs_nfbot/network/network_schedule_layers.hex"),
        .SCHEDULE_LAST_FILE("generated/r_tc_fabs_nfbot/network/network_schedule_last.hex"),
        .SCHEDULE_VALID_FILE("generated/r_tc_fabs_nfbot/network/network_schedule_valid.hex"),
        .OUTPUT_THRESHOLD_FILE("generated/r_tc_fabs_nfbot/network/network_output_threshold.hex")
    ) dut (.*);

    initial begin
        $readmemh("generated/r_tc_fabs_nfbot/full_inputs.hex", vectors);
        $readmemh("generated/r_tc_fabs_nfbot/full_expected_sparse.hex", expected);
        if (!$value$plusargs("COUNT=%d", vector_count)) vector_count = 100;
        if ($value$plusargs("START=%d", start_index)) begin end
        if (start_index < 0 || start_index >= vector_count) $fatal(1,"Invalid start");
        if (vector_count < 1 || vector_count > VECTOR_COUNT)
            $fatal(1, "Invalid vector count %0d", vector_count);
        $display("START vectors=%0d expected_cycles=10116", vector_count);
        $fflush();
        #20 reset_n = 1;
        for (index = start_index; index < vector_count; index = index + 1) begin
            @(negedge clk); features_q = vectors[index]; start = 1;
            @(negedge clk); start = 0; cycles = 0;
            while (!done && cycles < 25000) begin @(negedge clk); cycles = cycles + 1; end
            if (!done || attack !== expected[index] || cycles != 10116) begin
                mismatches = mismatches + 1;
                if (mismatches <= 10) $display("MISMATCH index=%0d expected=%0d actual=%0d cycles=%0d", index, expected[index], attack, cycles);
            end
            if ((index + 1) % 100 == 0) begin
                $display("PROGRESS checked=%0d total=%0d mismatches=%0d", index+1, vector_count, mismatches);
                $fflush();
            end
        end
        if (mismatches) $fatal(1, "FAIL vectors=%0d mismatches=%0d", vector_count, mismatches);
        $display("PASS start=%0d end=%0d mismatches=0 cycles_per_inference=%0d", start_index, vector_count, cycles);
        $finish;
    end
endmodule

