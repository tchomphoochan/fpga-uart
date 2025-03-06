#!/usr/bin/env python3

import cocotb
import os
import sys

from pathlib import Path
from cocotb.clock import Clock
from cocotb.triggers import (
    ClockCycles,
    ReadWrite,
    RisingEdge,
)
from cocotb.log import SimLog
from cocotb.runner import get_runner

import axis_tools

CLOCK_FREQ_HZ = 100
BAUD_RATE = 5

IDLE_BIT = 1
START_BIT = 0
STOP_BIT = 1


async def resetn(clk, rstn):
    await RisingEdge(clk)
    await ReadWrite()
    rstn.value = 0
    await ClockCycles(clk, 5)
    await ReadWrite()
    rstn.value = 1


async def uart_cycle(clk):
    await ClockCycles(clk, CLOCK_FREQ_HZ // BAUD_RATE)


async def send_uart(clk, tx, byte):
    tx.value = START_BIT
    await uart_cycle(clk)
    for i in range(8):
        bit = (byte >> i) & 0x01
        tx.value = bit
        await uart_cycle(clk)
    tx.value = STOP_BIT
    await uart_cycle(clk)


@cocotb.test()
async def test_basic(dut):
    clk = dut.m_axis_aclk
    rstn = dut.m_axis_aresetn
    cocotb.start_soon(Clock(clk, 10, units="ns").start())
    await resetn(clk, rstn)
    dut.rx_bit.value = IDLE_BIT
    dut.m_axis_tready.value = 1

    logger = SimLog("cocotb.tb.monitor_cb")

    received_word = ""

    def cb(txn):
        nonlocal received_word
        logger.info(f"Received from uart_rx: {txn} ({chr(int(txn))!r})")
        received_word = received_word + chr(int(txn))

    await ClockCycles(clk, 100)
    monitor = axis_tools.AXISMonitor(dut, "m", clk, callback=cb)
    word = "Hello! Welcome to sim_uart_rx.py. This is a very long message so we'll see how well this actually works."
    for byte in list(word.encode("utf-8")):
        await send_uart(clk, dut.rx_bit, byte)

    await ClockCycles(clk, CLOCK_FREQ_HZ // BAUD_RATE * 2)
    assert word == received_word


def test_runner():
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "uart_rx.sv"]
    build_test_args = ["-Wall"]
    parameters = {"CLOCK_FREQ_HZ": CLOCK_FREQ_HZ, "BAUD_RATE": BAUD_RATE}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="uart_rx",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale=("1ns", "1ps"),
        waves=True,
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="uart_rx",
        test_module="sim_uart_rx",
        test_args=run_test_args,
        waves=True,
    )


if __name__ == "__main__":
    test_runner()
