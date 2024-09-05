# Proof Generator
A proof generator for cairo programs.

## Overview
You can genrate proofs for cairo programs here. Check out the Makefile to see what commands are available.
There are 2 ways to genrate proofs: 
1. First bootloading the program and then proving the execution of the bootloader. This is the recommended way and generates smaller proofs.
2. Proving the execution of the program directly.


## Installation
Run the following command to install the dependencies:
```bash
./install.sh
cargo build
```

## Usage
To checkout an example, check out the `examples` directory.
1. Create a new cairo program to proove, e.g. `dummy_snos.cairo`. 
2. Create a corresponding input file, e.g. `dummy_snos_input.json`.

```bash
cargo run --bin dummy_snos
```