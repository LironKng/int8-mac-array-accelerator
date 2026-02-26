// ============================================================
// MAC Array Module
// v1.0 — 2D array of INT8 MAC PEs, with shared control signals
// ============================================================

module mac_array #(
    parameter ROWS = 2,
    parameter COLS = 2
)(
    input  logic clk,
    input  logic rst_n,

    input  logic run,
    input  logic acc_clear,

    input  logic signed [ROWS-1:0][7:0]  a_in,
    input  logic signed [COLS-1:0][7:0]  b_in,
    output logic signed [ROWS-1:0][COLS-1:0][31:0] acc_out
);

    // Internal meshes for forwarding
    wire signed [7:0] a_mesh [ROWS][COLS+1];
    wire signed [7:0] b_mesh [ROWS+1][COLS];

    // Generate a 2D array of MAC PEs
    genvar i, j;
    generate
        for (i = 0; i < ROWS; i++) begin : row_loop
            for (j = 0; j < COLS; j++) begin : col_loop
                mac_pe pe (
                    .clk(clk),
                    .rst_n(rst_n),
                    .a_in(a_mesh[i][j]),
                    .b_in(b_mesh[i][j]),
                    .run(run),
                    .acc_clear(acc_clear),
                    .a_out(a_mesh[i][j+1]),
                    .b_out(b_mesh[i+1][j]),
                    .acc_out(acc_out[i][j])
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
