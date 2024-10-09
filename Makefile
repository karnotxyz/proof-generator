# Makefile for Cairo compilation and proof generation

LAYOUT ?= small
CAIRO_PROGRAM ?= examples/dummy_snos/dummy_snos.cairo

CPU_AIR_PROVER := ./dependencies/stone-prover/cpu_air_prover
CAIRO_ENV := ./dependencies/cairo-vm/cairo-vm-env/bin/activate

# Extract the base name without extension
FILENAME_WITH_EXT := $(notdir $(CAIRO_PROGRAM))
FILENAME_WITHOUT_EXT := $(basename $(FILENAME_WITH_EXT))
DIR_NAME := $(dir $(CAIRO_PROGRAM))
OUTPUT_DIR := $(DIR_NAME)output/$(LAYOUT)/
OUTPUT_BASE_NAME := $(OUTPUT_DIR)$(FILENAME_WITHOUT_EXT)
INPUT_BASE_NAME := $(basename $(CAIRO_PROGRAM))

# Variables
COMPILED_OUTPUT := $(OUTPUT_BASE_NAME)_compiled.json
PROGRAM_INPUT := $(INPUT_BASE_NAME)_input.json
PUBLIC_INPUT := $(OUTPUT_BASE_NAME)_public_input.json
PRIVATE_INPUT := $(OUTPUT_BASE_NAME)_private_input.json
TRACE_FILE := $(OUTPUT_BASE_NAME)_trace.bin
MEMORY_FILE := $(OUTPUT_BASE_NAME)_memory.bin
PROOF_FILE := $(OUTPUT_BASE_NAME)_proof.json
CAIRO_PIE_OUTPUT := $(OUTPUT_BASE_NAME)_pie.zip
PROVER_CONFIG := $(INPUT_BASE_NAME)_cpu_air_prover_config.json
PARAM_FILE := $(INPUT_BASE_NAME)_cpu_air_params.json


# Phony targets
.PHONY: all compile run prove clean

# Default target
all: compile run prove

# Activate environment
define activate_env
	. $(CAIRO_ENV) &&
endef


# Check if CAIRO_PROGRAM is provided
check_program_set:
ifndef CAIRO_PROGRAM
	$(error CAIRO_PROGRAM is not set. Usage: make CAIRO_PROGRAM=your_program.cairo)
endif

# Compile the program
compile: check_program_set
	mkdir -p $(OUTPUT_DIR)
	@echo "Compiling the program..."
	$(activate_env) cairo-compile $(CAIRO_PROGRAM) \
		--output $(COMPILED_OUTPUT) \
		--proof_mode
	@echo "Compilation Successfull !!"

# Generate the pie output
generate_pie: compile
	@echo "Genrating the PIE..."
	$(activate_env) cairo-run \
		--program=$(COMPILED_OUTPUT) \
		--layout=$(LAYOUT) \
		--program_input=$(PROGRAM_INPUT) \
		--cairo_pie_output=$(CAIRO_PIE_OUTPUT) \
		--trace_file=$(TRACE_FILE) \
		--memory_file=$(MEMORY_FILE) \
		--print_output
	@echo "PIE generation Successfull !!"


# Run the program
run_pie: generate_pie
	@echo "Running the prorgram with PIE..."
	$(activate_env) cairo-run \
		--layout=$(LAYOUT) \
		--run_from_cairo_pie=$(CAIRO_PIE_OUTPUT) \
		--trace_file=$(TRACE_FILE) \
		--memory_file=$(MEMORY_FILE) \
		--print_output \
	@echo "Running with PIE Successfull !!"


# Run the program
run: compile
	@echo "Running the program..."
	$(activate_env) cairo-run \
		--program=$(COMPILED_OUTPUT) \
		--layout=$(LAYOUT) \
		--program_input=$(PROGRAM_INPUT) \
		--air_public_input=$(PUBLIC_INPUT) \
		--air_private_input=$(PRIVATE_INPUT) \
		--trace_file=$(TRACE_FILE) \
		--memory_file=$(MEMORY_FILE) \
		--print_output \
		--proof_mode
	@echo "Running Successfull !!"

run_bootloader: compile
	cargo run -- \
		--compiled-program $(COMPILED_OUTPUT) \
		--air-public-input $(PUBLIC_INPUT) \
		--air-private-input $(PRIVATE_INPUT) \
		--memory-file $(MEMORY_FILE) \
		--trace $(TRACE_FILE) \
		--layout $(LAYOUT)
	node format.js $(PUBLIC_INPUT)
	@echo "Running with bootloader Successfull !!"

# Generate the proof
proove_with_bootloader: run_bootloader
	@echo "Running the stone-prover..."
	$(CPU_AIR_PROVER) \
		--generate-annotations \
		--out_file=$(PROOF_FILE) \
		--private_input_file=$(PRIVATE_INPUT) \
		--public_input_file=$(PUBLIC_INPUT) \
		--prover_config_file=$(PROVER_CONFIG) \
		--parameter_file=$(PARAM_FILE)
	@echo "Prooving with bootloader Successfull !!"

# Generate the proof
proove_with_program: run
	@echo "Running the stone-prover..."
	$(CPU_AIR_PROVER) \
		--generate-annotations \
		--out_file=$(PROOF_FILE) \
		--private_input_file=$(PRIVATE_INPUT) \
		--public_input_file=$(PUBLIC_INPUT) \
		--prover_config_file=$(PROVER_CONFIG) \
		--parameter_file=$(PARAM_FILE)
	@echo "Prooving without bootloader Successfull !!"



# Clean up generated files
clean: check_program_set
	rm -f $(COMPILED_OUTPUT) $(TRACE_FILE) $(MEMORY_FILE) $(PROOF_FILE) $(PRIVATE_INPUT) $(PUBLIC_INPUT) $(CAIRO_PIE_OUTPUT)


# Print the current configuration
print-config:
	@echo "Current configuration:"
	@echo "CAIRO_PROGRAM: $(CAIRO_PROGRAM)"
	@echo "DIR_NAME: $(DIR_NAME)"
	@echo "OUTPUT_DIR: $(OUTPUT_DIR)"
	@echo "BASE_NAME: $(BASE_NAME)"
	@echo "COMPILED_OUTPUT: $(COMPILED_OUTPUT)"
	@echo "PUBLIC_INPUT: $(PUBLIC_INPUT)"
	@echo "PRIVATE_INPUT: $(PRIVATE_INPUT)"
	@echo "TRACE_FILE: $(TRACE_FILE)"
	@echo "MEMORY_FILE: $(MEMORY_FILE)"
	@echo "PROOF_FILE: $(PROOF_FILE)"
