module skip_top (
    input logic clk, reset_n, start,
    input logic signed [391:0] features_q,
    output logic busy, done, attack
);
    tc_fabs_skip_network #(.SCHEDULE_ENTRIES(417)) engine (.*);
endmodule
