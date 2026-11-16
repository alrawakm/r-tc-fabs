`timescale 1ns/1ps
module tb_corners;
  logic clk=0, reset_n=0, start=0;
  logic signed [391:0] features_q=0;
  wire busy_s,done_s,attack_s,busy_b,done_b,attack_b;
  tc_fabs_skip_network #(.SCHEDULE_ENTRIES(417)) s(clk,reset_n,start,features_q,busy_s,done_s,attack_s);
  tc_fabs_baseline_network #(.SCHEDULE_ENTRIES(417)) b(clk,reset_n,start,features_q,busy_b,done_b,attack_b);
  always #5 clk=~clk;
  reg [63:0] masks[0:6];
  reg [63:0] mask;
  integer k,j,f,r,w,cycles,cs,cb,sum,expected_cycles,direction,delta;
  reg signed [7:0] feature;
  reg seen_s,seen_b,asaved;
  reg [255:0] l0saved;
  initial begin
    masks[0]=0; masks[1]=64'hffff000000000000; masks[2]=1;
    masks[3]=64'h1000000000000; masks[4]=64'h1ffffffffffff;
    masks[5]=64'h1555555555555; masks[6]=64'hffffffffffffffff;
    #1;
    for(k=0;k<7;k=k+1) begin
      for(f=0;f<64;f=f+1) begin
        r=49;
        for(j=48;j>=0;j=j-1) if(j>=f && masks[k][j]) r=j;
        if(s.next_active(masks[k],f)!==r[5:0]) $fatal(1,"next_active corner failure");
      end
    end
    // Full-controller comparison with empty, padding-only, endpoint, dense,
    // alternating and all-bit masks. Signed extrema and comparator ties included.
    for(k=0;k<7;k=k+1) for(direction=0;direction<2;direction=direction+1) begin
      reset_n=0; start=0; repeat(2) @(negedge clk);
      mask=masks[k]; s.l0_mask_memory[0]=mask; b.l0_mask_memory[0]=mask;
      s.l0_weight_memory[0]=64'haaaaaaaaaaaaaaaa; b.l0_weight_memory[0]=64'haaaaaaaaaaaaaaaa;
      sum=0;
      for(j=0;j<49;j=j+1) begin
        feature=(j%2==0) ? -128 : 127; features_q[j*8+:8]=feature;
        if(mask[j]) sum=sum+(j%2==1 ? feature : -$signed(feature));
      end
      // Exact threshold tie exercises both >= and <= directions.
      s.l0_threshold_memory[0]=sum; b.l0_threshold_memory[0]=sum;
      s.l0_direction_memory[0]=direction; b.l0_direction_memory[0]=direction;
      expected_cycles=256+4*417;
      for(j=0;j<256;j=j+1) begin
        w=0; for(f=0;f<49;f=f+1) if(s.l0_mask_memory[j][f]) w=w+1;
        expected_cycles=expected_cycles+(w==0 ? 1 : w);
      end
      reset_n=1; @(negedge clk); start=1; @(negedge clk); start=0;
      cycles=0; seen_s=0;seen_b=0;cs=0;cb=0;
      while((!seen_s || !seen_b) && cycles<25000) begin
        @(negedge clk); cycles=cycles+1;
        if(done_s) begin seen_s=1;cs=cycles;asaved=attack_s;l0saved=s.activation_0; end
        if(done_b) begin seen_b=1;cb=cycles; end
      end
      if(!seen_s || !seen_b || cs!=expected_cycles || cb!=14468 || asaved!==attack_b || l0saved!==b.activation_0 || l0saved[0]!==1'b1)
        $fatal(1,"FAIL mask=%0d direction=%0d cs=%0d expected=%0d cb=%0d",k,direction,cs,expected_cycles,cb);
      $display("PASS corner_mask=%0d direction=%0d skip_cycles=%0d baseline_cycles=%0d",k,direction,cs,cb);
    end
    $display("PASS next_active_checks=448 full_controller_corner_cases=14");
    $finish;
  end
endmodule
