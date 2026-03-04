`timescale 1ns/1ps

module tb_mac_array_2x2;

  localparam int ROWS = 2;
  localparam int COLS = 2;
  localparam int K    = 2;

  // Clock/reset
  logic clk = 0;
  logic rst_n = 0;

  // Control
  logic run;
  logic acc_clear;

  // Boundary injections
  logic signed [ROWS-1:0][7:0] a_in;
  logic signed [COLS-1:0][7:0] b_in;

  // Outputs
  logic [ROWS-1:0][COLS-1:0] out_valid;
  logic done;
  logic signed [ROWS-1:0][COLS-1:0][31:0] acc_out;
  logic signed [31:0] exp_C [ROWS-1:0][COLS-1:0];

  // DUT
  mac_array #(
    .ROWS(ROWS),
    .COLS(COLS),
    .DEPTH(K)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .run(run),
    .acc_clear(acc_clear),
    .a_in(a_in),
    .b_in(b_in),
    .out_valid(out_valid),
    .done(done),
    .acc_out(acc_out)
  );

  // 100MHz clock
  always #5 clk <= ~clk;

  // Expect helper
  task automatic expect_equal32(
    input logic signed [31:0] got,
    input logic signed [31:0] exp,
    input string msg
  );
    if (got !== exp) begin
      $display("FAIL: %s | got=%0d (0x%08h) exp=%0d (0x%08h)", msg, got, got, exp, exp);
      $fatal(1);
    end
  endtask

  // Example matrices:
  // A (ROWS x K) = [[1,2],[3,4]]
  // B (K x COLS) = [[5,6],[7,8]]
  logic signed [7:0] A [ROWS][K];
  logic signed [7:0] B [K][COLS];

  int t_last;

  initial begin
    // Initialize matrices
    A[0][0] = 8'sd1; A[0][1] = 8'sd2;
    A[1][0] = 8'sd3; A[1][1] = 8'sd4;

    B[0][0] = 8'sd5; B[0][1] = 8'sd6;
    B[1][0] = 8'sd7; B[1][1] = 8'sd8;

    // Init inputs
    run = 1'b0;
    acc_clear = 1'b0;
    for (int i = 0; i < ROWS; i++) a_in[i] = '0;
    for (int j = 0; j < COLS; j++) b_in[j] = '0;

    // Reset
    rst_n = 1'b0;
    repeat (2) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    // Optional clear pulse (keeps behavior deterministic even if reset changes later)
    acc_clear = 1'b1;
    @(posedge clk);
    acc_clear = 1'b0;

    // ----------------------------
    // Skewed wavefront injection
    //
    // Boundary rule at cycle t:
    //   A_in[i] = A[i][k] where k = t - i
    //   B_in[j] = B[k][j] where k = t - j
    // Out-of-range k -> inject 0
    //
    // Inside PE(i,j), due to registered forwarding,
    // operands align as k = t - i - j.
    // ----------------------------

    for (int i = 0; i < ROWS; i++)
      for (int j = 0; j < COLS; j++) begin
        exp_C[i][j] = 0;
        for (int k = 0; k < K; k++)
          exp_C[i][j] += $signed(A[i][k]) * $signed(B[k][j]);
      end
    run = 1'b1;

    // Run for T cycles where last useful k reaches PE(ROWS-1, COLS-1):
    // t_last = (K-1) + (ROWS-1) + (COLS-1)
    t_last = (K-1) + (ROWS-1) + (COLS-1);

    for (int t = 0; t <= t_last; t++) begin
      // Drive left edge A
      for (int i = 0; i < ROWS; i++) begin
        int kA = t - i;
        if (kA >= 0 && kA < K) a_in[i] = A[i][kA];
        else                   a_in[i] = '0;
      end

      // Drive top edge B
      for (int j = 0; j < COLS; j++) begin
        int kB = t - j;
        if (kB >= 0 && kB < K) b_in[j] = B[kB][j];
        else                   b_in[j] = '0;
      end

      @(posedge clk);
    end

    // Stop injecting but keep run until done
    for (int i = 0; i < ROWS; i++) a_in[i] = '0;
    for (int j = 0; j < COLS; j++) b_in[j] = '0;

    do @(posedge clk); while (!done);

    run = 1'b0;
    @(posedge clk);

    // Expected C = A*B
    // C00=19, C01=22, C10=43, C11=50
    expect_equal32(acc_out[0][0], 32'sd19, "C[0][0]");
    expect_equal32(acc_out[0][1], 32'sd22, "C[0][1]");
    expect_equal32(acc_out[1][0], 32'sd43, "C[1][0]");
    expect_equal32(acc_out[1][1], 32'sd50, "C[1][1]");

    $display("PASS: tb_mac_array_2x2");
    $finish;
  end

  // ------------------------------------------------------------
  // out_valid checker
  // ------------------------------------------------------------
  always_ff @(posedge clk) begin
    if (run) begin
      for (int i = 0; i < ROWS; i++) begin
        for (int j = 0; j < COLS; j++) begin
          if (out_valid[i][j]) begin
            if ($signed(acc_out[i][j]) !== $signed(exp_C[i][j])) begin
              $display("Mismatch @ out_valid[%0d][%0d]: got=%0d exp=%0d",
                       i, j, $signed(acc_out[i][j]), $signed(exp_C[i][j]));
              $fatal;
            end
          end
        end
      end
    end
  end
endmodule
