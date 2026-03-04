// ============================================================
// MAC Array Module
// v1.0 — 2D array of INT8 MAC PEs, with shared control signals
// ============================================================

module mac_array #(
    parameter ROWS = 2,
    parameter COLS = 2,
    parameter DEPTH = 4   // K
)(
    input  logic clk,
    input  logic rst_n,

    input  logic run,
    input  logic acc_clear,

    input  logic signed [ROWS-1:0][7:0]  a_in,
    input  logic signed [COLS-1:0][7:0]  b_in,

    output logic [ROWS-1:0][COLS-1:0] out_valid,
    output logic done,
    output logic signed [ROWS-1:0][COLS-1:0][31:0] acc_out
);

  // Count cycles since run started (t = 0..)
  localparam int TMAX = DEPTH + ROWS + COLS + 4;
  localparam int TW   = $clog2(TMAX);

  logic [TW-1:0] t_cnt;
  localparam int DONE_T_INT = (DEPTH-1) + (ROWS-1) + (COLS-1);
  localparam logic [TW-1:0] DONE_T = TW'(DONE_T_INT);

  int i, j;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      t_cnt     <= '0;
      out_valid <= '0;
      done      <= 1'b0;
    end else begin
      // Defaults (avoid latches / carry-over)
      out_valid <= '0;

      // Highest priority: clear
      if (acc_clear) begin
        t_cnt <= '0;
        done  <= 1'b0;

      // Idle when run is low
      end else if (!run) begin
        t_cnt <= '0;
        done  <= 1'b0;

      end else begin
        // run==1: generate per-cell valid pulses (still 1-cycle each)
        for (i = 0; i < ROWS; i++) begin
          for (j = 0; j < COLS; j++) begin
            out_valid[i][j] <= (t_cnt == TW'((i + j + (DEPTH-1))));
          end
        end

        // Sticky done: once asserted, keep it high
        if (!done && (t_cnt == DONE_T)) begin
          done <= 1'b1;
        end

        // Counter: advance only until done (prevents wraparound)
        if (!done) begin
          t_cnt <= t_cnt + 1'b1;
        end else begin
          t_cnt <= t_cnt; // hold
        end
      end
    end
  end

  // Internal meshes for forwarding
  wire signed [7:0] a_mesh [ROWS][COLS+1];
  wire signed [7:0] b_mesh [ROWS+1][COLS];

  // Generate a 2D array of MAC PEs
  genvar gi, gj;
  generate
      for (gi = 0; gi < ROWS; gi++) begin : row_loop
          for (gj = 0; gj < COLS; gj++) begin : col_loop
              mac_pe pe (
                  .clk(clk),
                  .rst_n(rst_n),
                  .a_in(a_mesh[gi][gj]),
                  .b_in(b_mesh[gi][gj]),
                  .run(run),
                  .acc_clear(acc_clear),
                  .a_out(a_mesh[gi][gj+1]),
                  .b_out(b_mesh[gi+1][gj]),
                  .acc_out(acc_out[gi][gj])
              );
          end
      end
  endgenerate

  // Drive array boundaries (continuous wiring)
  genvar r, c;
  generate
    for (r = 0; r < ROWS; r++) begin : bind_a
      assign a_mesh[r][0] = a_in[r];
    end
    for (c = 0; c < COLS; c++) begin : bind_b
      assign b_mesh[0][c] = b_in[c];
    end
  endgenerate

endmodule
