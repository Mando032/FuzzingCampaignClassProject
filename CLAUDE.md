# libsndfile fuzzing campaign (Software Security, Track B)

Two-person class project (Francis Njoku, Armando Mendoza Sanchez): fuzz libsndfile with libFuzzer + ASan/UBSan, measure coverage with llvm-cov, root-cause anything found.

## Read first

- `PROJECT_REVIEW_AND_PLAN.md`: current status, the task checklist with owners, the revised thesis, the harness backlog and the timeline. **Start every session from its checklist.**
- `results/BASELINE_RESULTS.md`: milestone 1 results (the reference numbers everything is compared against).
- `Project_Abstract_TrackB_libsndfile.md`: the original proposal. Its thesis (minor container formats are cold) was **disproved** by the baseline; the review doc has the revised one.

## Grading drives priorities

Most of the grade is methodology, reproducibility and root-cause reasoning; only a fifth depends on finding a working bug. An honest negative result scores well. So:
- Never overstate a result. Report numbers exactly as measured, with run duration, core count, host/platform and seeds.
- Every claim in a write-up should trace to a file under `results/` that a script produced.
- Prefer a fair, repeated comparison (same seeds, time and cores; 3–5 runs; median and spread) over a single impressive run.
- Both team members must be able to explain all code in the technical interview. Keep harnesses short and commented where the intent isn't obvious, and explain non-obvious choices to the user rather than just making them.
- The course requires disclosing AI use; the abstract has a disclosure paragraph that the final paper should keep up to date.

## Layout

| Path | What |
|---|---|
| `scripts/env.sh` | Shared settings: `PINNED_COMMIT` (libsndfile `b9103bd…`), `FUZZERS` list, clang on PATH |
| `scripts/build.sh fuzz\|cov` | Builds libsndfile + upstream harnesses into `build/fuzz` (ASan+UBSan+libFuzzer) or `build/cov` (coverage). `EXTERNAL_LIBS=1` → `build/*-extlibs` |
| `scripts/baseline.sh [run]` | Runs every harness in `FUZZERS` for `$DURATION` s, replays corpora for UB sites and coverage, writes `results/<run>/` |
| `scripts/summarize.py` | llvm-cov JSON → `files.csv` + `summary.md` |
| `results/baseline/` | Committed milestone-1 run (x86-64, 600 s). **Do not overwrite.** |
| `results/docker-smoke/` | 60 s Docker run on arm64 that reproduces the baseline |
| `results/smoke/crash-136c…` | MAT4 signed-overflow reproducer |
| `results/ossfuzz-20261012/summary.json` | OSS-Fuzz public coverage snapshot (the fair upstream reference) |
| `libsndfile/`, `build/` | Gitignored; recreated by `build.sh` or inside the Docker image |
| `toolchain/` | Gitignored since Oct 28. Local clang for no-root Ubuntu hosts: `scripts/get-toolchain.sh`, or re-unpack `toolchain/debs/*.deb` with `dpkg -x` into `toolchain/root` (a git copy loses exec bits and the `.a` runtimes). Prefer Docker. |
| `*_harness.cc` | Our harnesses (repo root). See "Writing new harnesses". |
| `PROGRESS.md` | Dated log of what each team member did |

Upstream harnesses live in `libsndfile/ossfuzz/` (`sndfile_fuzzer.cc`, `sndfile_alt_fuzzer.cc`, `sndfile_fuzz_header.h`). They only call `sf_open_virtual` read-only plus a read loop, which is why SD2, RAW codecs, `sf_command`, write paths and the Ogg/FLAC code get no upstream fuzzing.

## Building and running (Docker)

```sh
docker build -t sndfile-fuzz .

# Baseline-style run of the upstream harnesses
docker run --rm --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
  -v "$PWD/results:/work/results" -e DURATION=600 \
  sndfile-fuzz scripts/baseline.sh <new-run-name>

# Replay a reproducer (UBSan fatal)
docker run --rm -v "$PWD/results:/work/results" -e UBSAN_OPTIONS=halt_on_error=1 \
  sndfile-fuzz build/fuzz/ossfuzz/sndfile_fuzzer results/smoke/crash-136c8b2a89d357c695d5cd8da040d3e0420ee740
```

- The image copies only `scripts/` at build time. After editing scripts, rebuild the image or mount `-v "$PWD/scripts:/work/scripts"`.
- `--cap-add=SYS_PTRACE --security-opt seccomp=unconfined` is required: LeakSanitizer aborts in a container without it.
- Always pass a **new run name**; the default `baseline` overwrites committed results.
- UBSan is recoverable during campaigns on purpose (the MAT4 overflow otherwise kills every job). Use `HALT_ON_UB=1` or `UBSAN_OPTIONS=halt_on_error=1` to make it fatal.
- On Apple Silicon the image is arm64; the committed baseline is x86-64. Coverage matches, exec/s does not (~3× higher on M-series). Never compare exec/s across machines, and keep each A/B comparison on one platform.

## Writing new harnesses

Our harnesses live in the **repo root** as `*_harness.cc` (Francis's choice, instead of a `harnesses/` folder), one `LLVMFuzzerTestOneInput` per file. They reuse `libsndfile/ossfuzz/sndfile_fuzz_header.h` for virtual I/O and `FuzzedDataProvider` (`#include <fuzzer/FuzzedDataProvider.h>`) to carve control bytes out of the input, which is why they are C++.

`scripts/build.sh fuzz|cov` compiles every `*_harness.cc` against `build/<mode>/src/.libs/libsndfile.a` (plus the `dependency_libs` from `libsndfile.la`, so `EXTERNAL_LIBS=1` links FLAC/Ogg/...) into `build/<mode>/ossfuzz/<name>_fuzzer`, e.g. `h1_api_harness.cc` → `h1_api_fuzzer`. The Docker image copies only `scripts/`, so mount the harness files (e.g. `-v "$PWD/h1_api_harness.cc:/work/h1_api_harness.cc"`) and rebuild inside the container.

Existing harnesses:
- `h1_api_harness.cc` (H1, API surface, Nov 4 2026). Opens the input with `sf_open_virtual`, then calls the `sf_command` getters (log, broadcast, cart, instrument, loop, cue, embed, channel map, peaks), `sf_get_string` for every string type, the chunk iterator (chunks over 1 MB skipped), and three `sf_seek` + `sf_read_raw`/`sf_readf_float` steps, optionally `SFC_CALC_SIGNAL_MAX`. The last 3 input bytes are control bytes. 60 s smoke test on the x86-64 host, seeded with `results/baseline/corpus/sndfile_fuzzer`: ~1.03M execs, 1,983 edges, no crashes, only the known MAT4 UB. Not yet an equal-effort comparison against upstream.
  - Two harness bugs were found and fixed during that test (raw buffer smaller than `channels * 16` bytes; `memcpy` from a NULL pointer on empty input). A new H1 crash should be checked against the harness code first.

Integrating new harnesses into `scripts/baseline.sh` is still to do: it hard-codes `$ROOT/build/{fuzz,cov}/ossfuzz/$f` and the `FUZZERS` list in `env.sh`, and does not yet support `build/*-extlibs`. Generalize it (harness binary paths and build dir as variables) rather than copying it.

Harness backlog, in order (details and targets in the review doc):
1. API surface (**first version done**, `h1_api_harness.cc`): `sf_command` getters (`SFC_GET_BROADCAST_INFO`, `SFC_GET_CART_INFO`, `SFC_GET_INSTRUMENT`, …), `sf_get_string`, chunk iterator APIs, `sf_seek`, `sf_read_raw`.
2. RAW + explicit codec via `SF_INFO` (VOX, G72x, IMA-OKI, …).
3. `EXTERNAL_LIBS=1` build with Ogg/Vorbis/Opus/FLAC/MP3 seeds (libraries are already in the image).
4. SD2: write data fork + AppleDouble `._name` resource fork to a temp dir and call `sf_open()`. `sf_open_virtual` can never reach `sd2.c` (see `try_resource_fork` in `src/sndfile.c`, `psf_open_rsrc` in `src/file_io.c`).
5. Stretch: RDWR/write round trip with a growable-buffer `vfwrite`.

## Known findings

- **MAT4 signed integer overflow** (`src/mat4.c:318/320/322/323/325`): `mat4_read_header` checks `rows == 0` and `rows > SF_MAX_CHANNELS` but never `rows < 0` / `cols < 0`, so negative header values reach 64-bit multiplications. `validate_sfinfo()` then rejects the file (`channels < 1`), so it appears to be arithmetic UB only. Remaining triage: debugger confirmation, check for an existing upstream/OSS-Fuzz report, patch, `make check`.

## Gotchas

- Scripts lost their executable bit on the Mac copy; the Dockerfile `chmod +x`'s them. Don't run them as `bash scripts/x.sh`: that drops the `-eu` from the shebang.
- `build.sh` always `rm -rf`s its build dir (make won't rebuild on CFLAGS changes).
- `results/ossfuzz-20261012/summary.json` was pretty-printed locally; content is unchanged.
- Don't delete tracked files (stray root files) without both team members agreeing; it's listed under repo hygiene in the review doc.
- Don't commit unless asked.
