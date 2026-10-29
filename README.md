# libsndfile Fuzzing Campaign

Software Security, Track B. Francis Njoku and Armando Mendoza Sanchez.

We fuzz [libsndfile](https://github.com/libsndfile/libsndfile) with libFuzzer under AddressSanitizer and UndefinedBehaviorSanitizer, and measure coverage with llvm-cov. This README explains how to reproduce our results in Docker. For the results themselves, see:

- [MILESTONE_SUMMARY.md](MILESTONE_SUMMARY.md): project status, results and plan
- [results/BASELINE_RESULTS.md](results/BASELINE_RESULTS.md): full baseline write-up with per-file coverage
- [PROJECT_REVIEW_AND_PLAN.md](PROJECT_REVIEW_AND_PLAN.md): detailed analysis and task list

## Requirements

- Docker on an x86-64 or arm64 machine (Windows with WSL2, macOS or Linux; setup below).
- At least 2 CPU cores and 4 GB of RAM. The campaign runs two fuzzers in parallel, one per core.
- About 2 GB of free disk space (the image is 1.6 GB).
- Internet access while building the image, to download Ubuntu packages and libsndfile.
- **No credentials, API keys or input files are needed.** The repository is public, and the crashing input for our finding is committed at `results/smoke/`.

**You don't need to clone libsndfile yourself.** The Docker build clones it and checks out the exact commit pinned in `scripts/env.sh`.

Everything the build uses is pinned:

| Component   | Version                                                                                             |
| ----------- | --------------------------------------------------------------------------------------------------- |
| Base image  | Ubuntu 26.04                                                                                        |
| Compiler    | clang / LLVM 21 (Ubuntu 21.1.8)                                                                     |
| libsndfile  | commit `b9103bd48b6c8fb517ae737fe3baee0c718b804c`                                                   |
| Tested with | Docker 29.8 (OrbStack) on Apple Silicon. The original baseline ran natively on Ubuntu 26.04 x86-64. |

## 1. Install Docker (free)

### Windows: WSL2 with Docker Engine

This installs Docker Engine inside Ubuntu on WSL2. It's free and doesn't need Docker Desktop.

1. Open PowerShell **as Administrator**, run the following, then restart the computer:

    ```powershell
    wsl --install
    ```

2. Open **Ubuntu** from the Start menu and create a user when it asks. In the Ubuntu terminal:

    ```sh
    sudo apt update && sudo apt install -y docker.io docker-buildx git
    ```

    ```sh
    sudo usermod -aG docker $USER
    ```

3. Close the Ubuntu window, open it again, and check that Docker works:

    ```sh
    docker run --rm hello-world
    ```

    If this says it can't connect to the Docker daemon, run `sudo service docker start` and try again.

Run every later command **in the Ubuntu terminal**, and clone into your Linux home directory (`cd ~`), not under `/mnt/c/`. A clone made from Windows can convert the scripts to Windows line endings, which breaks them.

### macOS: OrbStack

1. Install [OrbStack](https://orbstack.dev) (free for personal and non-commercial use) by downloading it or with Homebrew:

    ```sh
    brew install orbstack
    ```

2. Open OrbStack once so it starts, then check in Terminal:

    ```sh
    docker run --rm hello-world
    ```

On Apple Silicon the image is built for arm64. Coverage matches the x86-64 baseline (see the results below).

A fully open-source alternative is Colima: `brew install colima docker && colima start`.

### Linux

Install Docker Engine from your distribution (on Ubuntu or Debian, `sudo apt install docker.io docker-buildx`), then add yourself to the `docker` group with `sudo usermod -aG docker $USER` and log in again.

## 2. Set up

```sh
git clone https://github.com/Mando032/FuzzingCampaignClassProject.git
```

```sh
cd FuzzingCampaignClassProject
```

```sh
docker build -t sndfile-fuzz .
```

The build installs clang 21 and the libraries, clones libsndfile at the pinned commit, and compiles it twice:

- `build/fuzz`: ASan + UBSan + libFuzzer, for finding bugs
- `build/cov`: coverage instrumentation, for measuring what the fuzzers reached

A clean build took about 1 minute on an Apple Silicon Mac. Expect several minutes on a 2-core machine or a slow connection.

**Optional:** to read the libsndfile source at the same commit (for example the `src/mat4.c` lines in the finding), clone it next to the project:

```sh
git clone https://github.com/libsndfile/libsndfile.git
```

```sh
git -C libsndfile checkout b9103bd48b6c8fb517ae737fe3baee0c718b804c
```

The Docker build ignores this copy.

## 3. Run

All commands below are run from the `FuzzingCampaignClassProject` directory. The `-v "$PWD/results:/work/results"` option shares the `results/` folder with the container, so inputs are read from it and outputs land in it.

### a. Reproduce the MAT4 finding (a few seconds)

```sh
docker run --rm -v "$PWD/results:/work/results" -e UBSAN_OPTIONS=halt_on_error=1 \
  sndfile-fuzz build/fuzz/ossfuzz/sndfile_fuzzer \
  results/smoke/crash-136c8b2a89d357c695d5cd8da040d3e0420ee740
```

This feeds the 57-byte crashing input to the upstream harness. `halt_on_error=1` makes UBSan stop at the first problem. Expected output, after the libFuzzer start-up lines:

```
Running: results/smoke/crash-136c8b2a89d357c695d5cd8da040d3e0420ee740
/work/libsndfile/src/mat4.c:318:78: runtime error: signed integer overflow: 1553525816136777216 * 8 cannot be represented in type 'sf_count_t' (aka 'long')
SUMMARY: UndefinedBehaviorSanitizer: undefined-behavior /work/libsndfile/src/mat4.c:318:78
```

The command exits with status 1. The root cause, and the upstream commit that later fixed it, are explained in section 3 of [MILESTONE_SUMMARY.md](MILESTONE_SUMMARY.md).

### b. Short fuzzing campaign (just over 1 minute)

```sh
docker run --rm --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
  -v "$PWD/results:/work/results" -e DURATION=60 \
  sndfile-fuzz scripts/baseline.sh repro-60s
```

This runs both upstream harnesses for 60 seconds from an empty corpus, then replays what they found through the coverage build. Compare `results/repro-60s/` with our committed `results/docker-smoke/`, which is the same 60 s run.

### c. Full baseline (about 11 minutes)

Same command with `-e DURATION=600` and a new name, for example `repro-600s`. Compare with `results/baseline/`.

**Two things to know about these commands:**

- **Always give a new run name.** Without one, the script writes to `results/baseline/` and overwrites our committed results.
- **Keep `--cap-add=SYS_PTRACE --security-opt seccomp=unconfined`.** LeakSanitizer, part of ASan, aborts inside a container without them.

## 4. Expected results

| What to check                | File                     | Our result                                                                                     |
| ---------------------------- | ------------------------ | ---------------------------------------------------------------------------------------------- |
| Line coverage of `src/`      | `summary.md`, first line | 5.8% (1,494 / 25,814 in `baseline`, 1,493 in `docker-smoke`)                                   |
| UBSan sites                  | `ub_sites.txt`           | `src/mat4.c` lines 318, 320, 322, 323, signed integer overflow (325 also appears in some runs) |
| ASan crashes, OOMs, timeouts | `summary.md` table       | 0                                                                                              |

Fuzzing is random, so edge and line counts can differ by a few between runs. (Our check of these instructions from a clean build, on October 28, 2026, gave 5.8%, 1,494 / 25,814 lines, and the four `mat4.c` sites.) **Don't compare executions per second across machines:** speed depends on the hardware, and our Apple Silicon runs were about 3× faster than the 2-core x86-64 baseline host.

## 5. Output files

Each run writes `results/<run-name>/`:

| File                            | Contents                                                |
| ------------------------------- | ------------------------------------------------------- |
| `summary.md`                    | Overall coverage, fuzzer statistics and per-file tables |
| `files.csv`                     | Per-file line, branch and function coverage             |
| `coverage.txt`, `coverage.json` | Raw `llvm-cov` reports                                  |
| `html/index.html`               | Line-by-line coverage, viewable in a browser            |
| `ub_sites.txt`                  | UBSan sites triggered by the corpus                     |
| `corpus/`, `crashes/`           | Inputs the fuzzers kept, and any crashing inputs        |
| `*.log`                         | libFuzzer logs                                          |

On Linux and WSL these files are owned by root, because the container runs as root. Run `sudo chown -R $USER results/` if you want to edit or delete them.

## Repository layout

| Path                       | What                                                                                                                                |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `Dockerfile`               | Reproducible build environment (the only setup needed)                                                                              |
| `scripts/`                 | `build.sh` (builds), `baseline.sh` (fuzz + coverage run), `summarize.py` (report tables), `env.sh` (pinned commit and settings)     |
| `results/`                 | Committed results: `baseline/` (milestone 1), `docker-smoke/`, `smoke/` (MAT4 reproducer), `ossfuzz-20261012/` (OSS-Fuzz reference) |
| `scripts/get-toolchain.sh` | Downloads a fallback compiler for Ubuntu hosts without root. Not needed with Docker.                                                |
