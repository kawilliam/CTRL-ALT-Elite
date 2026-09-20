# ==============================================================================
# RISC-V VERIFICATION MAKEFILE (.x Files Only)
# ==============================================================================

# --- PATH DEFINITIONS ---
VERIF_DIR      := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
DESIGN_DIR     := $(abspath $(VERIF_DIR)/../code)
TESTS_BASE_DIR := $(VERIF_DIR)/tests
SIM_DIR        := $(VERIF_DIR)/Sim
OBJ_DIR        := $(VERIF_DIR)/obj_dir

# --- COMPILER CONFIG ---
VERILATOR ?= verilator

# Tracing Flags: Pass DT=1 or DT=2 on CLI
TRACE_FLAGS := --trace --timing
ifeq ($(DT),1)
    TRACE_FLAGS += --trace-max-array 4096 --trace-max-width 32
else ifeq ($(DT),2)
    TRACE_FLAGS += --trace-structs --trace-depth 99
endif

# --- TEST SELECTION ---
TEST_DIR  ?=
TEST      ?=
MEM_FILE  := $(if $(TEST),$(TEST_DIR)/$(TEST).x,$(TEST_DIR)/default.x)
FULL_PATH := $(TESTS_BASE_DIR)/$(MEM_FILE)
MEM_NAME  := $(basename $(notdir $(MEM_FILE)))

# Find ALL subdirectories inside verif/tests/
ALL_TEST_DIRS := $(notdir $(patsubst %/,%,$(wildcard $(TESTS_BASE_DIR)/*/)))

# Line count logic for dynamic allocation
LINE_COUNT := $(strip $(shell [ -f "$(FULL_PATH)" ] && grep -c '[^[:space:]]' "$(FULL_PATH)" || echo 0))

# Automatically collect all .sv files in design/code/
DESIGN_SRCS := $(wildcard $(DESIGN_DIR)/*.sv)

# Automatically inspect hut.sv for signals before compiling
HAS_STALL := $(shell grep -E -q '\bstall\b'  path/to/hut.sv && echo "-DHAS_STALL_SIGNAL")
HAS_FLUSH := $(shell grep -E -q '\bflush\b'  path/to/hut.sv && echo "-DHAS_FLUSH_SIGNAL")

EXTRA_FLAGS += $(HAS_FLUSH) $(HAS_STALL)

.PHONY: all clean help run run-all sim sim-all $(SIM_DIR)

all: sim-all

$(SIM_DIR):
	@mkdir -p $(SIM_DIR)

# --- AUTOMATIC TESTBENCH SELECTION ---
ifeq ($(findstring insn-bmarks,$(TEST_DIR)),insn-bmarks)
    TB_SRC := $(VERIF_DIR)/rv_official_tb.sv
    TOP_MODULE := rv_official_tb
else
    TB_SRC := $(VERIF_DIR)/top_tb.sv
    TOP_MODULE := top_tb
endif

# Find rv_core.sv path dynamically inside DESIGN_DIR
RV_CORE_FILE := $(shell find $(DESIGN_DIR) -name "rv_core.sv" -o -name "*rv_core*.v*" | head -n 1)

# Check rv_core for declarations of 'stall' and 'flush'
HAS_STALL := $(shell grep -E -q '\b(logic|wire|reg|input|output)\s+.*?\bstall\b' $(RV_CORE_FILE) 2>/dev/null && echo "-DHAS_STALL_SIGNAL")
HAS_FLUSH := $(shell grep -E -q '\b(logic|wire|reg|input|output)\s+.*?\b(flush|squash)\b' $(RV_CORE_FILE) 2>/dev/null && echo "-DHAS_FLUSH_SIGNAL")

EXTRA_FLAGS += $(HAS_STALL) $(HAS_FLUSH)

# --- VERILATOR BUILD ---
compile-tb: $(SIM_DIR)
	@if [ "$(QUIET_BUILD)" != "1" ]; then \
		echo "------------------------------------------------------------"; \
		echo "Building testbench binary: V$(TOP_MODULE) using $(TB_SRC)"; \
		echo "Using Test File: $(FULL_PATH)"; \
		echo "Extra Flags: $(EXTRA_FLAGS)"; \
		echo "------------------------------------------------------------"; \
	fi
	@$(VERILATOR) -sv --cc --exe $(EXTRA_FLAGS) \
		--timing \
		--trace \
		--timescale 1ns/1ps \
		-I$(DESIGN_DIR) \
		-I$(VERIF_DIR) \
		--top-module $(TOP_MODULE) \
		-CFLAGS "-DVM_PREFIX=V$(TOP_MODULE) -DVL_TOP=V$(TOP_MODULE)" \
		-DSIMULATION \
		-DMEM_DEPTH=1048576 \
		-DMEM_PATH=\"$(FULL_PATH)\" \
		-DLINE_COUNT=$(LINE_COUNT) \
		$(TRACE_FLAGS) \
		$(TB_SRC) \
		$(DESIGN_SRCS) \
		$(VERIF_DIR)/tb_main_verilator.cpp \
		--Mdir $(OBJ_DIR) \
		-MAKEFLAGS "-s --no-print-directory" \
		--build -o Vtop_tb

# --- SIMULATION EXECUTION ---
run: compile-tb
	@LOG_FILE="$(VERIF_DIR)/_results.txt"; \
	$(OBJ_DIR)/Vtop_tb > sim_out.tmp 2>&1; \
	TIMESTAMP=$$(date '+%Y-%m-%d %H:%M:%S'); \
	CYCLES=$$(sed -n 's/.*Total Cycles[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p' sim_out.tmp | tail -n1); \
	STALLS=$$(sed -n 's/.*Stalls[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p' sim_out.tmp | tail -n1); \
	SQUASHES=$$(sed -n 's/.*Squashes[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p' sim_out.tmp | tail -n1); \
	CPI=$$(sed -n 's/.*Final CPI[[:space:]]*:[[:space:]]*\([0-9.]*\).*/\1/p' sim_out.tmp | tail -n1); \
	CYCLES=$${CYCLES:-N/A}; \
	STALLS=$${STALLS:-N/A}; \
	SQUASHES=$${SQUASHES:-N/A}; \
	CPI=$${CPI:-N/A}; \
	if grep -q "Test Passed" sim_out.tmp; then \
		printf "%-30s %-20s %-8s %-12s %-8s %-10s %-6s\n" "$(MEM_NAME)" "$$TIMESTAMP" "PASS" "$$CYCLES" "$$STALLS" "$$SQUASHES" "$$CPI" >> $$LOG_FILE; \
	else \
		printf "%-30s %-20s %-8s %-12s %-8s %-10s %-6s\n" "$(MEM_NAME)" "$$TIMESTAMP" "FAIL" "$$CYCLES" "$$STALLS" "$$SQUASHES" "$$CPI" >> $$LOG_FILE; \
	fi; \
	cat sim_out.tmp; rm -f sim_out.tmp; \
	for vcd in dump.vcd top_tb.vcd wave.vcd vlt_dump.vcd; do \
		if [ -f "$$vcd" ]; then mv "$$vcd" $(SIM_DIR)/$(MEM_NAME).vcd; break; fi; \
	done

# Runs all .x files in a target TEST_DIR folder
run-all: $(SIM_DIR)
ifeq ($(TEST_DIR),)
	@$(MAKE) sim-all
else
	@LOG_FILE="$(VERIF_DIR)/_results.txt"; \
	export LOG_FILE; \
	printf "%s\n" "---------------------------------------------------------------------------------------------------" >> "$$LOG_FILE"; \
	printf "Test Directory: %-30s Date: %s\n" "$(TEST_DIR)" "$$(date '+%Y-%m-%d %H:%M:%S')" >> "$$LOG_FILE"; \
	printf "%-30s %-20s %-8s %-12s %-8s %-10s %-6s\n" "Test Name:" "Date/Time:" "Result:" "Cycles:" "Stalls:" "Squashed:" "CPI:" >> "$$LOG_FILE"; \
	printf "%s\n" "---------------------------------------------------------------------------------------------------" >> "$$LOG_FILE"; \
	for xfile in $(TESTS_BASE_DIR)/$(TEST_DIR)/*.x; do \
		[ -e "$$xfile" ] || continue; \
		name=$$(basename $${xfile%.x}); \
		echo ""; \
		echo "  >> Simulating: $$name"; \
		$(MAKE) --no-print-directory run TEST_DIR=$(TEST_DIR) TEST=$$name DT=$(DT) QUIET_BUILD=1; \
	done
endif

# --- SIMULATION TARGETS ---
sim:
ifndef TEST_DIR
	$(error TEST_DIR is required. Usage: make sim TEST_DIR=<folder> [TEST=<test_name>] [DT=1])
endif
	@if [ -z "$(TEST)" ]; then \
		$(MAKE) run-all TEST_DIR=$(TEST_DIR) DT=$(DT); \
	else \
		$(MAKE) run TEST_DIR=$(TEST_DIR) TEST=$(TEST) DT=$(DT) QUIET_BUILD=1; \
	fi

sim-all:
	@echo "------------------------------------------------------------"
	@echo "Running all tests across subdirectories in $(TESTS_BASE_DIR)"
	@echo "------------------------------------------------------------"
	@for dir in $(ALL_TEST_DIRS); do \
		echo $$dir; \
		$(MAKE) run-all TEST_DIR=$$dir DT=$(DT); \
		mv obj_dir obj_dir_$$dir; \
	done

# ==============================================================================
# STANDALONE TESTBENCH RUNNER (Isolates single testbenches without hardcoding HUTs)
# ==============================================================================

# Unique prefix prevents conflicts with existing run rules (e.g., make tb-template_tb)
tb-%: $(SIM_DIR)
	@echo "------------------------------------------------------------"
	@echo "Compiling and running dynamic testbench: $*"
	@echo "Target File: $(VERIF_DIR)/$*.sv"
	@echo "------------------------------------------------------------"
	@if [ ! -f "$(VERIF_DIR)/$*.sv" ]; then \
		echo "ERROR: Testbench file $(VERIF_DIR)/$*.sv does not exist!"; \
		exit 1; \
	fi
	
	@# -y and +librescan forces Verilator to dynamically find and extract
	@# ONLY the hardware files needed by your testbench out of the code dir.
	$(VERILATOR) --binary -sv \
		--timing \
		--trace \
		--timescale 1ns/1ps \
		-y $(DESIGN_DIR) \
		+librescan \
		-I$(VERIF_DIR) \
		--top-module $* \
		$(TRACE_FLAGS) \
		$(VERIF_DIR)/$*.sv \
		--Mdir $(OBJ_DIR)_$* \
		-o V$*
	
	@echo "Executing simulation..."
	$(OBJ_DIR)_$*/V$*
	
	@for vcd in $*.vcd dump.vcd wave.vcd; do \
		if [ -f "$$vcd" ]; then \
			mv "$$vcd" $(SIM_DIR)/$*.vcd; \
			echo "Waveform saved to: $(SIM_DIR)/$*.vcd"; \
			break; \
		fi; \
	done


clean:
	@echo "Cleaning artifacts..."
	rm -rf $(OBJ_DIR) $(SIM_DIR)
	rm -f $(VERIF_DIR)/_results.txt
	rm -f *.vcd
	rm -rf -f obj_dir*

help:
	@echo ""
	@echo "Supported Commands:"
	@echo "  make sim-all                                   (Sweeps ALL subdirectories in verif/tests/)"
	@echo "  make run-all                                   (Alias for make sim-all if TEST_DIR is omitted)"
	@echo "  make sim TEST_DIR=<folder_name>                (Runs ALL .x files in tests/<folder_name>/)"
	@echo "  make sim TEST_DIR=<folder_name> TEST=<name>    (Runs tests/<folder_name>/<name>.x)"
	@echo "  make clean                                     (Deletes obj_dir, Sim, results, and wave outputs)"
	@echo ""
	