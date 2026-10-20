# Baseline Review and Plan to Get Back on Track

Track B: libsndfile fuzzing campaign. Review of milestone 1 (`results/BASELINE_RESULTS.md`) against the project abstract, and what we do next.

Date: October 19, 2026

## TL;DR

- The baseline is solid work and covers the most heavily graded parts of the rubric: methodology, reproducibility and honest reasoning. Every key claim in it checked out against the libsndfile source.
- **The baseline disproved our main thesis.** CAF, W64, MAT4/MAT5, PVF, HTK and AVR are 58–71% covered by OSS-Fuzz, so they are not "cold." We should pivot now rather than at the week 9 checkpoint. The code upstream really misses sits behind **harness limitations**, not magic bytes:
  - SD2
  - the Ogg/Vorbis/Opus and FLAC code
  - RAW files and their codecs
  - `sf_command`
  - write paths
- The MAT4 UBSan finding is root-caused below: negative row and column counts are accepted from the header. It is low severity and arithmetic only, but it is a complete, reproducible defect write-up waiting to happen.
- We are behind on the weeks 3–4 milestone (our own harness and corpus v1). A Dockerfile is now in the repo so either of us can rebuild and rerun everything on any machine. The next step is our first new harness.

## Action checklist

| # | Task | Owner | Status |
|---|---|---|---|
| 1 | Dockerfile for a reproducible build and run (see [Reproducing with Docker](#reproducing-with-docker)) | Armando | Done, Francis to review |
| 2 | Revise the abstract's thesis and target list (see [Revised thesis](#revised-thesis-and-targets)) | Armando + Francis | To do |
| 3 | Finish MAT4 triage: debugger confirmation, check for an existing upstream report, patch, `make check` | Armando | To do |
| 4 | Harness 1: `sf_command` / chunk / string APIs | Francis | To do |
| 5 | Harness 2: RAW + explicit codec | Francis | To do |
| 6 | `EXTERNAL_LIBS=1` build, plus Ogg/FLAC/Opus seed files | Francis | To do |
| 7 | Seed corpus v1 (sox/ffmpeg/libsndfile-generated files, `-merge=1` minimized) and dictionaries | Francis | To do |
| 8 | Equal-effort A/B measurement script (N repeated runs, per-file coverage, median and spread) | Armando | To do |
| 9 | Coverage-over-time collection for the plots | Armando | To do |
| 10 | Harness 3: SD2 via `sf_open` plus an AppleDouble resource fork | Francis | To do |
| 11 | Repo cleanup (see [Repo hygiene](#repo-hygiene)) | Both, agree first | To do |

---

## 1. How the current harness works

There is no harness of our own yet. The baseline runs libsndfile's two OSS-Fuzz harnesses from `libsndfile/ossfuzz/`, unmodified.

**Shared plumbing (`sndfile_fuzz_header.h`)**
- The fuzz input stays in memory as `VIO_DATA {offset, length, data}`.
- Five callbacks (`vfread`, `vfseek`, `vftell`, `vfget_filelen`, `vfwrite`) present it as a file. Reads and seeks stop at the buffer edges, and `vfwrite` always returns 0, so the file is read-only.
- `sf_init_file()` calls `sf_open_virtual(vio, SFM_READ, ...)` with a zeroed `SF_INFO`, so libsndfile must guess the format from the bytes alone. The result is rejected when `channels == 0` or `channels > 1M`.

**The two harnesses**

| Harness | What it does after opening |
|---|---|
| `sndfile_fuzzer.cc` | Calls `sf_readf_float(…, 1)` in a loop, one frame at a time, until the file ends |
| `sndfile_alt_fuzzer.cc` | Uses byte 0 to choose `sf_read_short`, `sf_read_int` or `sf_read_double`, and reads in large chunks |

**Pipeline**

| Step | What happens |
|---|---|
| `scripts/build.sh fuzz` | ASan + UBSan (recoverable) + libFuzzer build |
| `scripts/build.sh cov` | Source-based coverage build (`-fprofile-instr-generate -fcoverage-mapping`) |
| Both builds | Use `--disable-external-libs --disable-mpeg`, the same as OSS-Fuzz |
| `scripts/baseline.sh` | Runs each harness for `DURATION` seconds on one core each (empty corpus, no dictionary, fork mode) |
| Replay through the fuzz build | Collects UBSan sites into `ub_sites.txt` |
| Replay through the coverage build | Produces `llvm-cov` text, JSON and HTML reports |
| `summarize.py` | Builds `files.csv` and `summary.md` |

In short: libFuzzer generates bytes, the harness feeds them to `sf_open_virtual` and a read loop, and ASan/UBSan flag misbehavior.

## 2. What the baseline shows

| Item | Result |
|---|---|
| Our 10-minute run | 10.8M and 12.4M executions at 18–20k exec/s. 5.8% line coverage of `src/`. No ASan crashes, OOMs or timeouts. |
| Formats reached from an empty corpus | Only MAT4, HTK and MPC2K (header heuristics, no magic string) |
| OSS-Fuzz public coverage, 2026-10-12 | 45.7% lines. This is the fair reference. |
| Our abstract's minor formats | CAF 58.8%, HTK 58.0%, W64 60.1%, MAT4 62.7%, AVR 63.4%, PVF 69.0%, MAT5 71.2%. **Not cold.** |
| Really cold upstream | • `sd2.c` 0%<br>• `raw.c` 0%<br>• `vox_adpcm.c`, `ima_oki_adpcm.c`, `G72x/g723_16.c` 0%<br>• `command.c`, `dither.c` 0%<br>• `broadcast.c` 2.1%, `cart.c` 9.5%<br>• all encoders and `*_write_header`<br>• all Ogg/Vorbis/Opus/FLAC/MPEG glue code (not compiled in) |
| UBSan | Signed integer overflow at `src/mat4.c:318/320/322/323` |

## 3. Independent check of the key claims

### SD2 is unreachable by both upstream harnesses (confirmed)

- The only way libsndfile detects SD2 is `try_resource_fork()` (`src/sndfile.c:2688`).
- That calls `psf_open_rsrc()` (`src/file_io.c:156`), which looks for a resource fork **on disk** at `<path>/..namedfork/rsrc`, `<dir>._<name>` or `<dir>.AppleDouble/<name>`.
- A virtual file has no path, so `sd2.c` can never be entered through `sf_open_virtual`.
- The AppleDouble `._<name>` variant is a plain file. A Linux harness that writes `x.sd2` and `._x.sd2` into a tmpfs directory and then calls `sf_open()` should reach `sd2_parse_rsrc_fork()`.

### MAT4 overflow: root cause

In `mat4_read_header()` (`src/mat4.c:205`), the second matrix header is read as `psf_binheader_readf (psf, "444", &rows, &cols, &imag)`. `rows` and `cols` are signed `int`s taken directly from the file. The only checks are:

```c
if (rows == 0)                    -> SFE_CHANNEL_COUNT_ZERO
else if (rows > SF_MAX_CHANNELS)  -> SFE_CHANNEL_COUNT
```

**Negative `rows` and any value of `cols` get through.** The parser then sets `psf->sf.channels = rows` and `psf->sf.frames = cols`. Lines 318–323 compute `channels * frames * bytewidth` and `rows * cols * bytewidth` in 64-bit signed arithmetic.

Decoding the reproducer (`results/smoke/crash-136c8b2a89d357c695d5cd8da040d3e0420ee740`, 57 bytes):

| Offset | Bytes | Field | Value |
|---|---|---|---|
| 0x00 | `00000000` | marker | `MAT4_LE_DOUBLE` |
| 0x04–0x1C | | first matrix (sample rate) | rows = cols = 1, valid |
| 0x1D | `00000000` | data marker | `MAT4_LE_DOUBLE`, so `bytewidth = 8` |
| 0x21 | `00 06 b5 b5` | rows | **−1,246,427,648** |
| 0x25 | `b5 b5 b5 b5` | cols | **−1,246,382,667** |

`rows * cols` = 1,553,525,816,136,777,216, which is exactly the left operand in the UBSan message (`1553525816136777216 * 8 cannot be represented in type 'sf_count_t'`).

The Docker smoke run (below) hit a **fifth site** with the same root cause, `mat4.c:325:54`. There, `psf->datalength = psf->filelength - psf->dataoffset - psf->dataend` overflows (`91 - -9223372036854775731`), because `dataend` was already set to a wrapped, hugely negative value on line 323.

**Consequence (to confirm in a debugger):** after the header parse, `validate_sfinfo()` (`src/sndfile.c:2925`, called at line 3316) rejects `channels < 1`, so the file is refused before any data is read.

**Current classification:** CWE-190 / CWE-1284, a missing lower-bound validation of header fields. The result is undefined behavior in arithmetic only, with no memory-safety impact found. Low severity.

**Still to do:**
- Step through it in gdb/lldb.
- Check libsndfile GitHub issues and OSS-Fuzz for an existing report. A UBSan site reached in 15 seconds may well already be known.
- Patch with `if (rows < 0 || cols < 0) return SFE_MAT4_...`, and confirm the reproducer is silent and `make check` passes.

### Other notes

- The uncommitted diff to `results/ossfuzz-20261012/summary.json` only pretty-prints the minified JSON. The content is the same.
- The OSS-Fuzz and local line totals differ slightly (25,963 vs 25,814). That is already listed as a limitation; replaying the OSS-Fuzz corpus on our pinned commit would resolve it (see section 5).

## 4. Where we stand against the abstract and rubric

The rubric: most of the grade is methodology, reproducibility and root-cause reasoning; one fifth depends on whether the attack worked; an honest negative result scores well.

**Going well**

| Rubric area | Evidence |
|---|---|
| Methodology | Mirrors OSS-Fuzz's configuration, uses a pinned commit, deliberately makes UBSan recoverable, and separates "our smoke run" from "fair upstream reference" |
| Reproducibility | Scripted end to end, with raw outputs committed. Docker now removes the host dependency. |
| Reasoning | We measured instead of assuming, and the write-up reports that the measurement contradicted us |

**At risk**

1. **Thesis versus data.** The abstract says the minor parsers "remain thin even after years of continuous fuzzing." OSS-Fuzz numbers contradict that for 7 of the 8 named formats. Coverage gains there will be small and hard to separate from noise.
2. **The planned "primary harness" is upstream's harness.** Abstract step 2 describes an `sf_open_virtual` read harness, which is exactly what `ossfuzz/` already contains. Our harnesses have to do something upstream's don't.
3. **The comparison baseline is undefined.** Beating a 10-minute run from an empty corpus proves nothing. We need equal-effort comparisons (section 5).
4. **Schedule.** If week 1 was the week of September 14, we are starting week 6 and the weeks 3–4 deliverable is missing.
5. **Abstract wording.** "All four members" should say both members (we are two). The contingency section should cite the baseline evidence.

## 5. Plan

### Revised thesis and targets

> Baseline measurement shows that libsndfile's minor container parsers are already well covered by OSS-Fuzz. The remaining unfuzzed surface sits behind **limitations of the upstream harnesses**: in-memory read-only I/O, no explicit format selection, no `sf_command` calls, and no external codec libraries. We build harnesses that remove those limitations and measure what they reach.

| Target | Upstream coverage | Why upstream misses it | Our harness |
|---|---|---|---|
| `broadcast.c`, `cart.c`, `chunk.c`, `command.c` | 2.1%, 9.5%, 54.3%, 0% | Harness never calls `sf_command` or the chunk APIs | H1 |
| `raw.c`, `vox_adpcm.c`, `ima_oki_adpcm.c`, `g723_16.c` | 0% | Need `SF_FORMAT_RAW` plus an explicit codec in `SF_INFO` | H2 |
| `ogg*.c`, `flac.c`, `mpeg*.c` | Not built | OSS-Fuzz image lacks the libraries | `EXTERNAL_LIBS=1` build + all harnesses |
| `sd2.c` | 0% | Needs a path on disk and a resource fork | H3 |
| Write and RDWR paths, encoders | 0% | Harness opens read-only and `vfwrite` returns 0 | H4 (stretch) |

The success metric from the abstract still applies: a measurable increase in at least three of these, plus one root-caused defect or a defensible negative result. Several targets start at 0%, so it is now realistic.

### Harness backlog (in order)

1. **H1: API surface.**
   - Open via `sf_open_virtual`, then let `FuzzedDataProvider` pick a sequence of:
     - `sf_command` with `SFC_GET_BROADCAST_INFO`, `SFC_GET_CART_INFO`, `SFC_GET_INSTRUMENT`, `SFC_GET_LOOP_INFO`, `SFC_GET_CUE`, `SFC_GET_CHANNEL_MAP_INFO` and `SFC_GET_LOG_INFO`
     - `sf_get_string` for each `SF_STR_*`
     - `sf_get_chunk_iterator`, `sf_next_chunk_iterator`, `sf_get_chunk_size` and `sf_get_chunk_data`
     - `sf_seek` and `sf_read_raw`
   - Cheapest to build, and it reaches four cold files.
2. **H2: RAW + codec.**
   - Consume a few bytes to choose `SF_FORMAT_RAW | codec` (VOX_ADPCM, G723_16/24/40, G721_32, ULAW, ALAW, GSM610, NMS_ADPCM_*, DWVW_*, PCM_*), channels from 1 to 8, and a sample rate.
   - Pass those in `SF_INFO` and read the rest.
3. **`EXTERNAL_LIBS=1`.**
   - The Docker image already has the libraries installed.
   - `scripts/baseline.sh` currently hard-codes `build/fuzz` and `build/cov`, so it needs a variable to point at `build/*-extlibs`.
   - Seed with small Ogg/Vorbis, Opus, FLAC and MP3 files.
4. **H3: SD2.**
   - Split the input into a data fork and a resource fork, write them to `/dev/shm/<pid>/x.sd2` and `._x.sd2`, then call `sf_open()`.
   - Generate seeds with libsndfile itself (`SF_FORMAT_SD2` write support).
5. **H4: write/RDWR round trip (stretch).**
   - Replace `vfwrite` with a growable buffer, open `SFM_RDWR`, and exercise `sf_command` setters and `*_write_header`.

### Measurement rigor (most of the grade)

- **Equal-effort A/B.** For each new harness, compare against the upstream harnesses with the same seed corpus, time budget and core count. Repeat each configuration 3–5 times and report the median and min–max. Cite Klees et al., "Evaluating Fuzz Testing" (CCS 2018) for the methodology.
- **Realistic seeds.** Try OSS-Fuzz's public corpus backup for libsndfile. If it is not available, generate files in every format with sox/ffmpeg/libsndfile and minimize with libFuzzer `-merge=1`. Replaying that corpus on our pinned commit also gives us our own "upstream-equivalent" number.
- **Coverage over time.** Snapshot the corpus every N minutes during campaigns and replay the snapshots through the coverage build. That gives us the abstract's coverage-over-time plots.
- **One platform per comparison.** Docker on Apple Silicon is arm64 Linux, while the baseline ran on x86-64. Coverage should match closely, but exec/s will not. Never mix platforms within one comparison.

### Revised timeline

Assumes week 1 was the week of September 14; shift if not. Changes from the abstract are in bold.

| Week | Milestone |
|---|---|
| 6 (now) | Docker env, abstract revision, MAT4 triage write-up, seed corpus v1, **H1** |
| 7 | **H2**, `EXTERNAL_LIBS=1` build and seeds, dictionaries, A/B measurement script |
| 8 | **H3 (SD2)**. First equal-effort A/B runs (1 h × 3–5 repetitions per harness). Coverage-over-time tooling. |
| 9 | **Checkpoint: per-target coverage deltas in hand.** Start the multi-day campaign. |
| 9–10 | Sustained campaign (**compressed from weeks 7–9**) |
| 11 | Crash triage and deduplication |
| 12–13 | Patches, regression verification, upstream disclosure |
| 14–15 | Paper and presentation |

## Repo hygiene

To discuss and agree before anyone deletes tracked files:

- **`toolchain/` (~178 MB of clang binaries and `.deb` files) is committed.** The libFuzzer `.a` it needs is gitignored, so the committed toolchain cannot build fuzzers by itself. With Docker in place, propose removing `toolchain/` from git and keeping `scripts/get-toolchain.sh` as the fallback for anyone without Docker.
- Stray files: the root `sndfile.c` (one `#include` line), the root `default.profraw` and the committed `.DS_Store` files. Propose deleting them and adding `.DS_Store` and `*.profraw` to `.gitignore`.
- The scripts lost their executable bit somewhere (they are `-rw-rw-r--` on the Mac copy). Running them as `bash scripts/x.sh` silently drops the `-eu` from the shebang. Propose `git update-index --chmod=+x scripts/*.sh`.
- Record how `results/smoke/crash-136c…` was produced (command, duration).

## Reproducing with Docker

**Verified on October 19, 2026** on an Apple Silicon Mac (Docker 29.4, image is `aarch64`, Ubuntu clang 21.1.8, libsndfile `b9103bd`). The image builds in about 2 minutes. A 60-second run (`results/docker-smoke/`) reproduces the baseline:

| | Baseline (x86-64 host, 600 s) | Docker (arm64, 60 s) |
|---|---|---|
| `src/` line coverage | 5.8% (1,494 / 25,814) | 5.8% (1,493 / 25,814) |
| Edges (`sndfile_fuzzer` / `alt`) | 1,466 / 1,750 | 1,458 / 1,741 |
| Formats reached | MAT4, HTK, MPC2K | MAT4 58.9%, HTK 58.0%, MPC2K 52.6% |
| Exec/s per fuzzer | 18–20k | 59–65k |
| UBSan sites | `mat4.c` 318/320/322/323 | the same four, plus 325 |
| ASan crashes, OOMs, timeouts | 0 | 0 |

Two things to take from this:

- **The upstream harnesses plateau within about a minute from an empty corpus.** Ten times the time bought only about 8 extra edges. That supports the argument that seeds and harness design matter far more than fuzzing time.
- Exec/s is about 3× higher on the M-series Mac than on the 2-core host, so **never compare exec/s across machines**.

```sh
docker build -t sndfile-fuzz .            # clones the pinned commit, builds fuzz + cov

docker run --rm --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
  -v "$PWD/results:/work/results" -e DURATION=600 \
  sndfile-fuzz scripts/baseline.sh my-run  # writes results/my-run/
```

- Use a new run name each time. The default name (`baseline`) overwrites the committed baseline.
- `SYS_PTRACE` and `seccomp=unconfined` are needed for LeakSanitizer inside the container.
- `--build-arg EXTERNAL_LIBS=1` builds the Ogg/FLAC/MPEG variant into `build/*-extlibs`.
- Replay the MAT4 reproducer:

  ```sh
  docker run --rm -v "$PWD/results:/work/results" -e UBSAN_OPTIONS=halt_on_error=1 \
    sndfile-fuzz build/fuzz/ossfuzz/sndfile_fuzzer \
    results/smoke/crash-136c8b2a89d357c695d5cd8da040d3e0420ee740
  ```
