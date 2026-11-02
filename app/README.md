# az_receipts (Flutter app)

See the repository README for the full build. Short version:

```bash
../scripts/download_models.sh && ../scripts/build_android_rust.sh
```

```bash
flutter pub get && flutter build apk --release
```

Code map: `lib/ocr` (FFI to `rust/receipt_ocr`, row grouping),
`lib/parser` (receipt fields, RKSV QR, merchants), `lib/categorize`
(two-level rules), `lib/data` (drift schema + repository), `lib/ui`.
