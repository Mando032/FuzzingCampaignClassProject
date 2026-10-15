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
. "$(dirname "$0")/env.sh"
DURATION="${DURATION:-600}"
RUN="$ROOT/results/${1:-baseline}"
mkdir -p "$RUN"
export UBSAN_OPTIONS="halt_on_error=${HALT_ON_UB:-0}"

# One fuzzer per core. Fork mode keeps going past crashes, saving each
# crashing input under crashes/.
for f in $FUZZERS; do
	mkdir -p "$RUN/corpus/$f" "$RUN/crashes/$f"
	"$ROOT/build/fuzz/ossfuzz/$f" "$RUN/corpus/$f" \
		-fork=1 -ignore_crashes=1 -ignore_timeouts=1 -ignore_ooms=1 \
		-max_total_time="$DURATION" -timeout=25 -rss_limit_mb=1024 \
		-close_fd_mask=3 -artifact_prefix="$RUN/crashes/$f/" \
		> "$RUN/$f.log" 2>&1 &
done
wait

OBJS=""
for f in $FUZZERS; do
	UBSAN_OPTIONS=halt_on_error=0 "$ROOT/build/fuzz/ossfuzz/$f" \
		-runs=0 -close_fd_mask=1 "$RUN/corpus/$f" > "$RUN/$f.ub.log" 2>&1 || true
	LLVM_PROFILE_FILE="$RUN/$f.profraw" "$ROOT/build/cov/ossfuzz/$f" \
		-runs=0 -close_fd_mask=3 "$RUN/corpus/$f" > "$RUN/$f.replay.log" 2>&1
	OBJS="$OBJS -object $ROOT/build/cov/ossfuzz/$f"
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
