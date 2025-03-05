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
    clk, rst, input, count = dut.clk, dut.rst, getattr(dut, "in"), dut.count
    rst.value = 0
    input.value = 0

    cocotb.start_soon(Clock(clk, 10, units="ns").start())
    assert count.value == 0

    await ClockCycles(clk, 10)
    assert count.value == 0

    input.value = 1

    await ClockCycles(clk, 1)
    await ReadOnly()
    assert count.value == 1

    await ClockCycles(clk, 1)
    await ReadOnly()
    assert count.value == 2

    await ClockCycles(clk, 1)
    await ReadOnly()
    assert count.value == 3

    await ClockCycles(clk, 1)
    await ReadOnly()
    assert count.value == 0

    await ClockCycles(clk, 1)
    await ReadOnly()
    assert count.value == 1

    await ClockCycles(clk, 1)
    await ReadWrite()
    rst.value = 1
    await ReadOnly()
    assert count.value == 2

    await ClockCycles(clk, 1)
    await ReadWrite()
    rst.value = 0
    await ReadOnly()
    assert count.value == 0

    await ClockCycles(clk, 1)
    await ReadOnly()
    assert count.value == 1


def test_runner():
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "cycle_counter.sv"]
    build_test_args = ["-Wall"]
    parameters = {
        "COUNT_BITS": 2,
    }
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="cycle_counter",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale=("1ns", "1ps"),
        waves=True,
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="cycle_counter",
        test_module="sim_cycle_counter",
        test_args=run_test_args,
        waves=True,
    )


if __name__ == "__main__":
    test_runner()
