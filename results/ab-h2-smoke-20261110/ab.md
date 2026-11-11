# A/B comparison: ab-h2-smoke-20261110

Lines hit: median (min–max) over 2 runs per harness. Each run is one harness alone on one core.

| File | Lines | h2_raw_fuzzer | sndfile_fuzzer |
|---|---|---|---|
| src/ (all files) | 25814 | 2926 (2926–2926) | 1143.5 (1127–1160) |
| broadcast.c | 96 | 0 (0–0) | 0 (0–0) |
| cart.c | 42 | 0 (0–0) | 0 (0–0) |
| chunk.c | 164 | 0 (0–0) | 0 (0–0) |
| command.c | 125 | 0 (0–0) | 0 (0–0) |
| raw.c | 58 | 56 (56–56) | 0 (0–0) |
| vox_adpcm.c | 240 | 128 (128–128) | 0 (0–0) |
| ima_oki_adpcm.c | 62 | 36 (36–36) | 0 (0–0) |
| nms_adpcm.c | 611 | 315 (315–315) | 0 (0–0) |
| dwvw.c | 381 | 203 (203–203) | 0 (0–0) |
| gsm610.c | 367 | 161 (161–161) | 0 (0–0) |
| ulaw.c | 203 | 88 (88–88) | 0 (0–0) |
| alaw.c | 202 | 87 (87–87) | 0 (0–0) |
| libFuzzer edges (final) | | 3659.5 (3657–3662) | 1465.5 (1464–1467) |

Edges are counted inside each binary and include the harness's own code, so compare harnesses by lines, not by edges.

Settings of the first run (`meta.txt`; the others differ only in date and harness):

```
date: 2026-11-11T06:27:10Z
host: Linux 7.2.12-orbstack-00394-gbecdd6130068 aarch64, 15 cores
duration_s: 60
harnesses: h2_raw_fuzzer (one core per harness)
builds: build/fuzz build/cov
libsndfile: b9103bd48b6c8fb517ae737fe3baee0c718b804c
clang: Ubuntu clang version 21.1.8 (6ubuntu1)
seeds: /work/results/baseline/corpus/sndfile_fuzzer (152 files)
```
