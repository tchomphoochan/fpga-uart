BOARD?=vcu108
VIVADO_VERSION?=$(shell ./scripts/get-vivado-version.sh)
TOP_LEVEL?=top_loopback

SUPPORTED_BOARDS:=vcu108

DATA := $(wildcard data/*.mem)
SRCS := $(wildcard src/*.sv src/*.v src/*.svh)

# All targets should be explicitly listed, especially for PHONY rules.
# See: https://stackoverflow.com/questions/3095569/why-are-phony-implicit-pattern-rules-not-triggered
BUILD_TARGETS:=$(foreach board, $(SUPPORTED_BOARDS), build.$(board))
BITSTREAM_TARGETS:=$(foreach board, $(SUPPORTED_BOARDS), build/$(board)/final.bit)
FLASH_TARGETS:=$(foreach board, $(SUPPORTED_BOARDS), flash.$(board))

.PHONY: all $(BUILD_TARGETS) $(FLASH_TARGETS)
all: $(BUILD_TARGETS)


$(BUILD_TARGETS): build.%: build/%/final.bit


$(FLASH_TARGETS): flash.%:
	@echo "Attempting to flash build/$*/final.bit without re-synthesizing..."
	fpgajtag build/$*/final.bit

$(BITSTREAM_TARGETS): build/%/final.bit: $(DATA) $(SRCS) tcl/build.tcl
	BOARD=$(BOARD) VIVADO_VERSION=$(VIVADO_VERSION) TOP_LEVEL=$(TOP_LEVEL) \
	  vivado -mode batch -source tcl/build.tcl
