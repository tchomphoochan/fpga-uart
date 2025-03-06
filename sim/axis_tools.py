import cocotb

from cocotb.triggers import (
    ReadWrite,
    RisingEdge,
)

from cocotb_bus.drivers import BusDriver
from cocotb_bus.monitors import BusMonitor
from cocotb_bus.scoreboard import Scoreboard


"""
Monitors a simple AXI4-Stream bus.
"""


class AXISMonitor(BusMonitor):
    def __init__(self, dut, name, clk, *args, **kwargs):
        BusMonitor.__init__(self, dut, name, clk, *args, **kwargs)
        self.bus._add_signal("tvalid", f"{self.name}_axis_tvalid")
        self.bus._add_signal("tready", f"{self.name}_axis_tready")
        self.bus._add_signal("tdata", f"{self.name}_axis_tdata")

    async def _monitor_recv(self):
        while True:
            await RisingEdge(self.clock)

            if self.bus.tvalid.value and self.bus.tready.value:
                self._recv(self.bus.tdata)


"""
Drives a simple AXI4-Stream bus with no bursting.
"""


class AXISDriver(BusDriver):
    def __init__(self, dut, name, clk, *args, **kwargs):
        self._signals = []
        self._optional_signals = []
        BusDriver.__init__(self, dut, name, clk, *args, **kwargs)
        self.bus._add_signal("tvalid", f"{self.name}_axis_tvalid")
        self.bus._add_signal("tready", f"{self.name}_axis_tready")
        self.bus._add_signal("tdata", f"{self.name}_axis_tdata")

        self.bus.tvalid.value = 0
        self.bus.tdata.value = 0

    async def _driver_send(self, value, sync=True):
        if sync:
            await ReadWrite()

        self.bus.tvalid.value = 1
        self.bus.tdata.value = value

        # Wait until a transfer has occured
        while True:
            await RisingEdge(self.clock)
            if self.bus.tvalid.value == 1 and self.bus.tready.value == 1:
                break

        # Done
        self.bus.tvalid.value = 0
