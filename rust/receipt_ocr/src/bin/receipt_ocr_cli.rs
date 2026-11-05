//! Host CLI: OCR receipt photos with the same engine the app embeds.
//!
//! ```text
//! receipt-ocr --models .models --ort-lib /path/libonnxruntime.so [--out-dir DIR] [--pretty] IMAGE...
//! ```
//! With one image and no `--out-dir` the JSON goes to stdout; with
//! `--out-dir` every image gets `<stem>.ocr.json` there (the golden fixtures
//! under `samples/` are produced this way).

use std::path::{Path, PathBuf};
use std::process::ExitCode;

use receipt_ocr::{init, scan_path, Config};

fn usage() -> ! {
    eprintln!(
        "usage: receipt-ocr [--models DIR] [--ort-lib PATH] [--max-side N] [--no-orientation] \
         [--min-confidence F] [--out-dir DIR] [--pretty] IMAGE..."
    );
    std::process::exit(2)
}

fn main() -> ExitCode {
    let mut config = Config::default();
    let mut out_dir: Option<PathBuf> = None;
    let mut pretty = false;
    let mut images: Vec<String> = Vec::new();
    let mut pdf_text: Option<String> = None;

    let mut args = std::env::args().skip(1);
    while let Some(a) = args.next() {
        match a.as_str() {
            "--models" => config.models_dir = Some(args.next().unwrap_or_else(|| usage())),
            "--ort-lib" => config.ort_lib = Some(args.next().unwrap_or_else(|| usage())),
            "--max-side" => {
                config.max_side = args
                    .next()
                    .and_then(|v| v.parse().ok())
                    .unwrap_or_else(|| usage())
            }
            "--min-confidence" => {
                config.min_confidence = args
                    .next()
                    .and_then(|v| v.parse().ok())
                    .unwrap_or_else(|| usage())
            }
            "--no-orientation" => config.textline_orientation = false,
            "--out-dir" => out_dir = Some(PathBuf::from(args.next().unwrap_or_else(|| usage()))),
            "--pretty" => pretty = true,
            "--pdf-text" => pdf_text = Some(args.next().unwrap_or_else(|| usage())),
            "-h" | "--help" => usage(),
            s if s.starts_with('-') => usage(),
            _ => images.push(a),
        }
    }
    // Text layer of a PDF (no models needed): what the app's statement import feeds the LLM.
    if let Some(path) = pdf_text {
        return match receipt_ocr::pdf_text_path(&path) {
            Ok(text) => {
                println!("{text}");
                ExitCode::SUCCESS
            }
            Err(e) => {
                eprintln!("receipt-ocr: {e}");
                ExitCode::FAILURE
            }
        };
    }
    if images.is_empty() {
        usage();
    }

    if let Err(e) = init(config) {
        eprintln!("receipt-ocr: {e}");
        return ExitCode::FAILURE;
    }

    let mut failed = false;
    for image in &images {
        match scan_path(image) {
            Ok(result) => {
                let json = if pretty {
                    serde_json::to_string_pretty(&result)
                } else {
                    serde_json::to_string(&result)
                }
                .expect("serialisable");
                match &out_dir {
                    Some(dir) => {
                        let stem = Path::new(image)
                            .file_stem()
                            .map(|s| s.to_string_lossy().into_owned())
                            .unwrap_or_else(|| "image".into());
                        let target = dir.join(format!("{stem}.ocr.json"));
                        if let Err(e) = std::fs::create_dir_all(dir)
                            .and_then(|_| std::fs::write(&target, json.as_bytes()))
                        {
                            eprintln!("receipt-ocr: write {}: {e}", target.display());
                            failed = true;
                        } else {
                            eprintln!(
                                "receipt-ocr: {image}: {} lines in {} ms -> {}",
                                result.lines.len(),
                                result.elapsed_ms,
                                target.display()
                            );
                        }
                    }
                    None => println!("{json}"),
                }
            }
            Err(e) => {
                eprintln!("receipt-ocr: {image}: {e}");
                failed = true;
            }
        }
    }
    if failed {
        ExitCode::FAILURE
    } else {
        ExitCode::SUCCESS
    }
}
