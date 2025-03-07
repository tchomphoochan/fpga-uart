`default_nettype none

module top_loopback #(
    parameter CLOCK_FREQ_HZ = 125_000_000,
    parameter BAUD_RATE = 115200
) (
    input wire rst,
    input wire clk_125mhz_p,
    input wire clk_125mhz_n,
    input wire uart_rxd,
    output logic uart_txd,
    output logic [7:0] led = 8'b0000_0001
);

  wire clk;

  IBUFGDS #(
      .DIFF_TERM("FALSE"),
      .IBUF_LOW_PWR("FALSE")
  ) clk_125mhz_ibufg_inst (
      .O (clk),
      .I (clk_125mhz_p),
      .IB(clk_125mhz_n)
  );

  logic rstn;
  assign rstn = !rst;

  logic rx_word_valid;
  logic [7:0] rx_word_content;
  logic rx_ready;

  logic tx_word_valid;
  logic [7:0] tx_word_content;
  logic tx_ready;

  uart_rx #(
      .CLOCK_FREQ_HZ(CLOCK_FREQ_HZ),
      .BAUD_RATE(BAUD_RATE)
  ) uart_rx_inst (
      .rx_bit(uart_rxd),
      .m_axis_aclk(clk),
      .m_axis_aresetn(rstn),
      .m_axis_tvalid(rx_word_valid),
      .m_axis_tdata(rx_word_content),
      .m_axis_tready(rx_ready)
  );

  axis_fifo_64x8 fifo_inst (
      .s_axis_aresetn(rstn),
      .s_axis_aclk(clk),
      .s_axis_tvalid(rx_word_valid),
      .s_axis_tready(rx_ready),
      .s_axis_tdata(rx_word_content),
      .m_axis_tvalid(tx_word_valid),
      .m_axis_tready(tx_ready),
      .m_axis_tdata(tx_word_content)
  );

  uart_tx #(
      .CLOCK_FREQ_HZ(CLOCK_FREQ_HZ),
      .BAUD_RATE(BAUD_RATE)
  ) uart_tx_inst (
      .tx_bit(uart_txd),
      .s_axis_aclk(clk),
      .s_axis_aresetn(rstn),
      .s_axis_tvalid(tx_word_valid),
      .s_axis_tdata(tx_word_content),
      .s_axis_tready(tx_ready)
  );

  logic [31:0] counter = 0;

  always_ff @(posedge clk) begin
    counter <= counter + 1;
    if (counter == (CLOCK_FREQ_HZ - 1) / 10) begin
      counter <= 0;
      led <= led == 8'b10000000 ? 8'b00000001 : (led << 1);
    end
  end

endmodule

`default_nettype wire
