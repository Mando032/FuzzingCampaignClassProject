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

### Next

- Write H1 (API-surface harness) and add it to `scripts/build.sh`.
