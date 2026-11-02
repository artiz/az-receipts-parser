#!/usr/bin/env bash
# Cross-compile rust/receipt_ocr for Android (arm64) and drop the .so into the
# Flutter project's jniLibs. Requires:
#   - Android NDK (ANDROID_NDK_HOME, or $ANDROID_HOME/ndk/<version>)
#   - rustup target aarch64-linux-android
#   - cargo-ndk  (cargo install cargo-ndk)
#
# Usage: scripts/build_android_rust.sh [--debug] [--abi arm64-v8a[,x86_64]]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CRATE="$ROOT/rust/receipt_ocr"
OUT="$ROOT/app/android/app/src/main/jniLibs"
PROFILE=--release
ABIS="arm64-v8a"

while [ $# -gt 0 ]; do
  case "$1" in
    --debug) PROFILE="" ;;
    --abi) ABIS="$2"; shift ;;
    *) echo "unknown option $1" >&2; exit 2 ;;
  esac
  shift
done

if [ -z "${ANDROID_NDK_HOME:-}" ]; then
  if [ -n "${ANDROID_HOME:-}" ] && [ -d "$ANDROID_HOME/ndk" ]; then
    ANDROID_NDK_HOME="$(ls -d "$ANDROID_HOME"/ndk/* | sort -V | tail -1)"
    export ANDROID_NDK_HOME
  else
    echo "ANDROID_NDK_HOME is not set and no NDK found under \$ANDROID_HOME/ndk" >&2
    exit 1
  fi
fi
command -v cargo-ndk >/dev/null || { echo "cargo-ndk missing: cargo install cargo-ndk" >&2; exit 1; }

for abi in ${ABIS//,/ }; do
  case "$abi" in
    arm64-v8a) rustup target add aarch64-linux-android >/dev/null ;;
    x86_64) rustup target add x86_64-linux-android >/dev/null ;;
    armeabi-v7a) rustup target add armv7-linux-androideabi >/dev/null ;;
  esac
done

# `ort` is built with `load-dynamic`: nothing from pyke's CDN is downloaded and
# libonnxruntime.so comes from the onnxruntime-android AAR at run time.
TARGETS=()
for abi in ${ABIS//,/ }; do TARGETS+=(-t "$abi"); done
(cd "$CRATE" && cargo ndk "${TARGETS[@]}" -o "$OUT" --platform 26 build $PROFILE --lib)

echo
find "$OUT" -name 'libreceipt_ocr.so' -exec ls -la {} \;
