.PHONY: all
all: vcu108


vcu108:
	vivado -mode batch -source scripts/vcu108.tcl