`timescale 1ns/1ps

module tb_mac_pe;

  // Clock/reset
  logic clk = 0;
  logic rst_n = 0;

  // DUT inputs
  logic signed [7:0] a_in, b_in;
  logic run, acc_clear;

  // DUT outputs
  logic signed [7:0]  a_out, b_out;
  logic signed [31:0] acc_out;

  // Instantiate DUT
  mac_pe dut (
    .clk(clk),
    .rst_n(rst_n),
    .a_in(a_in),
    .b_in(b_in),
    .run(run),
    .acc_clear(acc_clear),
    .a_out(a_out),
    .b_out(b_out),
    .acc_out(acc_out)
  );

  // 100MHz clock (10ns period)
  always #5 clk <= ~clk;

  // Simple assertion helper
  task automatic expect_equal32(input logic signed [31:0] got, input logic signed [31:0] exp, input string msg);
    if (got !== exp) begin
      $display("FAIL: %s | got=%0d (0x%08h) exp=%0d (0x%08h)", msg, got, got, exp, exp);
      $fatal(1);
    end
  endtask

  task automatic expect_equal8(input logic signed [7:0] got, input logic signed [7:0] exp, input string msg);
    if (got !== exp) begin
      $display("FAIL: %s | got=%0d (0x%02h) exp=%0d (0x%02h)", msg, got, got, exp, exp);
      $fatal(1);
    end
  endtask

  // Reference model state
  logic signed [31:0] acc_ref;
  logic signed [7:0]  a_prev, b_prev;

  initial begin
    // Init
    a_in = '0; b_in = '0;
    run = 1'b0; acc_clear = 1'b0;
    acc_ref = 32'sd0;
    a_prev = 8'sd0; b_prev = 8'sd0;

    // Hold reset for 2 cycles
    rst_n = 1'b0;
    repeat (2) @(posedge clk);

    // Release reset
    rst_n = 1'b1;
    @(posedge clk);

    // After reset, outputs should be 0
    expect_equal32(acc_out, 32'sd0, "acc_out after reset");
    expect_equal8(a_out, 8'sd0, "a_out after reset");
    expect_equal8(b_out, 8'sd0, "b_out after reset");

    // ----------------------------
    // Test 1: Forwarding is 1-cycle delayed
    // ----------------------------
    a_in = 8'sd11; b_in = 8'sd22;
    run = 1'b0; acc_clear = 1'b0;
    a_prev = a_in; b_prev = b_in;
    @(posedge clk);
    // a_out/b_out now should equal previous cycle inputs
    expect_equal8(a_out, a_prev, "a_out forwarding 1-cycle");
    expect_equal8(b_out, b_prev, "b_out forwarding 1-cycle");

    // ----------------------------
    // Test 2: run=1 accumulates
    // acc += a*b each cycle
    // ----------------------------
    acc_ref = acc_out;

    // Cycle A: 3*5 = 15
    a_in = 8'sd3; b_in = 8'sd5;
    run = 1'b1; acc_clear = 1'b0;
    @(posedge clk);
    acc_ref = acc_ref + (3*5);
    expect_equal32(acc_out, acc_ref, "accumulate 3*5");

    // Cycle B: -2*7 = -14
    a_in = -8'sd2; b_in = 8'sd7;
    @(posedge clk);
    acc_ref = acc_ref + ((-2)*7);
    expect_equal32(acc_out, acc_ref, "accumulate -2*7");

    // ----------------------------
    // Test 3: run=0 holds
    // ----------------------------
    a_in = 8'sd9; b_in = 8'sd9;
    run = 1'b0;
    @(posedge clk);
    expect_equal32(acc_out, acc_ref, "hold when run=0");

    // ----------------------------
    // Test 4: acc_clear priority over run
    // ----------------------------
    a_in = 8'sd10; b_in = 8'sd10;
    run = 1'b1;
    acc_clear = 1'b1;
    @(posedge clk);
    acc_ref = 32'sd0;
    expect_equal32(acc_out, acc_ref, "acc_clear priority over run");

    // Deassert clear, accumulate again: 4*6=24
    acc_clear = 1'b0;
    a_in = 8'sd4; b_in = 8'sd6;
    run = 1'b1;
    @(posedge clk);
    acc_ref = acc_ref + (4*6);
    expect_equal32(acc_out, acc_ref, "accumulate after clear 4*6");

    $display("PASS: tb_mac_pe");
    $finish;
  end

endmodule
