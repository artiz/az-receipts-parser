# AZ Budget (az-receipts-parser)

Android app (Flutter) for a household budget that lives in one spreadsheet per
year, `Budget <year>.xlsx`, in a cloud folder (Google Drive, Dropbox, iCloud or
local storage). The app appends bookings to that file; the spreadsheet keeps
all the formulas, the overview and the charts, and stays editable on the
laptop. Receipts are read **on the device** with
[docling.rs](https://github.com/docling-project/docling.rs); bank statements and
banking-app screenshots are turned into bookings by docling.rs (text) plus an
OpenAI model (structure), with the user's own API key.

```
manual entry / quick tile ─┐
receipt photo ──► rust/receipt_ocr (docling.rs OCR + rqrr QR) ──► parser ──► one booking to confirm
screenshot ─────► rust/receipt_ocr OCR ──► text ─┐
statement PDF ──► docling.rs text layer (rows) ──┴► OpenAI (gpt-4.1-mini, JSON schema) ──► review list
                                                     │
                       local queue ◄─────────────────┘
                            │ sync (like a Drive client)
                            ▼
          Budget <year>.xlsx in the chosen folder: sheet "Buchungen" gets new rows,
          "Übersicht" inputs are editable, "Einstellungen" holds categories + limits
```

## The spreadsheet is the database

One file per year. A new user gets it from a bundled template
(`app/assets/templates/budget_{de,en,ru}.xlsx`, built by
`tools/budget_template.py`); the layout below is the contract, shown with
the German names. The English and Russian templates use the same layout with
translated sheet names, labels and categories, and the reader finds every
row by what its label means (`app/lib/budget/budget_labels.dart`), so a
file in any of the three languages, or one with renamed sheets, reads the
same way. Category names are never hard-coded; they come from the file.

| Sheet | Contract |
| --- | --- |
| `Buchungen` | Row 1 header, then `A` Datum, `B` Monat (formula), `C` Kategorie, `D` Beschreibung, `E` Betrag (€), `F` Notiz. Expenses positive, income negative. Rows are pre-formatted to 2000; the app fills the next empty one (and creates rows beyond 2000 when needed). |
| `Übersicht` | Input rows found by their label in column `A` (`Kontostand Monatsanfang…`, `Sparkonto`, `Kreditkarte offen…`), months in `B..M`; the `Plan` block from the row labelled `Plan` to `Summe Plan`. Everything else is formulas. |
| `Einstellungen` | Categories below the `Kategorie` header (`A` name, `B` Typ: Ausgabe / Einnahme / Umbuchung, `D` hint, `E` icon and colour as chosen in the app, e.g. `basket #FF2E7E`); label/value settings in `F`/`G` (`Monatslimit 1/2`, `Ausgabenlimit 1/2/3`). New settings may be appended below; the app reads whatever is there. |
| `Verlauf` | Month labels `YYYY-MM`; the app only re-targets them when it creates a new year. |
| `Regeln` | Optional. Below the `Muster` header: `A` pattern (case-insensitive, `*` for anything), `B` category, `C` description. The statement import and the receipt scan check these before the learned history and before the model; "save as rule" in the import review appends here (the sheet is created in an old file). |

The app never re-serialises the workbook. It patches individual cells in the
sheet XML inside the zip (`app/lib/budget/xlsx_workbook.dart`) and copies every
other zip entry byte for byte, so Excel/LibreOffice formulas, conditional
formats, the table, data validation, comments and charts survive. It sets
`fullCalcOnLoad` so the spreadsheet recalculates when opened. Tests check
this against a generated file and a LibreOffice-resaved copy.

Nothing about categories or quick entries is hard-coded: the category list,
the per-category autocomplete ("S" → "Spar" under Lebensmittel), the quick
tiles on the home screen (most used category + description pairs with their
last amount) and the category guessed for a scanned merchant all come from
the bookings in the file.

## Layout

| Path | What |
| --- | --- |
| `rust/receipt_ocr/` | Rust crate: docling.rs text detector + recognizer and the PDF text-layer reader behind a C ABI (`receipt_ocr_*`) for `dart:ffi`, plus the `receipt-ocr` host CLI. Reads Austrian RKSV QR codes too. |
| `app/` | Flutter app (Android). Budget model + xlsx patcher, folder access (Storage Access Framework), receipt parser, statement import, UI, l10n (en/de/ru). |
| `app/android/.../MainActivity.kt` | The folder bridge: pick a folder once (persisted grant), list/read/write files through the document provider of Drive, Dropbox, iCloud or the local storage. |
| `samples/receipts/`, `samples/golden/` | Example receipts and their OCR output: regression fixtures for the Dart parser tests. |
| `app/test/fixtures/` | Small synthetic `Budget 2026.xlsx` (plus a LibreOffice-resaved copy) for the xlsx tests. |
| `scripts/download_models.sh` / `.bat` | Fetches the ONNX models (~31 MB) into `app/assets/models` with SHA256 verification. |
| `scripts/build_android_rust.sh` / `.bat` | Cross-compiles the Rust crate with `cargo-ndk` into `app/android/app/src/main/jniLibs`. |
| `scripts/build_android.bat` | Windows one-shot: models → Rust `.so` → `flutter build apk` (`--run`, `--install`, `--debug`). |

## Using the app

1. **Start screen**: the first launch explains the app in five steps and asks
   for the folder (reachable again under *Settings → How to use the app*).
   Pick the folder that holds `Budget <year>.xlsx` (in the Drive app's folder
   picker choose the folder, not the file). The grant is persisted; the app
   lists the year files and loads the current year. An empty folder gets a
   `Budget <year>.xlsx` created from the template in the app language
   (German, English or Russian, following the system language unless set in
   Settings), with translated categories, plan block and limits
   (3000/4000 € per month, 200/500/1000 € per entry) that you can change in
   *Overview* or in the file. When the calendar year has no file yet, the
   app offers to create it from the latest one (categories, settings and
   plan copied, no bookings) or, if the folder is empty, from the template
   with a language choice.
2. **Entries**: the upper half of the screen holds the quick tiles (tap →
   confirm or change the amount), the lower half the bookings table with a
   search field, paged by 20 as you scroll. Tap a row to edit it (queued rows
   and rows already in the file alike, the file row is rewritten in place);
   the **+** on a row tops it up ("+6 Glühwein": amount added, detail appended
   to the note). *New entry* has category, description autocomplete, amount,
   note and date (category pickers list the categories alphabetically, the
   most used one is preselected); income is typed as a plain number and
   stored negative. A new
   booking with the same amount as one booked within three days asks whether
   to add its details to that booking's note instead (a scanned receipt of a
   purchase typed by hand). New bookings go into a local queue and are written
   to the file right away; without network they wait and are flushed on the
   next start/resume/sync, like a Drive client. Queued bookings whose year has
   no file (a mis-read receipt date) are shown in a banner with a *Fix date*
   action instead of waiting forever.
   The year follows the calendar: the current year's file is loaded, the year
   menu in the status line switches to another file, and when a new year has
   no file yet a banner offers to create `Budget <year>.xlsx` from the latest
   file (categories, settings and plan kept, bookings and account inputs
   cleared; `Verlauf` is left to the laptop).
3. **Camera button**: photograph a receipt. docling.rs OCR + the parser
   propose one booking: merchant as description, total as amount, the line
   items in the note, the category from the file's history for that merchant.
4. **Picture button**: a banking-app screenshot from the gallery → OCR →
   OpenAI → review list.
5. **PDF button**: a bank statement → docling.rs text layer (rebuilt as rows:
   text, value date, amount) → the rows are read deterministically: date and
   amount exactly as printed, merchant from the row or its detail line,
   card bills as Kreditkarte transfers, cash withdrawals and own transfers
   skipped. The category comes from the file's own history for that merchant;
   only merchants the file has never seen go to OpenAI, in one small request
   for their category. Without an API key those rows are simply flagged for
   you to pick. Rows whose amount and date match an existing booking are
   marked *already booked* and unticked. Nothing is written before *Add n*.
   Free text (screenshots) still goes to the model as a whole.
6. **Overview**: income, expenses with a traffic light against
   `Monatslimit 1/2` (green, amber from limit 1, red from limit 2; the same
   icon sits in the top bar of the home screen), saldo, per-category actual
   vs plan with a pencil to edit the month's plan, and the input rows of
   `Übersicht` (Kontostand, Sparkonto, Kreditkarte offen) editable per month;
   those accept a small formula (`=500+232,23`) that is kept in the cell.
   Tapping the expenses card edits the two month limits (written to
   `Einstellungen`). The first time the calendar month's expenses reach
   limit 1, and again at limit 2, the app posts a system notification.
7. **Settings → OpenAI**: API key (stored in Android's encrypted storage) and
   model (default `gpt-4.1-mini`). Only the statement/screenshot import uses it.
   **Settings → Language** overrides the system language (German, English,
   Russian).
8. **Settings → Categories**: name, type, hint, icon (from a built-in set)
   and colour of every category, stored in the file's `Einstellungen` sheet,
   plus *Add category* (several income categories, several credit cards). A
   rename follows into the bookings, the overview rows, the formulas that
   quote the name (income and transfer categories) and the conditional
   format of the entries sheet. A changed or added type rebuilds the
   overview's `Einnahmen` row (sum over every income category) and
   `Ausgaben` row (everything but income and transfer categories), blanks or
   restores the category's row in the actual block, extends the category
   dropdown of the entries sheet and clones the grey-italic format of
   transfer rows. A new *expense* category gets no row of its own in the
   sheet's actual/plan blocks (the app counts it anyway). When the file is in another language than the
   app (say it was created before the language was changed), *Translate file*
   turns category names and hints, type labels, settings labels and the
   overview/history labels into the app language; bookings are renamed with
   their categories, the user's own texts and the sheet names stay (formulas
   refer to the sheet names, and the entries table definition to its header).
9. **Share into the app**: AZ Budget is a share target for PDFs, images and
   text ("Share" in a shop's app, Gmail, the gallery, or "Open with" on a
   downloaded file). A shop's digital receipt (PDF e-bon) is read from its
   text layer with positions and goes through the same parser as a photo,
   straight to the entry sheet; a bank statement PDF goes to the review list;
   an image is scanned like a camera photo; text goes to the model. The same
   PDF routing applies to the PDF button on the home screen. Sharing needs
   a chosen folder; the shared copy is deleted afterwards.
10. **Writing safely**: every write re-reads the file and compares its
    modification time right before writing; if the laptop saved in between,
    the change is applied again to the fresh file instead of overwriting it.
    Before each write the previous version is copied to `.backup/` in the
    budget folder (at most once per ten minutes per year, the newest five
    kept; *Settings → Data* switches it off).
11. **Split a receipt**: the entry sheet of a scanned receipt offers *Split by
    category*: give each item a category and one booking per category is
    saved, the items in the notes, a rounding remainder with the main one.
    The scanned file (photo or PDF) goes to `Belege/<year>/` next to the
    budget files and is linked from the note (*Settings → Data*).
12. **Year view**: the month menu of *Overview* has a *Year* entry: twelve
    months as bars (colour = limit, plan grey, line = cumulated saldo) and
    every category's actual / plan / previous year (from `Budget <year-1>.xlsx`).
13. **Widget and shortcuts**: a home-screen widget shows the month's
    expenses against limit 1 with the traffic-light colour and a "+" for a
    booking; long-pressing the launcher icon offers scan, new booking and
    statement import.
14. **Settings → Data**: currency symbol (the file carries none), CSV export
    of the loaded year into the folder; *Overview* shares a text summary of
    the month.
15. **Overview**: under the Saldo a bar per expense category for the month,
   the plan in grey with the actual amount over it in the category's colour,
   icons on the x axis, the largest on the right; tapping a bar shows its
   name and numbers.

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
and the app refuses to start the OCR engine when the model assets are missing,
so a half-built APK fails loudly instead of silently returning empty scans.

The application id changed to `dev.artiz.az_budget` (label *AZ Budget*): the
old *Receipts* app can be uninstalled, it kept nothing the new one needs.

### Windows

Install once:

1. **Git for Windows** and **Visual Studio Build Tools** with the
   *Desktop development with C++* workload.
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
`%LOCALAPPDATA%\Android\Sdk\ndk`; set `ANDROID_NDK_HOME` to override. In the
repository root:

```bat
scripts\build_android.bat --run
```

downloads the models, cross-compiles the Rust crate for `arm64-v8a`, runs
`flutter pub get` and launches a debug build on the connected device.
`scripts\build_android.bat` alone builds
`app\build\app\outputs\flutter-apk\app-release.apk`; `--install` builds and
installs it; `--debug` builds a debug APK only. The steps can be run on their
own (`scripts\download_models.bat [--verify] [dir]`,
`scripts\build_android_rust.bat [--debug] [--abi arm64-v8a,x86_64]`).

Build time: the models step returns at once when the files are present
(`--verify` re-hashes them). The Rust step is incremental; it only takes
minutes when a Rust source changed, because the release profile links with
LTO. `--no-rust` skips it when only Dart/Kotlin changed. The Flutter release
build (Dart AOT + Gradle) is the slow part; for day-to-day work use `--run`,
which is a debug build with hot reload, and build the release APK only to
install it.

### Host CLI (fixtures, debugging, statement text, e-receipts)

```bash
cd rust/receipt_ocr && cargo build --release
```

```bash
rust/receipt_ocr/target/release/receipt-ocr \
  --models /path/to/models --ort-lib /path/to/libonnxruntime.so \
  --pretty --out-dir samples/golden samples/receipts/*.webp samples/receipts/*.png
```

```bash
rust/receipt_ocr/target/release/receipt-ocr --pdf-text Kontoauszug.pdf
```

```bash
rust/receipt_ocr/target/release/receipt-ocr --pdf-lines ebon.pdf --pretty > samples/golden/ebon.ocr.json
```

`--pdf-text` prints a statement as the app's import sees it (one printed row
per line, columns separated by two spaces); `--pdf-lines` prints a PDF's
text layer in the scan JSON format (lines with boxes), which is how a
digital receipt reaches the receipt parser and how its golden fixture is
made. Neither needs a model.
`--models` is any directory with the four files from `download_models.sh`; a
host `libonnxruntime.so` is e.g. `onnxruntime/capi/libonnxruntime.so.*` from the
`onnxruntime` PyPI wheel (`onnxruntime.dll` on Windows).

## Why det+rec and not the full docling pipeline

docling.rs' image pipeline runs layout analysis (RT-DETR, 65 MB int8) and merges
text into layout regions. A receipt parser needs the opposite: one box per
printed line with its geometry, so "name … price" rows can be rebuilt. The
crate therefore calls `docling_pdf::ocr_det::DetModel` + `docling_pdf::OcrModel`
directly, which needs only `ocr_det.onnx` + `ocr_rec_v6.onnx` (+ optional
`ocr_textline_ori.onnx`). The same applies to statements: the paragraph export
of the text layer reads a statement column by column, so the crate takes the
parser's positioned line cells (`docling_pdf::textparse::pdf_textlines`) and
regroups them by vertical position into printed rows.

ONNX Runtime is **not** linked at build time: the crate uses `ort`'s
`load-dynamic` and `dlopen`s `libonnxruntime.so`. On Android that library comes
from the `com.microsoft.onnxruntime:onnxruntime-android` AAR that Gradle
bundles (declared in `app/android/app/build.gradle.kts`); on a host you pass any
libonnxruntime ≥ 1.17.

## Tests and regression

* `app/test/budget_file_test.dart`: xlsx reading (categories, settings,
  entries, overview inputs), appending inside and beyond the pre-formatted
  rows, input/plan/setting updates, and the guarantee that only the touched
  sheet (and `workbook.xml`) changes in the zip. Runs against the generated
  fixture and its LibreOffice-resaved copy. Also the suggestion engine (quick
  tiles, autocomplete, learned categories).
* `app/test/budget_service_test.dart`: queue + sync with a fake folder,
  including offline, restart and write-through of overview inputs.
* `app/test/budget_template_test.dart`: every bundled template read through
  the same code (categories, types, limits, input and plan rows), written to
  (entries, limits, inputs, plan, new year) and the empty-folder path of the
  service (template in the app or system language, tried once per folder,
  clone once a file exists); category edits (icon and colour in column `E`,
  rename cascade into bookings, overview labels, quoted formulas and the
  conditional format) and the file translation against the English template
  and against a user-like fixture. After changing `tools/budget_template.py`,
  regenerate with `python3 tools/budget_template.py` (needs openpyxl; it also
  rewrites `app/lib/budget/template_texts.dart`, the dictionary the
  translation uses) and check with a LibreOffice recalculation that no cell
  shows an error. Note that LibreOffice trusts cached values in an xlsx, so a
  rewritten formula is stored without one.
* `app/test/statement_import_test.dart`: prompt and JSON-schema contract,
  sign enforcement, unknown categories, duplicate detection.
* `app/test/receipt_parser_test.dart` and `units_test.dart`: the receipt
  parser against every fixture in `samples/golden` (photos, plus
  `billa_ebon`, a synthetic digital receipt PDF read through
  `receipt-ocr --pdf-lines`, where quantity lines sit above their item),
  money parsing, row grouping, RKSV QR, categoriser.
* `app/test/share_receiver_test.dart`: the queue of shared files.
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

## How receipt parsing works

1. **Rows.** Detector boxes are grouped by vertical centre into printed rows
   (`ocr_rows.dart`); the rightmost fragment is where prices live.
2. **QR first.** Austrian RKSV codes (`_R1-AT1_…`) give the exact timestamp,
   the gross amount per VAT rate and the register/receipt ids; OCR only fills
   in merchant and items. Decoding is pure Rust (`rqrr`) on the full-resolution
   photo.
3. **Dictionaries, German first.** Total rows (`SUMME`, `TOTAL`, `Gesamt`,
   `zu zahlen`…), non-item rows (`MwSt`, `Netto`, `Bar`, `Rückgeld`, card
   terminal lines…), date priority, payment (card words win over cash words),
   VAT tables resolved by arithmetic (net + VAT = gross).
4. **Items.** Rows between the header and the total with a price at the right
   edge; multi-line items, quantity lines (`= 2 x 1,89`) and OCR slips are
   handled explicitly and covered by the fixtures.
5. **Category.** First the file's own history for the merchant (`EntrySuggestions.categoryFor`),
   then the built-in merchant dictionary (`merchants.dart`) mapped onto the
   file's category names, then the most used expense category; the user
   confirms in the entry form either way.

## Known limits

* Android only (the folder bridge is Storage Access Framework). iCloud Drive
  works through Apple's Android client only where that exists; Dropbox and
  Google Drive expose their folders through their Android apps.
* Edits of bookings already in the file are done in the spreadsheet, not in
  the app; the app edits only its queued entries and the overview inputs.
* A statement that is a scanned image (no text layer) is reported as empty;
  photograph the page instead (screenshot path).
* The five sample receipt photos are previews whose QR codes are too small to
  decode; phone photos at full resolution decode. Only `arm64-v8a` is built by
  default.
