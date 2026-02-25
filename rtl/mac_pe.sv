// ============================================================
// INT8 MAC Processing Element (PE)
// v1.0 — Single-cycle MAC, wrap-around arithmetic
// ============================================================

module mac_pe (
    input  logic                clk,
    input  logic                rst_n,

    // Datapath inputs
    input  logic signed [7:0]   a_in,
    input  logic signed [7:0]   b_in,

    // Control
    input  logic                run,
    input  logic                acc_clear,

    // Forwarded outputs
    output logic signed [7:0]   a_out,
    output logic signed [7:0]   b_out,

    // Accumulator output
    output logic signed [31:0]  acc_out
);

    // Internal accumulator register
    logic signed [31:0] acc;

    // Multiply (combinational)
    logic signed [31:0] product;
    assign product = $signed(a_in) * $signed(b_in);

    // Sequential logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc    <= '0;
            a_out  <= '0;
            b_out  <= '0;
        end
        else begin
            // Forwarding (registered hop)
            a_out <= a_in;
            b_out <= b_in;

            // Accumulator update
            if (acc_clear) begin
                acc <= '0;
            end
            else if (run) begin
                acc <= acc + product;
            end
        end
    end

    assign acc_out = acc;

endmodule
