# az-receipts-parser

Android app (Flutter) that photographs shop receipts, reads them **on the device**
with [docling.rs](https://github.com/docling-project/docling.rs), stores them in a
local SQLite database and categorises them automatically on two levels
(receipt → merchant category, line item → keyword category). No network access,
no cloud.

```
photo ──► rust/receipt_ocr (docling.rs PP-OCR det+rec, rqrr QR) ──► JSON lines + boxes
      ──► Dart: rows → ReceiptParser → Categorizer → drift/SQLite ──► UI (list, stats, edit)
```

## Layout

| Path | What |
| --- | --- |
| `rust/receipt_ocr/` | Rust crate: docling.rs text detector + recognizer behind a C ABI (`receipt_ocr_*`) for `dart:ffi`, plus the `receipt-ocr` host CLI. Reads Austrian RKSV QR codes too. |
| `app/` | Flutter app (Android). Parser, categoriser, DB, UI, l10n (en/de/ru). |
| `samples/receipts/` | Example receipts (dm, TEDi, Ernsting's, Action, TK Maxx, synthetic RKSV QR). |
| `samples/golden/` | OCR output of the samples, produced by the CLI. **Regression fixtures** for the Dart parser tests. |
| `scripts/download_models.sh` | Fetches the ONNX models (~31 MB) into `app/assets/models` with SHA256 verification. |
| `scripts/build_android_rust.sh` | Cross-compiles the Rust crate with `cargo-ndk` into `app/android/app/src/main/jniLibs`. |

## Why det+rec and not the full docling pipeline

docling.rs' image pipeline runs layout analysis (RT-DETR, 65 MB int8) and merges
text into layout regions. A receipt parser needs the opposite: one box per
printed line with its geometry, so "name … price" rows can be rebuilt. The
crate therefore calls `docling_pdf::ocr_det::DetModel` + `docling_pdf::OcrModel`
directly (the same code path the pipeline uses), which needs only
`ocr_det.onnx` + `ocr_rec_v6.onnx` (+ optional `ocr_textline_ori.onnx`).

ONNX Runtime is **not** linked at build time: the crate uses `ort`'s
`load-dynamic` and `dlopen`s `libonnxruntime.so`. On Android that library comes
from the `com.microsoft.onnxruntime:onnxruntime-android` AAR that Gradle
bundles (declared in `app/android/app/build.gradle.kts`); on a host you pass any
libonnxruntime ≥ 1.17 (pip wheel, Maven jar, GitHub release).

## Build

Prerequisites: Rust ≥ 1.92, Flutter 3.47 stable, Android SDK + NDK (r26+),
`cargo install cargo-ndk`.

```bash
scripts/download_models.sh                      # models → app/assets/models (gitignored)
```

```bash
scripts/build_android_rust.sh                   # libreceipt_ocr.so → app/android/app/src/main/jniLibs/arm64-v8a
```

```bash
cd app && flutter pub get && flutter build apk --release
```

The Gradle build refuses to package the app when `libreceipt_ocr.so` is missing,
and the app refuses to start the engine when the model assets are missing, so a
half-built APK fails loudly instead of silently returning empty scans.

### Windows

Every script has a `.bat` twin: `scripts\download_models.bat`,
`scripts\build_android_rust.bat`, and `scripts\build_android.bat`, which chains
all steps (models → Rust `.so` → `flutter build apk`).

Install once:

1. **Git for Windows** and **Visual Studio Build Tools** with the
   *Desktop development with C++* workload (the MSVC linker is needed for host
   Rust binaries such as `cargo-ndk` and the CLI).
2. **Rust**: run `rustup-init.exe` from <https://rustup.rs>, then
   `cargo install cargo-ndk`.
3. **Flutter SDK** 3.47 stable: unzip to e.g. `C:\src\flutter` and add
   `C:\src\flutter\bin` to `PATH`.
4. **Android Studio**: in *SDK Manager → SDK Tools* tick *Android SDK
   Platform-Tools*, *Android SDK Command-line Tools* and *NDK (Side by side)*.
   Then run `flutter doctor --android-licenses` and `flutter doctor` until the
   Android toolchain row is green.
5. On the phone enable *Developer options → USB debugging* and connect it;
   `adb devices` must list it.

The build script finds the NDK on its own under `%ANDROID_HOME%\ndk` or
`%LOCALAPPDATA%\Android\Sdk\ndk`; set `ANDROID_NDK_HOME` to override. Build and
run from a *Developer Command Prompt* (or any terminal with Flutter and Cargo on
`PATH`), in the repository root:

```bat
scripts\build_android.bat --run
```

That downloads the models, cross-compiles the Rust crate for `arm64-v8a`, runs
`flutter pub get` and launches a debug build on the connected device with hot
reload. Other modes:

```bat
scripts\build_android.bat
```

builds `app\build\app\outputs\flutter-apk\app-release.apk`;
`scripts\build_android.bat --install` builds and installs that APK on the
connected phone; `--debug` builds a debug APK only. The individual steps can be
run on their own (`scripts\download_models.bat [dir]`,
`scripts\build_android_rust.bat [--debug] [--abi arm64-v8a,x86_64]`), e.g. after a
Rust change only the second one plus `flutter run` is needed. `--abi x86_64`
adds the ABI for the Android emulator (the emulator's own ONNX Runtime comes
from the same AAR).

Host CLI on Windows:

```bat
cd rust\receipt_ocr && cargo build --release
```

```bat
rust\receipt_ocr\target\release\receipt-ocr.exe --models app\assets\models --ort-lib C:\path\to\onnxruntime.dll --pretty samples\receipts\tedi_wien.webp
```

`onnxruntime.dll` (≥ 1.17) comes from the `onnxruntime` PyPI wheel
(`onnxruntime\capi\onnxruntime.dll`) or from
`onnxruntime-win-x64-<version>.zip` on the ONNX Runtime GitHub releases page.

### Host CLI (for fixtures and debugging)

```bash
cd rust/receipt_ocr && cargo build --release
```

```bash
rust/receipt_ocr/target/release/receipt-ocr \
  --models /path/to/models --ort-lib /path/to/libonnxruntime.so \
  --pretty --out-dir samples/golden samples/receipts/*.webp samples/receipts/*.png
```

`--models` is any directory with the four files from `download_models.sh`.
A host `libonnxruntime.so` is e.g. `onnxruntime/capi/libonnxruntime.so.*` from the
`onnxruntime` PyPI wheel.

## Tests and regression

* `app/test/receipt_parser_test.dart` parses every fixture in `samples/golden`
  and checks merchant, date/time, total, payment, address, VAT rates, every
  line item with its price, that items add up to the total, and the item-level
  categories. Add a receipt = add a photo to `samples/receipts`, run the CLI
  into `samples/golden`, add its expectations.
* `app/test/units_test.dart` covers money parsing, row grouping, the RKSV QR
  parser and the categoriser (longest-match, word boundaries, learned rules).
* `cargo test` in `rust/receipt_ocr` covers the C ABI contract.

```bash
cd app && flutter analyze && flutter test
```

```bash
cd rust/receipt_ocr && cargo fmt --check && cargo clippy --all-targets && cargo test --release
```

The docling.rs dependency is pinned to a commit in `rust/receipt_ocr/Cargo.toml`.
Bumping it can change OCR output; regenerate the goldens with the CLI and run the
Dart tests to see what moved before committing the new fixtures.

## How parsing works

1. **Rows.** Detector boxes are grouped by vertical centre into printed rows
   (`ocr_rows.dart`); the rightmost fragment is where prices live.
2. **QR first.** Austrian RKSV codes (`_R1-AT1_…`) give the exact timestamp,
   the gross amount per VAT rate and the register/receipt ids; OCR only fills
   in merchant and items. Decoding is pure Rust (`rqrr`) on the full-resolution
   photo.
3. **Dictionaries, German first.** Total rows (`SUMME`, `TOTAL`, `Gesamt`,
   `zu zahlen`…), non-item rows (`MwSt`, `Netto`, `Bar`, `Rückgeld`, card
   terminal lines…), date priority (a `Datum` row → a row with date and time →
   first date), payment (card words win over cash words), VAT tables resolved
   by arithmetic (net + VAT = gross) so column order does not matter.
4. **Items.** Rows between the header and the total with a price at the right
   edge. Multi-line items (TEDi article number row, Ernsting's barcode row,
   Action's size row), quantity lines (`= 2 x 1,89`) and OCR slips (`0:65`,
   `ARTIKEL` glued to the first item, `20.G0%`) are handled explicitly and
   covered by the fixtures.
5. **Categories.** Merchant dictionary (`merchants.dart`) → receipt category;
   keyword dictionary (`default_rules.dart`) → item category, longest match
   wins, fallback to the receipt category. When the user changes a category in
   the editor the app stores a learned rule (merchant name or normalised item
   name) that wins ties next time. Rules are editable under Settings.

## Known limits

* The five sample photos in this repo are 795×1412 previews; their QR codes are
  below ~4 px per module and no decoder (rqrr, rxing, OpenCV) reads them. Phone
  photos at full resolution decode; the synthetic sample proves the path.
  OCR alone still extracts total/date/items for all five.
* Only `arm64-v8a` is built by default (`--abi` on the build script for more).
* OCR languages: the PP-OCRv6 multilingual recognizer reads Latin scripts
  incl. German umlauts; the parser dictionaries are German + English, the UI is
  English, German and Russian.
* Receipt photos are stored in the app's private documents directory; the
  database can be exported (CSV/JSON) or backed up as a SQLite file from
  Settings. There is no restore UI yet.
