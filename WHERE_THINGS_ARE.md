# Where Things Are

## On disk now

| What | Where |
|---|---|
| Files the fuzzer made (kept because they reached new code) | `results/baseline/corpus/sndfile_fuzzer/` (152 files) and `results/baseline/corpus/sndfile_alt_fuzzer/` (198 files) |
| A crashing file the fuzzer made (the `mat4.c` bug) | `results/smoke/crash-136c8b2a89d357c695d5cd8da040d3e0420ee740` (57 bytes of garbage, which is what fuzzer files look like) |
| Scripts that build and run everything | `scripts/build.sh`, `scripts/baseline.sh` |
| The compiler toolchain (clang 21) | `toolchain/root/usr/lib/llvm-21/bin/` |

## Not on this machine (left out of git by `.gitignore`)

| What | Where it would be |
|---|---|
| **The fuzzer itself (libFuzzer)**, a library inside clang named `libclang_rt.fuzzer-x86_64.a` | `toolchain/root/usr/lib/llvm-21/lib/clang/21/lib/linux/` (missing because git ignores `*.a` files) |
| libsndfile source code, including the upstream harnesses in `ossfuzz/` | `libsndfile/` |
| The built fuzzer programs | `build/fuzz/ossfuzz/sndfile_fuzzer`, `build/fuzz/ossfuzz/sndfile_alt_fuzzer` |

## How to get the missing pieces back

### Docker (recommended, works on any machine including Macs)

```
docker build -t sndfile-fuzz .     # downloads libsndfile at the pinned commit and builds the fuzzers
docker run --rm --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
  -v "$PWD/results:/work/results" -e DURATION=600 \
  sndfile-fuzz scripts/baseline.sh my-run     # results land in results/my-run/
```

Pick a new run name each time; the default (`baseline`) overwrites the committed results. See `PROJECT_REVIEW_AND_PLAN.md` for more.

### Without Docker (Ubuntu only)

```
scripts/get-toolchain.sh   # re-downloads clang, including libFuzzer
scripts/build.sh fuzz      # downloads libsndfile and builds the fuzzers
```

## Who does what

- **Fuzzer:** creates the bad files.
- **Harness:** passes each file to libsndfile.
- **Sanitizers (ASan/UBSan):** catch the moment libsndfile misbehaves.
- **You:** pick good seeds and harnesses, then explain and fix the crashes.

```
Fuzzer → makes bytes → Harness → hands them to libsndfile → Sanitizers watch
```
