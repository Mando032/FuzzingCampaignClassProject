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

### Next

- Add H1 to `scripts/baseline.sh` (Armando's "generalize baseline.sh" task) and run the equal-effort comparison against the upstream harnesses.
- H2: RAW + explicit codec harness.
- Ask Armando to push `PROJECT_REVIEW_AND_PLAN.md`; `CLAUDE.md` refers to it but it isn't in the repo.
