.DEFAULT_GOAL := help
.DELETE_ON_ERROR:

OSS_CAD_BIN ?= /opt/oss-cad-suite/bin
IVERILOG    ?= $(OSS_CAD_BIN)/iverilog
VVP         ?= $(OSS_CAD_BIN)/vvp
VERILATOR   ?= $(OSS_CAD_BIN)/verilator
YOSYS       ?= $(OSS_CAD_BIN)/yosys
GTKWAVE     ?= $(OSS_CAD_BIN)/gtkwave

override BUILD_DIR := build
WAVE_SAVE := artifacts/waveforms/tiny8_system.gtkw

RTL_HEADERS := rtl/tiny8_defs.vh
RTL_SOURCES := \
	rtl/alu8.v \
	rtl/instruction_decoder.v \
	rtl/control_unit.v \
	rtl/program_rom.v \
	rtl/data_ram.v \
	rtl/tiny8_core.v \
	rtl/tiny8_system.v

TEST_TOPS := \
	alu8_tb \
	instruction_decoder_tb \
	data_ram_tb \
	program_rom_tb \
	control_unit_tb \
	tiny8_core_tb \
	tiny8_system_tb \
	tiny8_program_regression_tb

RTL_SRCS_alu8_tb := rtl/alu8.v
RTL_SRCS_instruction_decoder_tb := rtl/instruction_decoder.v
RTL_SRCS_data_ram_tb := rtl/data_ram.v
RTL_SRCS_program_rom_tb := rtl/program_rom.v
RTL_SRCS_control_unit_tb := rtl/instruction_decoder.v rtl/control_unit.v
RTL_SRCS_tiny8_core_tb := \
	rtl/alu8.v \
	rtl/instruction_decoder.v \
	rtl/control_unit.v \
	rtl/tiny8_core.v
RTL_SRCS_tiny8_system_tb := $(RTL_SOURCES)
RTL_SRCS_tiny8_program_regression_tb := $(RTL_SOURCES)

SYNTH_TOPS := \
	alu8 \
	instruction_decoder \
	data_ram \
	program_rom \
	control_unit \
	tiny8_core \
	tiny8_system

SYNTH_SRCS_alu8 := rtl/alu8.v
SYNTH_SRCS_instruction_decoder := rtl/instruction_decoder.v
SYNTH_SRCS_data_ram := rtl/data_ram.v
SYNTH_SRCS_program_rom := rtl/program_rom.v
SYNTH_SRCS_control_unit := rtl/instruction_decoder.v rtl/control_unit.v
SYNTH_SRCS_tiny8_core := \
	rtl/alu8.v \
	rtl/instruction_decoder.v \
	rtl/control_unit.v \
	rtl/tiny8_core.v
SYNTH_SRCS_tiny8_system := $(RTL_SOURCES)

SYNTH_FLAGS_alu8 := -Irtl
SYNTH_FLAGS_instruction_decoder := -Irtl
SYNTH_FLAGS_data_ram :=
SYNTH_FLAGS_program_rom :=
SYNTH_FLAGS_control_unit := -Irtl
SYNTH_FLAGS_tiny8_core := -Irtl
SYNTH_FLAGS_tiny8_system := -Irtl

TEST_TARGETS := $(addprefix test-,$(TEST_TOPS))
LINT_TARGETS := $(addprefix lint-,$(TEST_TOPS))
SYNTH_TARGETS := $(addprefix synth-,$(SYNTH_TOPS))

.PHONY: help test lint synth wave clean check-root
.PHONY: $(TEST_TARGETS) $(LINT_TARGETS) $(SYNTH_TARGETS)

help:
	@echo "Tiny8 verification and synthesis targets"
	@echo "  make test   - compile and run all self-checking RTL simulations"
	@echo "  make lint   - run Verilator lint on every test hierarchy"
	@echo "  make synth  - synthesize every RTL module under build/"
	@echo "  make wave   - regenerate and open the annotated system waveform"
	@echo "  make clean  - remove generated files under build/"

check-root:
	@if [ "$(CURDIR)" != "$(abspath $(dir $(lastword $(MAKEFILE_LIST))))" ]; then \
		echo "Run make from the Tiny8 repository root."; \
		exit 1; \
	fi

$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/%.vvp: tb/%.v $(RTL_SOURCES) $(RTL_HEADERS) | check-root $(BUILD_DIR)
	$(IVERILOG) -g2012 -Wall -Irtl -s $* -o $@ $(RTL_SRCS_$*) $<

$(TEST_TARGETS): test-%: $(BUILD_DIR)/%.vvp
	@echo "==> Simulating $*"
	$(VVP) $<

test: $(TEST_TARGETS)
	@echo "All Tiny8 RTL simulations passed."

$(LINT_TARGETS): lint-%: tb/%.v $(RTL_SOURCES) $(RTL_HEADERS) | check-root
	@echo "==> Linting $*"
	$(VERILATOR) --lint-only --timing -Wall -Irtl \
		--top-module $* $(RTL_SRCS_$*) $<

lint: $(LINT_TARGETS)
	@echo "All Tiny8 Verilator lint checks passed."

$(SYNTH_TARGETS): synth-%: $(RTL_SOURCES) $(RTL_HEADERS) | check-root $(BUILD_DIR)
	@echo "==> Synthesizing $*"
	$(YOSYS) -ql $(BUILD_DIR)/$*_synth.log -p 'read_verilog $(strip $(SYNTH_FLAGS_$*) $(SYNTH_SRCS_$*)); hierarchy -check -top $*; synth -top $*; check -assert; stat; write_verilog $(BUILD_DIR)/$*_synth.v; write_json $(BUILD_DIR)/$*.json'
	@if grep 'Warning:' $(BUILD_DIR)/$*_synth.log | \
		grep -vF 'ABC: Warning: The network is combinational (run "fraig" or "fraig_sweep").'; then \
		echo "Unexpected synthesis warning(s) found in $(BUILD_DIR)/$*_synth.log"; \
		exit 1; \
	fi

synth: $(SYNTH_TARGETS)
	@echo "All Tiny8 Yosys synthesis checks passed."

wave: test-tiny8_system_tb
	$(GTKWAVE) $(BUILD_DIR)/tiny8_system_tb.vcd $(WAVE_SAVE)

clean: check-root
	$(RM) -r -- $(BUILD_DIR)
	@echo "Removed generated files under $(BUILD_DIR)/."
