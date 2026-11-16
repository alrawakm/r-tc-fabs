`timescale 1ns/1ps
// Matched internal-core activity: same vectors, clock and transaction protocol.
// Excludes feature extraction and transport; not a physical power measurement.
module tb_power;
    logic clk=0, reset_n=0, start=0;
    logic signed [391:0] features_q=0;
    logic busy,done,attack;
    logic [391:0] vectors [0:9999];
    logic expected [0:9999];
    integer i,cycles;
    integer expected_cycles=10116;
    string output_vcd="power_activity.vcd";
    always #6.667 clk=~clk; // 74.996 MHz, shared by both variants
    skip_top dut(.*);
    initial begin
        if ($value$plusargs("CYCLES=%d",expected_cycles)) begin end
        if ($value$plusargs("VCD=%s",output_vcd)) begin end
        $readmemh("generated/r_tc_fabs_nfbot/full_inputs.hex",vectors);
        $readmemh("generated/r_tc_fabs_nfbot/full_expected_sparse.hex",expected);
        $dumpfile(output_vcd);
        $dumpvars(0,tb_power.dut);
        #30 reset_n=1;
        for(i=0;i<32;i=i+1) begin
            @(negedge clk); features_q=vectors[i];start=1;
            @(negedge clk);start=0;cycles=0;
            while(!done && cycles<25000) begin
                @(negedge clk);cycles=cycles+1;
            end
            if(!done || attack !== expected[i] || cycles != expected_cycles)
                $fatal(1,"FAIL vector=%0d cycles=%0d expected_cycles=%0d",i,cycles,expected_cycles);
        end
        $display("PASS power_vectors=32 cycles=%0d half_period_ns=6.667",expected_cycles);
        $finish;
    end
endmodule
