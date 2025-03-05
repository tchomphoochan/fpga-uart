`default_nettype none

/*
Counts up by one every clock cycle `in` is high.
*/
module cycle_counter #(
    parameter COUNT_BITS = 0
) (
    input wire clk,
    input wire rst,
    input wire in,
    output logic [COUNT_BITS-1 : 0] count = 0
);

  always_ff @(posedge clk) begin
    if (in) count <= count + 1;
    if (rst) count <= 0;
  end

endmodule

`default_nettype wire
