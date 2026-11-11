#!/bin/bash -eu
# Run the upstream harnesses the way OSS-Fuzz does (empty corpus, no
# dictionary, close_fd_mask=3), then replay the resulting corpora through the
# coverage build and write llvm-cov reports.
#   DURATION=600 scripts/baseline.sh [run-name]
#
# UBSan findings are not fatal during the run (HALT_ON_UB=0), otherwise a UB
# site early in a parser stops the fuzzer from ever exploring past it and the
# coverage numbers understate what the harness reaches. The corpus is replayed
# afterwards to list every UB site it triggers (ub_sites.txt).
#
# Optional settings (the defaults reproduce the original baseline):
#   HARNESSES="h1_api_fuzzer"  which binaries to run (default: upstream $FUZZERS)
#   SEEDS=<dir>                copied into each corpus before fuzzing
#   EXTERNAL_LIBS=1            use build/fuzz-extlibs and build/cov-extlibs
. "$(dirname "$0")/env.sh"
DURATION="${DURATION:-600}"
RUN="$ROOT/results/${1:-baseline}"
# FUZZERS stays upstream-only because build.sh hands it to make.
HARNESSES="${HARNESSES:-$FUZZERS}"
# Same rule as build.sh for where the EXTERNAL_LIBS=1 builds live.
SUF=""
if [ "${EXTERNAL_LIBS:-0}" = 1 ]; then SUF=-extlibs; fi
FUZZ="$ROOT/build/fuzz$SUF/ossfuzz"
COV="$ROOT/build/cov$SUF/ossfuzz"
mkdir -p "$RUN"
export UBSAN_OPTIONS="halt_on_error=${HALT_ON_UB:-0}"

# Everything needed to report this run's numbers honestly.
{
	echo "date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
	echo "host: $(uname -srm), $(nproc) cores"
	echo "duration_s: $DURATION"
	echo "harnesses: $HARNESSES (one core per harness)"
	echo "builds: build/fuzz$SUF build/cov$SUF"
	echo "libsndfile: $(git -C "$SRC" rev-parse HEAD)"
	echo "clang: $(clang --version | head -1)"
	if [ -n "${SEEDS:-}" ]; then
		echo "seeds: $SEEDS ($(ls "$SEEDS" | wc -l | tr -d ' ') files)"
	else
		echo "seeds: none (empty corpus)"
	fi
} > "$RUN/meta.txt"

# One fuzzer per core. Fork mode keeps going past crashes, saving each
# crashing input under crashes/.
for f in $HARNESSES; do
	mkdir -p "$RUN/corpus/$f" "$RUN/crashes/$f"
	# Seeds go into the corpus itself, so the coverage replay below counts
	# what the seeds reach as well as what the fuzzer added.
	if [ -n "${SEEDS:-}" ]; then cp -r "$SEEDS"/. "$RUN/corpus/$f/"; fi
	"$FUZZ/$f" "$RUN/corpus/$f" \
		-fork=1 -ignore_crashes=1 -ignore_timeouts=1 -ignore_ooms=1 \
		-max_total_time="$DURATION" -timeout=25 -rss_limit_mb=1024 \
		-close_fd_mask=3 -artifact_prefix="$RUN/crashes/$f/" \
		> "$RUN/$f.log" 2>&1 &
done
wait

OBJS=""
for f in $HARNESSES; do
	UBSAN_OPTIONS=halt_on_error=0 "$FUZZ/$f" \
		-runs=0 -close_fd_mask=1 "$RUN/corpus/$f" > "$RUN/$f.ub.log" 2>&1 || true
	LLVM_PROFILE_FILE="$RUN/$f.profraw" "$COV/$f" \
		-runs=0 -close_fd_mask=3 "$RUN/corpus/$f" > "$RUN/$f.replay.log" 2>&1
	OBJS="$OBJS -object $COV/$f"
done
llvm-profdata merge -sparse "$RUN"/*.profraw -o "$RUN/merged.profdata"

# llvm-cov takes the first binary positionally and the rest via -object.
OBJS="${OBJS# -object }"
llvm-cov report $OBJS -instr-profile="$RUN/merged.profdata" "$SRC/src" > "$RUN/coverage.txt"
llvm-cov export $OBJS -instr-profile="$RUN/merged.profdata" -summary-only "$SRC/src" > "$RUN/coverage.json"
llvm-cov show $OBJS -instr-profile="$RUN/merged.profdata" -format=html \
	-output-dir="$RUN/html" "$SRC/src" > /dev/null
grep -h 'runtime error' "$RUN"/*.ub.log | sed "s|$SRC/||" \
	| sed -E 's/: runtime error: ([a-z -]+).*/ \1/' | sort | uniq -c | sort -rn > "$RUN/ub_sites.txt" || true
python3 "$ROOT/scripts/summarize.py" "$RUN"
