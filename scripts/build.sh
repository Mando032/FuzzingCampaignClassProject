#!/bin/bash -eu
# Build libsndfile and the upstream OSS-Fuzz harnesses.
#   build.sh fuzz   ASan + UBSan + libFuzzer        -> build/fuzz
#   build.sh cov    source-based coverage + libFuzzer -> build/cov
#
# The configuration mirrors ossfuzz/ossfuzz.sh: static library, and no
# FLAC/Ogg/Vorbis/Opus/MPEG, because the OSS-Fuzz builder image does not
# install those libraries. Set EXTERNAL_LIBS=1 to link them in instead.
#
# UBSan is built recoverable so one binary serves both uses: set
# UBSAN_OPTIONS=halt_on_error=1 at run time to treat UB as a crash.
. "$(dirname "$0")/env.sh"
MODE="${1:?usage: build.sh fuzz|cov}"

case "$MODE" in
	fuzz) SAN="-fsanitize=address,undefined,fuzzer-no-link" ;;
	cov)  SAN="-fsanitize=fuzzer-no-link -fprofile-instr-generate -fcoverage-mapping" ;;
	*)    echo "unknown mode $MODE" >&2 ; exit 1 ;;
esac
FLAGS="-O1 -g -fno-omit-frame-pointer $SAN"

if [ ! -d "$SRC/.git" ]; then
	git clone https://github.com/libsndfile/libsndfile.git "$SRC"
fi
git -C "$SRC" checkout -q "$PINNED_COMMIT"
[ -x "$SRC/configure" ] || (cd "$SRC" && autoreconf -vif)

if [ "${EXTERNAL_LIBS:-0}" = 1 ]; then
	BUILD="$ROOT/build/$MODE-extlibs" ; LIBOPTS=""
else
	BUILD="$ROOT/build/$MODE" ; LIBOPTS="--disable-external-libs --disable-mpeg"
fi
# Always start clean: make does not rebuild objects when only CFLAGS change.
rm -rf "$BUILD"
mkdir -p "$BUILD" && cd "$BUILD"

CFLAGS="$FLAGS" CXXFLAGS="$FLAGS" LIB_FUZZING_ENGINE=-fsanitize=fuzzer \
	"$SRC/configure" --disable-shared --enable-ossfuzzers $LIBOPTS
make -j"$(nproc)" src/libsndfile.la
for f in $FUZZERS; do make -j"$(nproc)" "ossfuzz/$f"; done
ls -la $(printf "$BUILD/ossfuzz/%s " $FUZZERS)
