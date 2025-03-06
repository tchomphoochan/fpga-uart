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

  wire clk_125mhz_ibufg;
  wire clk_125mhz_mmcm_out;
  wire clk;

  wire mmcm_rst = rst;
  wire mmcm_locked;
  wire mmcm_clkfb;

  IBUFGDS #(
      .DIFF_TERM("FALSE"),
      .IBUF_LOW_PWR("FALSE")
  ) clk_125mhz_ibufg_inst (
      .O (clk_125mhz_ibufg),
      .I (clk_125mhz_p),
      .IB(clk_125mhz_n)
  );

  MMCME3_BASE #(
      .BANDWIDTH("OPTIMIZED"),
      .CLKOUT0_DIVIDE_F(5),
      .CLKOUT0_DUTY_CYCLE(0.5),
      .CLKOUT0_PHASE(0),
      .CLKOUT1_DIVIDE(1),
      .CLKOUT1_DUTY_CYCLE(0.5),
      .CLKOUT1_PHASE(0),
      .CLKOUT2_DIVIDE(1),
      .CLKOUT2_DUTY_CYCLE(0.5),
      .CLKOUT2_PHASE(0),
      .CLKOUT3_DIVIDE(1),
      .CLKOUT3_DUTY_CYCLE(0.5),
      .CLKOUT3_PHASE(0),
      .CLKOUT4_DIVIDE(1),
      .CLKOUT4_DUTY_CYCLE(0.5),
      .CLKOUT4_PHASE(0),
      .CLKOUT5_DIVIDE(1),
      .CLKOUT5_DUTY_CYCLE(0.5),
      .CLKOUT5_PHASE(0),
      .CLKOUT6_DIVIDE(1),
      .CLKOUT6_DUTY_CYCLE(0.5),
      .CLKOUT6_PHASE(0),
      .CLKFBOUT_MULT_F(5),
      .CLKFBOUT_PHASE(0),
      .DIVCLK_DIVIDE(1),
      .REF_JITTER1(0.010),
      .CLKIN1_PERIOD(8.0),
      .STARTUP_WAIT("FALSE"),
      .CLKOUT4_CASCADE("FALSE")
  ) clk_mmcm_inst (
      .CLKIN1(clk_125mhz_ibufg),
      .CLKFBIN(mmcm_clkfb),
      .RST(mmcm_rst),
      .PWRDWN(1'b0),
      .CLKOUT0(clk_125mhz_mmcm_out),
      .CLKOUT0B(),
      .CLKOUT1(),
      .CLKOUT1B(),
      .CLKOUT2(),
      .CLKOUT2B(),
      .CLKOUT3(),
      .CLKOUT3B(),
      .CLKOUT4(),
      .CLKOUT5(),
      .CLKOUT6(),
      .CLKFBOUT(mmcm_clkfb),
      .CLKFBOUTB(),
      .LOCKED(mmcm_locked)
  );

  BUFG clk_125mhz_bufg_inst (
      .I(clk_125mhz_mmcm_out),
      .O(clk)
  );

  logic rstn;
  assign rstn = !rst;

  logic uart_rx_valid_out;
  logic [7:0] uart_rx_data_out;
  logic uart_rx_ready_in;

  uart_rx #(
      .CLOCK_FREQ_HZ(CLOCK_FREQ_HZ),
      .BAUD_RATE(BAUD_RATE)
  ) uart_rx_inst (
      .rx_bit(uart_rxd),
      .m_axis_aclk(clk),
      .m_axis_aresetn(rstn),
      .m_axis_tvalid(uart_rx_valid_out),
      .m_axis_tdata(uart_rx_data_out),
      .m_axis_tready(uart_rx_ready_in)
  );

  uart_tx #(
      .CLOCK_FREQ_HZ(CLOCK_FREQ_HZ),
      .BAUD_RATE(BAUD_RATE)
  ) uart_tx_inst (
      .tx_bit(uart_txd),
      .s_axis_aclk(clk),
      .s_axis_aresetn(rstn),
      .s_axis_tvalid(uart_rx_valid_out),
      .s_axis_tdata(uart_rx_data_out),
      .s_axis_tready(uart_rx_ready_in)
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
