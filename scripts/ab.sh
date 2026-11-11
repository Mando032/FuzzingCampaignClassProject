#!/bin/bash -eu
# Equal-effort comparison of harnesses. Every harness in ARMS gets its own
# baseline.sh run: alone, on one core, with the same SEEDS and DURATION,
# repeated REPS times.
#   DURATION=600 REPS=3 SEEDS=<dir> scripts/ab.sh <name>
#
# Runs are sequential, so harnesses never compete for CPU, and the harnesses
# alternate within each repetition, so a slow spell on the machine does not
# land on one harness only. Each run goes to results/<name>/<harness>-<rep>/
# and ab_summary.py then compares them (median and min-max per file).
. "$(dirname "$0")/env.sh"
NAME="${1:?usage: ab.sh <name>}"
ARMS="${ARMS:-$FUZZERS h1_api_fuzzer h2_raw_fuzzer}"
# Never write into an existing experiment (committed results live here).
[ ! -e "$ROOT/results/$NAME" ] || { echo "results/$NAME already exists" >&2 ; exit 1 ; }

for rep in $(seq "${REPS:-3}"); do
	for h in $ARMS; do
		echo "== $h, repetition $rep"
		HARNESSES="$h" "$ROOT/scripts/baseline.sh" "$NAME/$h-$rep" > /dev/null
	done
done
python3 "$ROOT/scripts/ab_summary.py" "$ROOT/results/$NAME"
