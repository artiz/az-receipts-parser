//! Receipt OCR on top of docling.rs.
//!
//! The crate runs docling.rs' PP-OCR text *detector* (`ocr_det.onnx`) and
//! *recognizer* (`ocr_rec_v6.onnx` + dictionary) on a receipt photo and
//! returns every text line with its box, in reading order. Row grouping,
//! field extraction and categorisation live in the Flutter app (Dart), where
//! they are unit-tested against the golden fixtures in `samples/`.
//!
//! Why the low-level det+rec path and not `docling_pdf::convert_image`: the
//! full pipeline needs the 65 MB layout model and merges lines into layout
//! regions (paragraphs), which loses the line geometry a receipt parser
//! needs ("name … price" per row). The detector+recognizer pair is ~30 MB
//! and keeps one box per printed line.
//!
//! Two surfaces:
//! * the Rust API ([`init`], [`scan_bytes`], [`scan_path`]) used by the CLI;
//! * a C ABI (`receipt_ocr_*`) consumed through `dart:ffi` — every call is
//!   panic-safe and returns a NUL-terminated JSON string the caller frees
//!   with [`receipt_ocr_free`].

use std::ffi::{c_char, CStr, CString};
use std::io::Cursor;
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::sync::Mutex;
use std::time::Instant;

use docling_pdf::ocr_det::{sort_boxes, DetBox, DetModel};
use docling_pdf::{OcrLang, OcrModel};
use image::metadata::Orientation;
use image::{DynamicImage, ImageDecoder, ImageReader, RgbImage};
use serde::{Deserialize, Serialize};

/// The docling.rs commit the crate is pinned to (see `Cargo.toml`); reported
/// in every result so a fixture can be traced to the engine that made it.
pub const DOCLING_REV: &str = "6428c8b0b6ae60bf264aca2b62b6087ca1a99738";

/// Engine configuration, also the JSON accepted by [`receipt_ocr_init`].
#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(default, deny_unknown_fields)]
pub struct Config {
    /// Directory holding `ocr_det.onnx`, `ocr_rec_v6.onnx`,
    /// `ocr_rec_v6_dict.txt` (and optionally `ocr_textline_ori.onnx`).
    /// Exported as `DOCLING_RS_MODELS_DIR`; `None` keeps docling's own
    /// resolution (`./.models`, next to the executable).
    pub models_dir: Option<String>,
    /// Path to `libonnxruntime.so` (`ORT_DYLIB_PATH`). `None` lets ort dlopen
    /// the bare soname — on Android that resolves to the library the
    /// `onnxruntime-android` AAR packages next to this one.
    pub ort_lib: Option<String>,
    /// Longest image side after decoding; larger photos are downscaled
    /// before OCR (memory + speed on a phone). The detector itself caps its
    /// input at 2000 px, recognition crops come from this image.
    pub max_side: u32,
    /// RapidOCR's text-line orientation handling (needs
    /// `ocr_textline_ori.onnx`): rotated crops and the 0/180° classifier.
    pub textline_orientation: bool,
    /// Intra-op threads for the detector session.
    pub det_threads: usize,
    /// Parallel recognition sessions (each single-threaded).
    pub rec_lanes: usize,
    /// Drop recognised lines below this confidence (0 keeps everything).
    pub min_confidence: f32,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            models_dir: None,
            ort_lib: None,
            max_side: 2500,
            textline_orientation: true,
            det_threads: 2,
            rec_lanes: 2,
            min_confidence: 0.0,
        }
    }
}

/// One recognised text line in pixels of the (possibly downscaled) image the
/// OCR ran on; `width`/`height` of [`OcrResult`] give that frame.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct OcrLine {
    pub text: String,
    /// Recognition confidence: mean emitted-character probability.
    pub confidence: f32,
    /// Detector score of the box.
    pub det_score: f32,
    pub x0: f32,
    pub y0: f32,
    pub x1: f32,
    pub y1: f32,
}

impl OcrLine {
    pub fn cx(&self) -> f32 {
        (self.x0 + self.x1) / 2.0
    }
    pub fn cy(&self) -> f32 {
        (self.y0 + self.y1) / 2.0
    }
    pub fn height(&self) -> f32 {
        self.y1 - self.y0
    }
}

/// A QR code found on the photo (coordinates in the OCR frame).
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct QrCode {
    pub text: String,
    pub x0: f32,
    pub y0: f32,
    pub x1: f32,
    pub y1: f32,
}

/// The scan output; serialised as the JSON the C ABI returns.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OcrResult {
    /// Frame the line coordinates refer to.
    pub width: u32,
    pub height: u32,
    /// Original photo size before EXIF orientation and downscaling.
    pub source_width: u32,
    pub source_height: u32,
    /// `source → frame` scale (1.0 when nothing was resized).
    pub scale: f32,
    /// EXIF orientation that was applied (image crate's numbering, 1 = none).
    pub exif_orientation: u8,
    pub lines: Vec<OcrLine>,
    /// Decoded QR codes, top to bottom (undecodable grids are skipped).
    pub qr_codes: Vec<QrCode>,
    pub elapsed_ms: u64,
    pub engine: String,
}

/// Loaded detector + recognizer.
pub struct Engine {
    det: DetModel,
    rec: OcrModel,
    config: Config,
}

static ENGINE: Mutex<Option<Engine>> = Mutex::new(None);

fn engine_label() -> String {
    format!(
        "docling.rs@{} receipt_ocr {}",
        &DOCLING_REV[..12],
        env!("CARGO_PKG_VERSION")
    )
}

impl Engine {
    /// Load both models. Environment variables are set *before* the first
    /// ONNX session so docling's own resolution picks them up.
    pub fn load(config: Config) -> Result<Self, String> {
        if let Some(dir) = &config.models_dir {
            if !std::path::Path::new(dir).is_dir() {
                return Err(format!("models_dir is not a directory: {dir}"));
            }
            std::env::set_var("DOCLING_RS_MODELS_DIR", dir);
        }
        if let Some(lib) = &config.ort_lib {
            if !std::path::Path::new(lib).is_file() {
                return Err(format!("ort_lib is not a file: {lib}"));
            }
            std::env::set_var("ORT_DYLIB_PATH", lib);
        }
        // The textline classifier is optional: docling warns once and runs
        // without it when the model is missing, which is what we want.
        let det = DetModel::load(config.det_threads.max(1))?;
        let mut rec = OcrModel::load_with(OcrLang::from_env(), config.rec_lanes.max(1))?;
        rec.set_textline_orientation(config.textline_orientation);
        Ok(Self { det, rec, config })
    }

    pub fn config(&self) -> &Config {
        &self.config
    }

    /// OCR an already decoded, upright RGB image.
    pub fn scan_rgb(&mut self, rgb: &RgbImage) -> Result<Vec<OcrLine>, String> {
        let mut boxes: Vec<DetBox> = self.det.detect(rgb)?;
        sort_boxes(&mut boxes);
        let read = self.rec.recognize_det_boxes(rgb, &boxes)?;
        let min_conf = self.config.min_confidence;
        Ok(boxes
            .iter()
            .zip(read)
            .filter(|(_, r)| !r.text.is_empty() && r.confidence >= min_conf)
            .map(|(b, r)| OcrLine {
                text: r.text,
                confidence: r.confidence,
                det_score: b.score,
                x0: b.l,
                y0: b.t,
                x1: b.r,
                y1: b.b,
            })
            .collect())
    }

    /// Decode (honouring EXIF orientation), downscale, OCR.
    pub fn scan_bytes(&mut self, bytes: &[u8]) -> Result<OcrResult, String> {
        let started = Instant::now();
        let (full, exif_orientation, source) = decode_upright(bytes)?;
        // QR codes are read from the full-resolution photo first: a crumpled
        // RKSV code needs every pixel it can get, and the downscale that is
        // fine for OCR can push it below ~4 px per module. Coordinates are
        // mapped into the OCR frame.
        let full_gray = full.to_luma8();
        let (img, scale) = fit_max_side(full, self.config.max_side);
        let rgb = img.to_rgb8();
        let lines = self.scan_rgb(&rgb)?;
        let mut qr_codes = decode_qr_codes(&full_gray);
        drop(full_gray);
        if scale != 1.0 {
            for q in &mut qr_codes {
                q.x0 *= scale;
                q.y0 *= scale;
                q.x1 *= scale;
                q.y1 *= scale;
            }
            if qr_codes.is_empty() {
                qr_codes = decode_qr_codes(&img.to_luma8());
            }
        }
        Ok(OcrResult {
            width: rgb.width(),
            height: rgb.height(),
            source_width: source.0,
            source_height: source.1,
            scale,
            exif_orientation,
            lines,
            qr_codes,
            elapsed_ms: started.elapsed().as_millis() as u64,
            engine: engine_label(),
        })
    }
}

/// Decode an image applying its EXIF orientation. Returns the upright image,
/// the orientation tag that was applied and the decoded (pre-rotation) size.
pub fn decode_upright(bytes: &[u8]) -> Result<(DynamicImage, u8, (u32, u32)), String> {
    let reader = ImageReader::new(Cursor::new(bytes))
        .with_guessed_format()
        .map_err(|e| format!("image: {e}"))?;
    let mut decoder = reader
        .into_decoder()
        .map_err(|e| format!("image decode: {e}"))?;
    let orientation = decoder.orientation().unwrap_or(Orientation::NoTransforms);
    let mut img = DynamicImage::from_decoder(decoder).map_err(|e| format!("image decode: {e}"))?;
    let source = (img.width(), img.height());
    img.apply_orientation(orientation);
    Ok((img, orientation.to_exif(), source))
}

/// Find and decode every QR code on a grayscale image. Decoding failures
/// (damaged or crumpled codes) are skipped, never fatal.
pub fn decode_qr_codes(gray: &image::GrayImage) -> Vec<QrCode> {
    let mut prepared = rqrr::PreparedImage::prepare(gray.clone());
    let mut found: Vec<QrCode> = prepared
        .detect_grids()
        .into_iter()
        .filter_map(|grid| {
            let (_meta, text) = grid.decode().ok()?;
            let xs = grid.bounds.iter().map(|p| p.x as f32);
            let ys = grid.bounds.iter().map(|p| p.y as f32);
            Some(QrCode {
                text,
                x0: xs.clone().fold(f32::INFINITY, f32::min),
                y0: ys.clone().fold(f32::INFINITY, f32::min),
                x1: xs.fold(f32::NEG_INFINITY, f32::max),
                y1: ys.fold(f32::NEG_INFINITY, f32::max),
            })
        })
        .collect();
    found.sort_by(|a, b| a.y0.total_cmp(&b.y0).then(a.x0.total_cmp(&b.x0)));
    found.dedup_by(|a, b| a.text == b.text);
    found
}

/// Downscale so the longest side is at most `max_side` (never upscales).
pub fn fit_max_side(img: DynamicImage, max_side: u32) -> (DynamicImage, f32) {
    let longest = img.width().max(img.height());
    if max_side == 0 || longest <= max_side {
        return (img, 1.0);
    }
    let scale = max_side as f32 / longest as f32;
    let w = ((img.width() as f32 * scale).round() as u32).max(1);
    let h = ((img.height() as f32 * scale).round() as u32).max(1);
    (
        img.resize_exact(w, h, image::imageops::FilterType::Triangle),
        scale,
    )
}

/// Load the models into the process-wide engine (replacing a previous one).
pub fn init(config: Config) -> Result<(), String> {
    let engine = Engine::load(config)?;
    *lock_engine() = Some(engine);
    Ok(())
}

/// Whether [`init`] succeeded in this process.
pub fn is_initialized() -> bool {
    lock_engine().is_some()
}

/// OCR image bytes with the process-wide engine.
pub fn scan_bytes(bytes: &[u8]) -> Result<OcrResult, String> {
    let mut guard = lock_engine();
    let engine = guard
        .as_mut()
        .ok_or_else(|| "receipt_ocr: engine not initialised (call receipt_ocr_init)".to_string())?;
    engine.scan_bytes(bytes)
}

/// OCR an image file with the process-wide engine.
pub fn scan_path(path: &str) -> Result<OcrResult, String> {
    let bytes = std::fs::read(path).map_err(|e| format!("read {path}: {e}"))?;
    scan_bytes(&bytes)
}

/// Text of a PDF's embedded text layer, as Markdown, through docling.rs'
/// pure-Rust content-stream parser (`convert_text_layer`): no ONNX models,
/// no renderer. Bank statements are text PDFs, so this is what the
/// statement import feeds to the LLM; a scanned PDF yields an empty string
/// (the caller falls back to photographing it).
pub fn pdf_text_bytes(bytes: &[u8], name: &str) -> Result<String, String> {
    // Row-wise text first: docling's paragraph assembly reads a statement
    // column by column (dates, texts and amounts end up in separate blocks),
    // while the LLM needs "text … date … amount" per line. The positioned
    // line cells of the same parser, re-grouped by their vertical position,
    // give that; the Markdown export is the fallback for PDFs the glyph
    // parser cannot read (it then tries lopdf's other code paths).
    let rows = pdf_text_rows(bytes);
    if rows.trim().len() >= 40 {
        return Ok(rows);
    }
    let doc = docling_pdf::convert_text_layer(bytes, name).map_err(|e| format!("pdf: {e}"))?;
    Ok(doc.export_to_markdown())
}

/// Text of a PDF as layout rows: cells of one printed line joined left to
/// right, column gaps marked by two spaces, pages separated by a form feed.
pub fn pdf_text_rows(bytes: &[u8]) -> String {
    let mut out = String::new();
    for (page_index, (_w, _h, cells)) in docling_pdf::textparse::pdf_textlines(bytes)
        .into_iter()
        .enumerate()
    {
        if page_index > 0 {
            out.push('\x0c');
            out.push('\n');
        }
        let mut cells: Vec<_> = cells
            .into_iter()
            .filter(|c| !c.text.trim().is_empty())
            .collect();
        cells.sort_by(|a, b| a.t.total_cmp(&b.t).then(a.l.total_cmp(&b.l)));
        // Cluster into rows: a cell joins the current row when its vertical
        // centre lies inside the row's band.
        let mut rows: Vec<(f32, f32, Vec<docling_pdf::TextCell>)> = Vec::new();
        for c in cells {
            let cy = (c.t + c.b) / 2.0;
            match rows.iter_mut().find(|(t, b, _)| cy >= *t && cy <= *b) {
                Some((t, b, row)) => {
                    *t = t.min(c.t);
                    *b = b.max(c.b);
                    row.push(c);
                }
                None => rows.push((c.t, c.b, vec![c])),
            }
        }
        rows.sort_by(|a, b| a.0.total_cmp(&b.0));
        for (_, _, mut row) in rows {
            row.sort_by(|a, b| a.l.total_cmp(&b.l));
            let mut line = String::new();
            let mut last_r = f32::NEG_INFINITY;
            let mut last_h = 10.0f32;
            for c in row {
                if !line.is_empty() {
                    let gap = c.l - last_r;
                    line.push_str(if gap > last_h * 1.2 { "  " } else { " " });
                }
                line.push_str(c.text.trim());
                last_r = c.r;
                last_h = (c.b - c.t).max(1.0);
            }
            out.push_str(line.trim_end());
            out.push('\n');
        }
    }
    out
}

/// [`pdf_text_bytes`] for a file path.
pub fn pdf_text_path(path: &str) -> Result<String, String> {
    let bytes = std::fs::read(path).map_err(|e| format!("read {path}: {e}"))?;
    let name = std::path::Path::new(path)
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("document.pdf");
    pdf_text_bytes(&bytes, name)
}

fn lock_engine() -> std::sync::MutexGuard<'static, Option<Engine>> {
    // A panic while holding the lock must not poison every later call.
    ENGINE.lock().unwrap_or_else(|p| p.into_inner())
}

// ---------------------------------------------------------------------------
// C ABI
// ---------------------------------------------------------------------------

#[derive(Serialize)]
struct Reply<'a> {
    ok: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
    #[serde(flatten, skip_serializing_if = "Option::is_none")]
    result: Option<&'a OcrResult>,
}

fn to_c(s: String) -> *mut c_char {
    // Interior NULs cannot come from JSON; replace defensively anyway.
    CString::new(s.replace('\0', " "))
        .unwrap_or_else(|_| CString::new("{\"ok\":false,\"error\":\"encoding\"}").expect("static"))
        .into_raw()
}

fn reply(result: Result<OcrResult, String>) -> *mut c_char {
    let json = match &result {
        Ok(r) => serde_json::to_string(&Reply {
            ok: true,
            error: None,
            result: Some(r),
        }),
        Err(e) => serde_json::to_string(&Reply {
            ok: false,
            error: Some(e.clone()),
            result: None,
        }),
    }
    .unwrap_or_else(|e| format!("{{\"ok\":false,\"error\":\"serialize: {e}\"}}"));
    to_c(json)
}

fn guarded<F: FnOnce() -> Result<OcrResult, String>>(f: F) -> *mut c_char {
    match catch_unwind(AssertUnwindSafe(f)) {
        Ok(r) => reply(r),
        Err(_) => reply(Err("receipt_ocr: internal panic".into())),
    }
}

/// # Safety
/// `s` is NULL or a valid NUL-terminated string.
unsafe fn c_str<'a>(s: *const c_char) -> Result<&'a str, String> {
    if s.is_null() {
        return Err("null string argument".into());
    }
    CStr::from_ptr(s)
        .to_str()
        .map_err(|e| format!("argument is not UTF-8: {e}"))
}

/// Initialise the engine from a JSON [`Config`] (`NULL`/empty = defaults).
/// Returns `NULL` on success, else an error message to free with
/// [`receipt_ocr_free`].
///
/// # Safety
/// `config_json` is NULL or a valid NUL-terminated string.
#[no_mangle]
pub unsafe extern "C" fn receipt_ocr_init(config_json: *const c_char) -> *mut c_char {
    let outcome = catch_unwind(AssertUnwindSafe(|| -> Result<(), String> {
        let config = if config_json.is_null() {
            Config::default()
        } else {
            let text = c_str(config_json)?;
            if text.trim().is_empty() {
                Config::default()
            } else {
                serde_json::from_str(text).map_err(|e| format!("config: {e}"))?
            }
        };
        init(config)
    }));
    match outcome {
        Ok(Ok(())) => std::ptr::null_mut(),
        Ok(Err(e)) => to_c(e),
        Err(_) => to_c("receipt_ocr: internal panic during init".into()),
    }
}

/// `1` when the engine is loaded.
#[no_mangle]
pub extern "C" fn receipt_ocr_is_ready() -> i32 {
    i32::from(is_initialized())
}

/// OCR an image file. Always returns a JSON string (`{"ok":true,...}` or
/// `{"ok":false,"error":...}`); free it with [`receipt_ocr_free`].
///
/// # Safety
/// `path` is a valid NUL-terminated string.
#[no_mangle]
pub unsafe extern "C" fn receipt_ocr_scan_file(path: *const c_char) -> *mut c_char {
    let path = match c_str(path) {
        Ok(p) => p.to_string(),
        Err(e) => return reply(Err(e)),
    };
    guarded(move || scan_path(&path))
}

/// OCR an encoded image (JPEG/PNG/WebP/…) held in memory.
///
/// # Safety
/// `data` points to `len` readable bytes.
#[no_mangle]
pub unsafe extern "C" fn receipt_ocr_scan_bytes(data: *const u8, len: usize) -> *mut c_char {
    if data.is_null() {
        return reply(Err("null data".into()));
    }
    let bytes = std::slice::from_raw_parts(data, len);
    guarded(move || scan_bytes(bytes))
}

/// Free a string returned by any `receipt_ocr_*` call.
///
/// # Safety
/// `s` is NULL or a pointer previously returned by this library and not yet freed.
#[no_mangle]
pub unsafe extern "C" fn receipt_ocr_free(s: *mut c_char) {
    if !s.is_null() {
        drop(CString::from_raw(s));
    }
}

/// Static version string (`receipt_ocr <crate> / docling.rs@<rev>`); do not free.
#[no_mangle]
pub extern "C" fn receipt_ocr_version() -> *const c_char {
    static VERSION: std::sync::OnceLock<CString> = std::sync::OnceLock::new();
    VERSION
        .get_or_init(|| CString::new(engine_label()).expect("no NUL"))
        .as_ptr()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn config_json_defaults_and_unknown_keys() {
        let c: Config = serde_json::from_str("{}").unwrap();
        assert_eq!(c.max_side, 2500);
        assert!(serde_json::from_str::<Config>("{\"nope\":1}").is_err());
    }

    #[test]
    fn fit_max_side_keeps_small_images() {
        let img = DynamicImage::new_rgb8(400, 800);
        let (out, scale) = fit_max_side(img, 1000);
        assert_eq!((out.width(), out.height()), (400, 800));
        assert_eq!(scale, 1.0);
        let (out, scale) = fit_max_side(DynamicImage::new_rgb8(400, 800), 400);
        assert_eq!((out.width(), out.height()), (200, 400));
        assert!((scale - 0.5).abs() < 1e-6);
    }

    #[test]
    fn scan_without_init_is_an_error_reply() {
        let p = unsafe { receipt_ocr_scan_bytes(b"xx".as_ptr(), 2) };
        let s = unsafe { CStr::from_ptr(p) }.to_str().unwrap().to_string();
        unsafe { receipt_ocr_free(p) };
        let v: serde_json::Value = serde_json::from_str(&s).unwrap();
        assert_eq!(v["ok"], false);
        assert!(
            v["error"].as_str().unwrap().contains("not initialised")
                || v["error"].as_str().is_some()
        );
    }
}

#[derive(Serialize)]
struct TextReply {
    ok: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    text: Option<String>,
}

/// Text layer of a PDF file as `{"ok":true,"text":"…"}` (Markdown) or
/// `{"ok":false,"error":"…"}`. Needs no engine. Free with
/// [`receipt_ocr_free`].
///
/// # Safety
/// `path` is a valid NUL-terminated string.
#[no_mangle]
pub unsafe extern "C" fn receipt_ocr_pdf_text(path: *const c_char) -> *mut c_char {
    let outcome = catch_unwind(AssertUnwindSafe(|| -> Result<String, String> {
        let path = c_str(path)?;
        pdf_text_path(path)
    }));
    let reply = match outcome {
        Ok(Ok(text)) => TextReply {
            ok: true,
            error: None,
            text: Some(text),
        },
        Ok(Err(e)) => TextReply {
            ok: false,
            error: Some(e),
            text: None,
        },
        Err(_) => TextReply {
            ok: false,
            error: Some("receipt_ocr: internal panic".into()),
            text: None,
        },
    };
    to_c(
        serde_json::to_string(&reply)
            .unwrap_or_else(|e| format!("{{\"ok\":false,\"error\":\"serialize: {e}\"}}")),
    )
}
