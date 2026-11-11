# H2 byterate findings (Nov 10, 2026)

Both found by `h2_raw_fuzzer` (`h2_raw_harness.cc`) at libsndfile `b9103bd`, in the Docker image on arm64 (Apple Silicon, OrbStack), from an empty corpus. Both are in `sf_current_byterate()`, which no upstream harness calls.

| Input | Site | What | Upstream status |
|---|---|---|---|
| `dwvw-byterate-div0.input` | `src/dwvw.c:178:49` | `dwvw_byterate()` divides by `sf.frames`, which is 0 for RAW DWVW data that decodes to no frames | Fixed after our pin in `e82eb494` ("Fix divide-by-zero in byterate functions on empty files", Oct 8 2026). Known bug, rediscovered. |
| `gsm610-byterate-overflow.input` | `src/sndfile.c:1665:50` | `samplerate * channels * 13000` in `int` overflows once `samplerate * channels > 165,191` | Still present at upstream `396a715d` (Oct 28 2026), the newest commit in our local clone. Not yet searched for in GitHub issues or OSS-Fuzz. |

In these RAW inputs the sample rate comes from the harness's control bytes (H2 limits it to 1–384000 Hz), i.e. from the caller. The overflow is only a file-input bug if a header can set it: GSM610 is also read from WAV, AIFF and W64 (`gsm610_init` callers), whose headers carry the sample rate. That still needs a WAV reproducer. The other `sf_current_byterate` branches use the same `int` arithmetic.

On arm64 the DWVW division by zero does not crash (AArch64 integer division returns 0 instead of trapping); only UBSan reports it. On x86-64 it should raise SIGFPE. Not yet checked there.

## How these were produced

```sh
# 300 s unguarded run, UBSan recoverable -> unguarded-300s.log (only these two sites)
docker run --rm -v "$PWD/results:/work/results" -e H2_BYTERATE_UNGUARDED=1 sndfile-fuzz \
  build/fuzz/ossfuzz/h2_raw_fuzzer -max_total_time=300 /tmp/c
# Reproducers: same, with UBSAN_OPTIONS=halt_on_error=1 and -seed=1..8, -max_total_time=120;
# every seed stopped at one of the two sites (*.find.log).
```

Replay (`replay.txt`):

```sh
docker run --rm -v "$PWD/results:/work/results" -e UBSAN_OPTIONS=halt_on_error=1 \
  -e H2_BYTERATE_UNGUARDED=1 sndfile-fuzz build/fuzz/ossfuzz/h2_raw_fuzzer \
  results/h2-byterate-20261110/dwvw-byterate-div0.input
```

Without `H2_BYTERATE_UNGUARDED` the harness skips `sf_current_byterate()` when `frames == 0`, so the DWVW input runs clean and the GSM610 input still reports the overflow.
