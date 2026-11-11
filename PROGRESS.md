# Progress Log

## November 4, 2026 (Francis)

- Deleted the empty `sndfile.c`. Nothing used it; the harnesses live in `libsndfile/ossfuzz/`.
- Rebuilt both configurations on this machine at the pinned commit `b9103bd`:
  - `scripts/build.sh fuzz` → `build/fuzz/ossfuzz/` (ASan + UBSan + libFuzzer)
  - `scripts/build.sh cov` → `build/cov/ossfuzz/` (coverage)
- Checked: `sndfile_fuzzer -runs=1000` runs cleanly.

### Problems fixed

- **Clone failed with an SSL error.** The VM clock was behind, so GitHub's certificate looked not yet valid. Fixed with `sudo hwclock --hctosys && sudo timedatectl set-ntp true`.
- **The toolchain was broken after cloning.** Git stored `toolchain/root/` without execute permissions and without the `.a` runtime libraries (libFuzzer, ASan). `toolchain/` is no longer tracked in git. Recreate it with `scripts/get-toolchain.sh`, or, if `toolchain/debs/` is already present:
  ```
  cd toolchain/debs && for d in *.deb; do dpkg -x "$d" ../root; done
  ```

### H1 harness (first version)

- Wrote `h1_api_harness.cc` (repo root), our first harness. Besides opening the file, it calls the parts of the API the upstream harnesses never use:
  - metadata getters: `sf_command` for broadcast, cart, instrument, loop, cue, channel map, peaks and the parse log, and `sf_get_string`
  - the chunk iterator (`sf_get_chunk_iterator`, `sf_get_chunk_data`)
  - `sf_seek` and `sf_read_raw`
- `scripts/build.sh fuzz|cov` now also compiles every `*_harness.cc` in the repo root, so H1 builds to `build/fuzz/ossfuzz/h1_api_fuzzer` and `build/cov/ossfuzz/h1_api_fuzzer`.
- 60 s smoke test (one core, seeded with the baseline corpus): about 1.03 million runs, 1,983 edges, no crashes. The only UBSan reports were the known MAT4 overflow. This is not yet a fair comparison against upstream.
- Two crashes during testing were bugs in the harness, not in libsndfile, and are fixed: a read buffer that was too small for files with many channels, and empty inputs.

## November 10, 2026 (Armando)

All runs in the Docker image on Apple Silicon (arm64, OrbStack), libsndfile `b9103bd`.

### Measurement tooling

- `scripts/baseline.sh` now takes `HARNESSES`, `SEEDS` and `EXTERNAL_LIBS=1`, and writes `meta.txt` (date, host, cores, duration, seeds, commit, clang). Unchanged when none are set: a 60 s default run (`results/repro-check-20261110/`) gave 5.9% lines (1,532 / 25,814) and the same four `mat4.c` UB sites. The committed `docker-smoke` gave 1,493 lines; the difference is run-to-run randomness, which is why we repeat runs.
- `scripts/ab.sh` + `scripts/ab_summary.py`: equal-effort A/B (each harness alone on one core, same seeds and time, N repetitions, median and min–max per file, plus edges over time).
- The Dockerfile now copies `*_harness.cc`, so the image builds our harnesses.
- Smoke A/B (`results/ab-smoke-20261110/`, 2 × 60 s, seeds = baseline `sndfile_fuzzer` corpus, 152 files), lines hit, median: H1 1,489.5, `sndfile_alt_fuzzer` 1,373, `sndfile_fuzzer` 1,128.5. H1 reaches `command.c` 33 lines, but `broadcast.c` and `cart.c` only 4 each: the seeds have no WAV files with `bext`/`cart` chunks. Smoke test only, not the real comparison.

### H2 harness (first version)

- Wrote `h2_raw_harness.cc`: opens the input as RAW with a codec, endianness, channel count and sample rate picked from control bytes, so libsndfile does not have to detect the format. Reads with all four sample types and calls `sf_current_byterate`.
- Smoke A/B against `sndfile_fuzzer` (`results/ab-h2-smoke-20261110/`, 2 × 60 s, same seeds): H2 2,926 lines vs 1,143.5. `raw.c` 56/58, `vox_adpcm.c` 128/240, `ima_oki_adpcm.c` 36/62, `nms_adpcm.c` 315/611, `dwvw.c` 203/381, `gsm610.c` 161/367; all 0 for `sndfile_fuzzer`.
- Found while writing it: G72x can't be used with RAW, `g723_16.c` is unreachable from the public API at our pin, and IMA-OKI is only reached via VOX. Our earlier plan listed them as H2 targets.
- Two UBSan findings, both in `sf_current_byterate` (`results/h2-byterate-20261110/README.md`):
  - DWVW divide-by-zero, `dwvw.c:178`: known, fixed upstream in `e82eb494` after our pin. The harness skips the call when `frames == 0` so it doesn't end every fork job; `H2_BYTERATE_UNGUARDED=1` reproduces it.
  - GSM610 signed overflow, `sndfile.c:1665`: still present upstream at `396a715d`. So far only shown with the sample rate coming from the caller.

### Next

- Decide the re-pin with Francis before the real A/B (3 × 600 s or longer, all four harnesses).
- GSM610 overflow: build a WAV GSM610 reproducer with a high sample rate in the header, search GitHub issues and OSS-Fuzz, check x86-64.
- MAT4: apply `c3faa5bb`, confirm the reproducer is silent, `make check`.
- Seeds: WAV files with `bext`/`cart` chunks for H1 (Francis's corpus v1).

### Next (as of Nov 4)

- Add H1 to `scripts/baseline.sh` (Armando's "generalize baseline.sh" task) and run the equal-effort comparison against the upstream harnesses.
- H2: RAW + explicit codec harness.
- Ask Armando to push `PROJECT_REVIEW_AND_PLAN.md`; `CLAUDE.md` refers to it but it isn't in the repo.
