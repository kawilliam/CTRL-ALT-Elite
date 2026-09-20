# EECS-4201-project

This is the starter code for YorkU's EECS 4201 course project that progressively builds a fully-pipelined 5-staged in-order RISC-V core that supports the RV32I instruction set.
SystemVerilog is the hardware descriptive language (HDL) used to implement the core.

## Project structure
There are three main directories: `code`, `verif` and `synthesis`.
The `code` directory houses the main hardware logic design, the `verif` holds the build scripts and sample tests to verify and simulate your design, and the `synthesis` holds the synthesis scripts and cell library.

## Code structure
The following files are present in the `code` directory:
- `rv_core.sv`: This is the top level design that instantiates all the logic modules. The top level design is called `rv_core`
- `fetch.sv`: Implements the fetch stage logic
- `decode.sv`: Implements the decode stage logic
- `igen.sv`: Implements the immediate value generator logic
- `control.sv`: Implements the control path.
- `branch_control.sv`: Implements the branching control path
- `execute.sv`: Implements the execute stage (ALU implementation)
- `memory.sv`: Top level memory stage that instantiates `memory_controller` and `main_memory`
- `memory_controller.sv`: Implements the memory controller logic that interfaces with the main memory
- `main_memory.sv`: Implements the memory module
- `register_file.sv`: Implements the register file data path component
- `writeback.sv`: Implements the writeback stage
- `stall_flush_logic.sv`: Implements the stall and flush logic

## Synthesis
You will synthesis your design using a 130nm library provided by Skywater + Google. To run the synthesis, in a terminal on the EA machine, invoke the librelane suite of EDA tools by executing `librelane`. This will open a nix-shell. After that invoke `yosys synthesis/synthesis.ys`. yosys will run a series of hardware optimizations and do a technology mapping against the 130nm library and generate a report. 

## Getting started
Note that the below steps assume a linux environment with ModelSim or Verilator installed.

### Step 0: Setup your workstation
You will need a workstation (duh) to do the project. You may either use your personal computer or use one of the linux remote machines [EA machines](https://remotelab.eecs.yorku.ca/#/) provided by the department. We will use  [Verilator](https://verilator.org/) to build and simulate the design and use [gtkwave](https://gtkwave.sourceforge.net/) to view the VCD waveforms. Both of these are available on the EA machines.

The below steps have been tested on a EA linux machine provided by the department and on a personal linux workstation. If you would like to develop on a windows system, then you will have to develop your own scripts and methodologies to load and test your designs.

### Step 1: Get the starter code
------------------------------------

### Step 2: Check your environment
------------------------------------

Open a terminal and execute the following:
- `verilator --version` : This should return a string displaying the verilator version
- `gtkwave --version`: This should return a string displaying the gtkwave version

### Step 3: Compiling the code
------------------------------------
- In the current directory, invoke the following command to build your hardware model using verilator: `make compile-tb -C verif/`.
  This will compile your hardware design and output any syntax or hardware design bugs. Pay close attention to the errors.
  I recommend to use `make compile-tb WARN=1 -C verif/` and pay close attention to the warnings.

- Once the design is compiled, you can invoke the following command to run the sample testbench using `make tb-template_tb -C verif/`
- You can also run your design on a test benchmark by invoking the following command: `make run -C verif/ TEST_DIR=test-bmarks TEST=test1`.
  If you want to run all the benchmarks in a directory, do not include the `TEST` command line argument

## Step 4: Testing the code
------------------------------------
- You **must** write your own testbenches (TB) to test your design. A sample TB is available for you to extend in `verif/template_tb.sv`.
- I strongly suggest first checking your logic using custom TBs and corresponding waveforms using gtkwave and then running the sample benchmarks in `verif/tests`
- On running a benchmark in `verif/tests`, one of three outputs are possible:
     - `Test Passed`: Your design successfully passed the test
     - `Test Failed`: Your design failed the test
     - `Simulation TIMEOUT`: Your test took a long time to execute on the hardware

- For the `Test Failed` and `Simulation TIMEOUT` cases, you can open the waveforms located in the `Sim` directory using `gtkwave Sim/<name of .vcd file>`.

### Step 5: Submitting code to eclass
------------------------------------
- After you have verified your design, zip up the `code/` directory and submit on eclass.

### Acknowledgements
------------------------------------
Many thanks to the Fall 2025 students of EECS 4201 who caught bugs and suggested improvements to this project (Hussein, Salwan, Abdulbasit, Minhyeok, Areeba, Nitant, Anthony, Vikram, Steven, Cheuk, Clarence, Patrick, Dylan, Aadi, Paavan, Harman, Arnav, Salim, Salman, Manya, Artin, Yousif, Anagha, Kiet, Colin, Kaibin, Jackie, Quardin, Mavra, Kosy, Kanwarpartap, Paramkumar, Mateo, Taha, Sara, Abdullah, Ariana, and Erwin).

