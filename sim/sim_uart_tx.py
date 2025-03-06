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


async def resetn(clk, rstn):
    await RisingEdge(clk)
    await ReadWrite()
    rstn.value = 0
    await ClockCycles(clk, 5)
    await ReadWrite()
    rstn.value = 1


@cocotb.test()
async def test_basic(dut):
    clk = dut.s_axis_aclk
    rstn = dut.s_axis_aresetn
    cocotb.start_soon(Clock(clk, 10, units="ns").start())
    await resetn(clk, rstn)

    logger = SimLog("cocotb.tb.monitor_cb")

    def cb(txn):
        logger.info(f"Sent to uart_tx: {txn}")

    driver = axis_tools.AXISDriver(dut, "s", clk)
    monitor = axis_tools.AXISMonitor(dut, "s", clk, callback=cb)

    driver.append(0b01010101)
    driver.append(0b11001100)
    driver.append(0b10000001)

    await ClockCycles(clk, 500)


def test_runner():
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "uart_tx.sv"]
    build_test_args = ["-Wall"]
    parameters = {"CLOCK_FREQ_HZ": 10, "BAUD_RATE": 2}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="uart_tx",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale=("1ns", "1ps"),
        waves=True,
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="uart_tx",
        test_module="sim_uart_tx",
        test_args=run_test_args,
        waves=True,
    )


if __name__ == "__main__":
    test_runner()
