# Sourced by the other scripts. Sets up paths and the pinned target revision.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/libsndfile"
PINNED_COMMIT=b9103bd48b6c8fb517ae737fe3baee0c718b804c
FUZZERS="sndfile_fuzzer sndfile_alt_fuzzer"

# Prefer a system clang (sudo apt install clang llvm); otherwise fall back to
# the LLVM 21 packages unpacked under toolchain/ by scripts/get-toolchain.sh.
if ! command -v clang >/dev/null 2>&1; then
	export PATH="$ROOT/toolchain/root/usr/lib/llvm-21/bin:$PATH"
fi
export CC=clang CXX=clang++
