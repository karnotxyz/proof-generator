// Check out https://github.com/Moonsong-Labs/cairo-bootloader/blob/main/examples/run_program.rs


use std::error::Error;

use bincode::enc::write::Writer;
use cairo_vm::cairo_run::{cairo_run_program_with_initial_scope, CairoRunConfig};
use cairo_vm::types::exec_scope::ExecutionScopes;
use cairo_vm::types::layout_name::LayoutName;
use cairo_vm::types::program::Program;
use cairo_vm::vm::errors::cairo_run_errors::CairoRunError;
use cairo_vm::vm::runners::cairo_runner::CairoRunner;
use cairo_vm::Felt252;

use cairo_bootloader::bootloaders::load_bootloader;
use cairo_bootloader::tasks::make_bootloader_tasks;
use cairo_bootloader::{
    insert_bootloader_input, BootloaderConfig, BootloaderHintProcessor, BootloaderInput,
    PackedOutput, SimpleBootloaderInput, TaskSpec,
};
use std::{
    io::{self, Write},
    path::Path,
};

use clap::Parser;

fn cairo_run_bootloader_in_proof_mode(
    bootloader_program: &Program,
    tasks: Vec<TaskSpec>,
) -> Result<CairoRunner, CairoRunError> {
    let mut hint_processor = BootloaderHintProcessor::new();

    let cairo_run_config = CairoRunConfig {
        entrypoint: "main",
        trace_enabled: true,
        relocate_mem: true,
        layout: LayoutName::small,
        proof_mode: true,
        secure_run: Some(true),
        disable_trace_padding: false,
        allow_missing_builtins: None,
    };

    // Build the bootloader input
    let n_tasks = tasks.len();
    let bootloader_input = BootloaderInput {
        simple_bootloader_input: SimpleBootloaderInput {
            fact_topologies_path: None,
            single_page: false,
            tasks,
        },
        bootloader_config: BootloaderConfig {
            simple_bootloader_program_hash: Felt252::from(0),
            supported_cairo_verifier_program_hashes: vec![],
        },
        packed_outputs: vec![PackedOutput::Plain(vec![]); n_tasks],
    };

    // Note: the method used to set the bootloader input depends on
    // https://github.com/lambdaclass/cairo-vm/pull/1772 and may change depending on review.
    let mut exec_scopes = ExecutionScopes::new();
    insert_bootloader_input(&mut exec_scopes, bootloader_input);

    // Run the bootloader
    cairo_run_program_with_initial_scope(
        &bootloader_program,
        &cairo_run_config,
        &mut hint_processor,
        exec_scopes,
    )
}

pub struct FileWriter {
    buf_writer: io::BufWriter<std::fs::File>,
    bytes_written: usize,
}

impl Writer for FileWriter {
    fn write(&mut self, bytes: &[u8]) -> Result<(), bincode::error::EncodeError> {
        self.buf_writer
            .write_all(bytes)
            .map_err(|e| bincode::error::EncodeError::Io {
                inner: e,
                index: self.bytes_written,
            })?;

        self.bytes_written += bytes.len();

        Ok(())
    }
}

impl FileWriter {
    fn new(buf_writer: io::BufWriter<std::fs::File>) -> Self {
        Self {
            buf_writer,
            bytes_written: 0,
        }
    }

    fn flush(&mut self) -> io::Result<()> {
        self.buf_writer.flush()
    }
}

#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    #[arg(short, long, required = true)]
    compiled_program: String,

    #[arg(short='u', long, required = true)]
    air_public_input: String,

    #[arg(short='p', long, required = true)]
    air_private_input: String,

    #[arg(short, long, required = true)]
    memory_file: String,

    #[arg(short, long, required = true)]
    trace: String,
}

fn main() -> Result<(), Box<dyn Error>> {
    let args = Args::parse();

    for path in [
        &args.compiled_program,
        &args.air_public_input,
        &args.air_private_input,
        &args.memory_file,
        &args.trace,
    ] {
        if !Path::new(path).exists() {
            eprintln!("Error: File '{}' does not exist", path);
            std::process::exit(1);
        }
    }

    let bootloader_program = load_bootloader()?;
    let dummy_snos_program = std::fs::read(args.compiled_program)?;
    let tasks = make_bootloader_tasks(&[&dummy_snos_program], &[])?;

    let mut runner = cairo_run_bootloader_in_proof_mode(&bootloader_program, tasks)?;

    // Air public input
    {
        let json = runner.get_air_public_input().unwrap().serialize_json()?;
        std::fs::write(args.air_public_input, json)?;
    }

    // Air private input
    {
        let json = runner
            .get_air_private_input()
            .to_serializable(args.trace.clone(), args.memory_file.clone())
            .serialize_json()?;
        // print!("{:?}", json);
        std::fs::write(args.air_private_input, json)?;
    }

    // memory_file
    {
        let memory_file = std::fs::File::create(args.memory_file)?;
        let mut memory_writer =
            FileWriter::new(io::BufWriter::with_capacity(5 * 1024 * 1024, memory_file));

        cairo_vm::cairo_run::write_encoded_memory(&runner.relocated_memory, &mut memory_writer)?;
        memory_writer.flush()?;
    }

    // Trace file
    {
        let relocated_trace = runner.relocated_trace.clone().unwrap().clone();
        let trace_file = std::fs::File::create(args.trace)?;
        let mut trace_writer =
            FileWriter::new(io::BufWriter::with_capacity(3 * 1024 * 1024, trace_file));

        cairo_vm::cairo_run::write_encoded_trace(&relocated_trace, &mut trace_writer)?;
        trace_writer.flush()?;
    }

    let mut output_buffer = "Program Output:\n".to_string();
    runner.vm.write_output(&mut output_buffer)?;
    print!("{output_buffer}");

    Ok(())
}
