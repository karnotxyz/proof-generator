# Proof Generator

A proof generator for cairo programs.

### Credits

This repository uses [stone-prover](https://github.com/starkware-libs/stone-prover) under the hood to generate proofs and uses [cairo-vm](https://github.com/lambdaclass/cairo-vm) to run, compile. The bootloader is taken from [bootloader](https://github.com/Moonsong-Labs/cairo-bootloader.git) repository. To know more about bootloading check this [out](https://youtu.be/xHc_pKXN9h8?si=CMtp1cHjexRWDWYH&t=513)

## Overview

You can generate proofs for cairo programs here.
There are 2 ways to genrate proofs:

1. First bootloading the program and then proving the execution of the bootloader. This is the recommended way and generates smaller proofs. Check out a simple bootloader [here](https://github.com/starkware-libs/cairo-lang/blob/master/src/starkware/cairo/bootloaders/simple_bootloader/simple_bootloader.cairo_)
2. Proving the execution of the program directly.

## Installation

Run the following command to install the dependencies:

```shell
./install.sh
cargo build
```

## Files

`compiled.json`: The compiled Cairo program.
`input.json`: Input data for the Cairo program.
`public_input.json`: Public inputs for the proof generation.
`private_input.json`: Private inputs for the proof generation.
`trace.bin`: Execution trace of the Cairo program.
`memory.bin`: Memory dump of the Cairo program execution.
`proof.json`: The generated STARK proof.
`pie.zip`: Cairo PIE (Program Independent Executable) that can be generated by running the program and can be used re run the file in standardised way without inputs. This is only kept for reference/debugging purposes and not used for proof generation.
`cpu_air_prover_config.json`: Configuration file for the CPU AIR prover(stone-prover).
`cpu_air_params.json`: Parameters file for the CPU AIR prover(stone-prover).

## Preparing a program

To checkout an example, check out the `examples` directory.

1. Create a new cairo program to prove, e.g. `dummy_snos.cairo`.
2. Create a corresponding input file, e.g. `dummy_snos_input.json`.
3. Modify the `examples/cpu_air_params.json` and `examples/cpu_air_config.json` to fit your needs. Check out the [stone-prover](https://github.com/starkware-libs/stone-prover) documentation to see how to generate these files.

## Generating a proof

- If you want to generate a proof after bootloading it, run:

```shell
make prove_with_bootloader CAIRO_PROGRAM=<path_to_cairo_file>
```

- If you want to generate a proof for a program directly, run:

```shell
make prove_with_program CAIRO_PROGRAM=<path_to_cairo_file>
```

- If you want to generate a PIE(Position Independent Executable) program, run:

```shell
make generate_pie CAIRO_PROGRAM=<path_to_cairo_file>
```

- If you want to run the PIE program, run:

```shell
make run_pie CAIRO_PROGRAM=<path_to_cairo_file>
```
