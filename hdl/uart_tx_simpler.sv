`default_nettype none

/*
8N1 UART transmitter.
Takes in only one byte at a time.
*/
module uart_tx_simpler #(
    parameter CLOCK_FREQ_HZ = 0,
    parameter BAUD_RATE = 0
) (
    // axi inputs
    input wire s_axis_aclk,
    input wire s_axis_aresetn,
    input wire s_axis_tvalid,
    input wire [7:0] s_axis_tdata,
    output logic s_axis_tready,
    // uart outputs
    output logic tx_bit
);

  localparam IDLE = 0;
  localparam START = 1;
  localparam DATA_0 = 2;
  localparam DATA_7 = 9;
  localparam STOP = 10;
  logic [3:0] state = IDLE;

  localparam UART_CYCLES = CLOCK_FREQ_HZ / BAUD_RATE;
  localparam UART_CYCLES_BITS = $clog2(UART_CYCLES);
  logic [UART_CYCLES_BITS-1:0] cycle_count;

  logic end_of_cycle;
  assign end_of_cycle = cycle_count == UART_CYCLES - 1;

  logic [7:0] data_latched;

  always_ff @(posedge s_axis_aclk) begin
    if (state == IDLE) begin
      if (s_axis_tvalid && s_axis_tready) begin
        data_latched <= s_axis_tdata;
        state <= START;
        cycle_count <= 0;
      end
    end else begin
      if (end_of_cycle) begin
        if (state >= DATA_0 && state <= DATA_7) data_latched <= data_latched >> 1;
        state <= state == STOP ? IDLE : state + 1;
        cycle_count <= 0;
      end else begin
        cycle_count <= cycle_count + 1;
      end
    end

    if (s_axis_aresetn == 0) begin
      state <= IDLE;
    end
  end

  localparam IDLE_BIT = 1'b1;
  localparam START_BIT = 1'b0;
  localparam STOP_BIT = 1'b1;

  assign s_axis_tready = state == IDLE;
  always_comb begin
    tx_bit = data_latched[0];
    if (state == IDLE) tx_bit = IDLE_BIT;
    if (state == START) tx_bit = START_BIT;
    if (state == STOP) tx_bit = STOP_BIT;
  end

endmodule

`default_nettype wire
