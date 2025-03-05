#!/usr/bin/env python3

import cocotb
import os
import sys

from pathlib import Path
from cocotb.clock import Clock
from cocotb.triggers import (
    ClockCycles,
    ReadWrite,
    ReadOnly,
)
from cocotb.runner import get_runner


@cocotb.test()
async def test_basic(dut):
    clk = dut.s_axis_aclk
    cocotb.start_soon(Clock(clk, 10, units="ns").start())

    rstn = dut.s_axis_aresetn
    tvalid = dut.s_axis_tvalid
    tdata = dut.s_axis_tdata
    tready = dut.s_axis_tready

    rstn.value = 0
    tvalid.value = 0
    tdata.value = 0
    await ClockCycles(clk, 5)
    rstn.value = 1

    await ClockCycles(clk, 5)
    await ReadWrite()
    tvalid.value = 1
    tdata.value = 0b01010101

    await ClockCycles(clk, 1)
    await ReadWrite()
    tvalid.value = 0

    await ClockCycles(clk, 100)


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
