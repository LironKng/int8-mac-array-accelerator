`timescale 1ns/1ps

module tb_mac_array_param;

  // ---- Parameters for this regression ----
  localparam int ROWS  = 4;
  localparam int COLS  = 4;
  localparam int K     = 4;
  localparam int NTEST = 100;

  // ---- Clock/reset ----
  logic clk = 0;
  logic rst_n = 0;

  // ---- Control ----
  logic run;
  logic acc_clear;

  // Packed array ports (Verilator-friendly)
  logic signed [ROWS-1:0][7:0] a_in;
  logic signed [COLS-1:0][7:0] b_in;

  logic signed [ROWS-1:0][COLS-1:0][31:0] acc_out;

  // DUT
  mac_array #(
    .ROWS(ROWS),
    .COLS(COLS)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .run(run),
    .acc_clear(acc_clear),
    .a_in(a_in),
    .b_in(b_in),
    .acc_out(acc_out)
  );

  always #5 clk <= ~clk;

  // Matrices and reference
  logic signed [7:0]  A [ROWS][K];
  logic signed [7:0]  B [K][COLS];
  logic signed [31:0] C_ref [ROWS][COLS];

  // Simple deterministic PRNG (xorshift32)
  int unsigned seed = 32'hC0FFEE42;

  function automatic int unsigned xorshift32(input int unsigned x);
    x ^= (x << 13);
    x ^= (x >> 17);
    x ^= (x << 5);
    return x;
  endfunction

  function automatic logic signed [7:0] rand_s8();
    int unsigned r;
    byte signed v8;              // exactly 8-bit signed
    begin
      seed = xorshift32(seed);
      r = seed;
  
      // Map to [-8..+7] as an 8-bit signed value
      v8 = byte'(int'(r % 16) - 8);
  
      return v8;
    end
  endfunction

  task automatic clear_inputs();
    for (int i = 0; i < ROWS; i++) a_in[i] = '0;
    for (int j = 0; j < COLS; j++) b_in[j] = '0;
  endtask

  task automatic compute_ref();
    for (int i = 0; i < ROWS; i++) begin
      for (int j = 0; j < COLS; j++) begin
        C_ref[i][j] = 32'sd0;
        for (int k = 0; k < K; k++) begin
          C_ref[i][j] += $signed(A[i][k]) * $signed(B[k][j]);
        end
      end
    end
  endtask

  task automatic expect_all();
    for (int i = 0; i < ROWS; i++) begin
      for (int j = 0; j < COLS; j++) begin
        if (acc_out[i][j] !== C_ref[i][j]) begin
          $display("FAIL: C[%0d][%0d] got=%0d exp=%0d (0x%08h vs 0x%08h)",
                   i, j, acc_out[i][j], C_ref[i][j], acc_out[i][j], C_ref[i][j]);
          $fatal(1);
        end
      end
    end
  endtask

  task automatic pulse_clear();
    acc_clear = 1'b1;
    @(posedge clk);
    acc_clear = 1'b0;
  endtask

  task automatic run_one_case();
    int t_last;
    begin
      // Clear accumulator
      run = 1'b0;
      pulse_clear();

      // Drive skewed wavefront for t = 0..t_last
      run = 1'b1;
      t_last = (K-1) + (ROWS-1) + (COLS-1);

      for (int t = 0; t <= t_last; t++) begin
        // A boundary: A_in[i] = A[i,k], k=t-i
        for (int i = 0; i < ROWS; i++) begin
          int kA = t - i;
          if (kA >= 0 && kA < K) a_in[i] = A[i][kA];
          else                   a_in[i] = '0;
        end

        // B boundary: B_in[j] = B[k,j], k=t-j
        for (int j = 0; j < COLS; j++) begin
          int kB = t - j;
          if (kB >= 0 && kB < K) b_in[j] = B[kB][j];
          else                   b_in[j] = '0;
        end

        @(posedge clk);
      end

      // Stop injecting, allow pipeline flush (registered forwarding)
      run = 1'b0;
      clear_inputs();
      repeat (2) @(posedge clk);

      expect_all();
    end
  endtask

  initial begin
    // Init
    run = 1'b0;
    acc_clear = 1'b0;
    clear_inputs();

    // Reset
    rst_n = 1'b0;
    repeat (2) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    // Run NTEST deterministic random cases
    for (int tc = 0; tc < NTEST; tc++) begin
      // Generate random A,B (small signed values)
      for (int i = 0; i < ROWS; i++)
        for (int k = 0; k < K; k++)
          A[i][k] = rand_s8();

      for (int k = 0; k < K; k++)
        for (int j = 0; j < COLS; j++)
          B[k][j] = rand_s8();

      compute_ref();
      run_one_case();
    end

    $display("PASS: tb_mac_array_param (%0d cases)", NTEST);
    $finish;
  end

endmodule
