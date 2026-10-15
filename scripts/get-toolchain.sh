#!/bin/bash -eu
# Unpack clang/llvm-cov/compiler-rt into toolchain/ without root. Only needed
# when clang is not installed system-wide. Relies on libllvm21 and
# libclang-cpp21 already being installed (they are on a stock Ubuntu 26.04
# desktop); the downloaded versions must match those.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/toolchain/debs"
cd "$ROOT/toolchain/debs"
apt-get download clang-21 libclang-common-21-dev libclang-rt-21-dev llvm-21 llvm-21-linker-tools
for d in *.deb; do dpkg -x "$d" ../root; done
../root/usr/lib/llvm-21/bin/clang --version
