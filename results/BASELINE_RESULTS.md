# Baseline Coverage Results

Track B: libsndfile fuzzing campaign. Milestone 1 (weeks 1-2): sanitizer build, upstream harness reproduction, coverage baseline.

Run date: October 12, 2026

## Summary

- The upstream harnesses build and run under ASan + UBSan + libFuzzer, and coverage is collected with `llvm-cov`. The whole pipeline is scripted and reruns with two commands.
- Our own 10-minute run from an empty corpus reached 5.8% of `src/` lines. It is a pipeline check, not a fair picture of upstream coverage.
- The fair reference is OSS-Fuzz's public coverage report, which sits at 45.7% of lines. Against that reference, **most of the minor containers named in the abstract are not cold**: CAF, W64, MAT4, MAT5, PVF, HTK and AVR are at 58-71%, about the same as WAV and AIFF.
- The code that is cold upstream is: Sound Designer II (0%), everything behind the external libraries (Ogg/Vorbis/Opus, FLAC, MPEG are not compiled into the OSS-Fuzz build), a few codecs, and all write-side code.
- UBSan reported signed integer overflow at four sites in `src/mat4.c` within seconds. Not yet triaged.

## Setup

| Item | Value |
|---|---|
| Target | libsndfile, commit `b9103bd48b6c8fb517ae737fe3baee0c718b804c` (master, September 1, 2026) |
| Compiler | Ubuntu clang 21.1.8 |
| Host | Ubuntu 26.04, 2 cores, 3 GB RAM |
| Fuzz build | `-O1 -g -fno-omit-frame-pointer -fsanitize=address,undefined,fuzzer-no-link` |
| Coverage build | `-O1 -g -fsanitize=fuzzer-no-link -fprofile-instr-generate -fcoverage-mapping` |
| Configure | `--disable-shared --enable-ossfuzzers --disable-external-libs --disable-mpeg` |
| Harnesses | `ossfuzz/sndfile_fuzzer.cc`, `ossfuzz/sndfile_alt_fuzzer.cc` (unmodified) |
| Fuzzer options | `-fork=1 -timeout=25 -rss_limit_mb=1024 -close_fd_mask=3`, default `max_len` (4096) |
| Corpus / dictionary | Empty / none, as in the OSS-Fuzz project config |
| Duration | 600 s per harness, run in parallel, one per core |

The configure line mirrors `ossfuzz/ossfuzz.sh`. The OSS-Fuzz builder image does not install the FLAC, Ogg, Vorbis, Opus or MPEG libraries, so upstream fuzzers are built without them; we disable them explicitly because this machine has them installed.

UBSan was left recoverable during the run. With UBSan fatal, the MAT4 overflow below killed the fuzzer on nearly every job and stopped it exploring past that point. After the run the corpus is replayed once to list every UB site it triggers.

## Campaign statistics (our run)

| Harness | Executions | Exec/s | Edges | Features | Corpus files | Crashes | OOMs | Timeouts |
|---|---|---|---|---|---|---|---|---|
| `sndfile_fuzzer` | 10,819,101 | 18,001 | 1,466 | 3,021 | 152 | 0 | 0 | 0 |
| `sndfile_alt_fuzzer` | 12,362,065 | 20,569 | 1,750 | 2,839 | 198 | 0 | 0 | 0 |

Combined coverage of `src/` after replaying both corpora: 5.8% lines (1,494 / 25,814), 5.3% branches, 9.8% functions.

## Reference: OSS-Fuzz public coverage

Source: `https://storage.googleapis.com/oss-fuzz-coverage/libsndfile/reports/20261012/linux/index.html` (summary saved in `results/ossfuzz-20261012/summary.json`).

Overall: 45.7% lines (11,876 / 25,963), 47.2% functions, 39.1% regions.

This reflects the corpus OSS-Fuzz has accumulated over years of continuous fuzzing with the same two harnesses. Its total line count differs slightly from ours (25,963 vs 25,814), so the two reports may not be from the identical revision or file set; per-file line counts for the parsers below match exactly.

## Per-parser line coverage

### Target minor formats (from the abstract)

| File | Format | Lines | Our run | OSS-Fuzz |
|---|---|---|---|---|
| `sd2.c` | Sound Designer II | 348 | 0% | **0%** |
| `htk.c` | HTK | 81 | 58.0% | 58.0% |
| `caf.c` | CAF | 680 | 0% | 58.8% |
| `w64.c` | W64 | 343 | 0% | 60.1% |
| `mat4.c` | MAT4 | 209 | 59.3% | 62.7% |
| `avr.c` | AVR | 101 | 0% | 63.4% |
| `pvf.c` | PVF | 87 | 0% | 69.0% |
| `mat5.c` | MAT5 | 299 | 0% | 71.2% |
| `ogg.c`, `ogg_vorbis.c`, `ogg_opus.c`, ... | Ogg family | stub | not built | not built |

### Mainstream formats

| File | Lines | Our run | OSS-Fuzz |
|---|---|---|---|
| `rf64.c` | 516 | 0% | 52.9% |
| `wav.c` | 977 | 0% | 57.3% |
| `aiff.c` | 1,167 | 0% | 65.3% |
| `au.c` | 252 | 0% | 72.6% |
| `wavlike.c` | 856 | 0% | 80.5% |
| `flac.c` | stub | not built | not built |

### Other containers

| File | Lines | Our run | OSS-Fuzz |
|---|---|---|---|
| `raw.c` | 58 | 0% | **0%** |
| `sds.c` | 646 | 0% | 48.6% |
| `xi.c` | 746 | 0% | 51.3% |
| `mpc2k.c` | 78 | 52.6% | 52.6% |
| `paf.c` | 486 | 0% | 55.8% |
| `wve.c` | 98 | 0% | 57.1% |
| `ircam.c` | 160 | 0% | 65.6% |
| `nist.c` | 219 | 0% | 66.7% |
| `voc.c` | 304 | 0% | 74.0% |
| `svx.c` | 217 | 0% | 74.2% |

### Codecs

| File | Lines | Our run | OSS-Fuzz |
|---|---|---|---|
| `vox_adpcm.c` | 240 | 0% | **0%** |
| `ima_oki_adpcm.c` | 62 | 0% | **0%** |
| `G72x/g723_16.c` | 42 | 0% | **0%** |
| `ima_adpcm.c` | 635 | 0% | 44.3% |
| `ms_adpcm.c` | 504 | 0% | 44.4% |
| `alaw.c` | 202 | 0% | 48.0% |
| `ulaw.c` | 203 | 0% | 48.3% |
| `dwvw.c` | 381 | 0% | 49.1% |
| `gsm610.c` | 367 | 0% | 50.4% |
| `nms_adpcm.c` | 611 | 0% | 51.6% |
| `alac.c` | 598 | 0% | 52.2% |
| `g72x.c` | 319 | 0% | 54.2% |

Decoder-side library files (`ALAC/alac_decoder.c`, `ALAC/dp_dec.c`, `ALAC/matrix_dec.c`, `GSM610/gsm_decode.c`) are at 100% in OSS-Fuzz. Encoder-side files (`ALAC/alac_encoder.c`, `ALAC/ag_enc.c`, `ALAC/dp_enc.c`, `ALAC/matrix_enc.c`, `GSM610/gsm_encode.c`, `GSM610/lpc.c`, `GSM610/code.c`) are at 0%.

### Core

| File | Lines | Our run | OSS-Fuzz |
|---|---|---|---|
| `command.c` | 125 | 0% | **0%** |
| `dither.c` | 234 | 0% | **0%** |
| `broadcast.c` | 96 | 0% | 2.1% |
| `cart.c` | 42 | 0% | 9.5% |
| `file_io.c` | 334 | 22.2% | 23.1% |
| `sndfile.c` | 2,166 | 17.4% | 23.8% |
| `double64.c` | 648 | 21.0% | 26.5% |
| `float32.c` | 637 | 17.7% | 27.8% |
| `pcm.c` | 1,885 | 13.6% | 38.2% |
| `common.c` | 1,203 | 24.4% | 45.6% |
| `chunk.c` | 164 | 0% | 54.3% |

Full per-file data for our run, including branch and function coverage, is in `results/baseline/files.csv`.

## What the numbers say

**Our short run only found the formats with no magic number.** From an empty corpus, ten minutes was enough to reach MAT4, HTK and MPC2K, which libsndfile detects by header heuristics, and nothing else. It never produced a `RIFF` or `FORM` header, so WAV and AIFF stayed at 0%. This confirms the mechanism the abstract describes (magic bytes gate the parsers), but only for a cold start.

**With an accumulated corpus the gate is already open.** OSS-Fuzz reaches CAF, W64, MAT5, PVF and AVR at 59-71% line coverage. The claim that coverage in these parsers "remains thin even after years of continuous fuzzing" is not supported for these formats.

**Where upstream fuzzing does not reach:**

1. **Sound Designer II (`sd2.c`, 348 lines, 0%).** SD2 is detected by opening a resource-fork file on disk next to the data file. `sf_open_virtual` cannot do that, so neither upstream harness can ever enter this parser. Reaching it needs a harness that writes files and calls `sf_open`.
2. **External-library paths.** `ogg.c`, `ogg_vorbis.c`, `ogg_opus.c`, `flac.c` and the MPEG files are compiled as stubs in the OSS-Fuzz build. libsndfile's own glue code around libogg, libvorbis, libopus, libFLAC and mpg123 gets no upstream fuzzing. Building with `EXTERNAL_LIBS=1` enables them here; this has not been built or run yet.
3. **Write-side and command code.** Every encoder, every `*_write_header` function, `command.c` (`sf_command`) and `dither.c` are at 0%, because both harnesses only open for reading and only call `sf_read*`. `broadcast.c` and `cart.c` (2-10%) are in the same position.
4. **A few codecs.** `vox_adpcm.c`, `ima_oki_adpcm.c` and `G72x/g723_16.c` are at 0%. VOX has no header, so it is only reachable through RAW with an explicit format, which the harness never requests; `raw.c` is at 0% for the same reason.
5. **The uncovered 30-40% inside each reached parser.** Some of that is write-side code; the rest would need per-file inspection of the HTML report.

## Finding: signed integer overflow in `mat4.c`

UBSan reports `signed integer overflow` at four locations, first hit about 15 seconds into a run:

| Location | Hits in corpus replay |
|---|---|
| `src/mat4.c:318:78` | 2 |
| `src/mat4.c:320:74` | 2 |
| `src/mat4.c:322:83` | 2 |
| `src/mat4.c:323:74` | 2 |

Example report:

```
src/mat4.c:318:78: runtime error: signed integer overflow: 1553525816136777216 * 8
cannot be represented in type 'sf_count_t' (aka 'long')
```

The code multiplies `channels * frames * bytewidth` (and `rows * cols * bytewidth`) as 64-bit signed values taken from the file header, without a range check, to decide whether the file is truncated and to compute `dataend`.

Status: reproducible, not triaged. Open questions are whether the wrapped value leads to any out-of-bounds access downstream or is only undefined behaviour in the arithmetic, and whether it is already reported upstream. A reproducer is at `results/smoke/crash-136c8b2a89d357c695d5cd8da040d3e0420ee740`.

No ASan findings, OOMs or timeouts occurred in the 10-minute run.

## Limitations

- Ten minutes on two cores from an empty corpus is a smoke-level run. Its coverage numbers should not be quoted as "upstream coverage"; use the OSS-Fuzz column for that.
- The OSS-Fuzz report is a snapshot from one day and its exact source revision was not checked against our pinned commit.
- Line coverage percentages include write-side code that a read-only harness cannot reach, so 60% in a parser can mean most of its read path is covered.
- The `EXTERNAL_LIBS=1` build variant exists in the script but has not been built or measured.

## Reproducing

```
scripts/get-toolchain.sh        # only if clang is not installed system-wide
scripts/build.sh fuzz           # ASan + UBSan + libFuzzer  -> build/fuzz
scripts/build.sh cov            # source-based coverage     -> build/cov
DURATION=600 scripts/baseline.sh baseline
```

Outputs in `results/baseline/`:

| File | Contents |
|---|---|
| `summary.md` | Per-file coverage tables for this run |
| `files.csv` | Per-file line, branch and function counts |
| `coverage.txt`, `coverage.json` | Raw `llvm-cov report` and `llvm-cov export` output |
| `html/index.html` | Line-by-line coverage |
| `ub_sites.txt` | UBSan sites triggered by the corpus |
| `corpus/`, `crashes/` | Final corpora and any crashing inputs |
| `*_fuzzer.log` | libFuzzer logs |

Set `HALT_ON_UB=1` to make UBSan findings count as crashes.
