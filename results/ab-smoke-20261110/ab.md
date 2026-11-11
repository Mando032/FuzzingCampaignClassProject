# A/B comparison: ab-smoke-20261110

Lines hit: median (min–max) over 2 runs per harness. Each run is one harness alone on one core.

| File | Lines | h1_api_fuzzer | sndfile_alt_fuzzer | sndfile_fuzzer |
|---|---|---|---|---|
| src/ (all files) | 25814 | 1489.5 (1488–1491) | 1373 (1373–1373) | 1128.5 (1128–1129) |
| broadcast.c | 96 | 4 (4–4) | 0 (0–0) | 0 (0–0) |
| cart.c | 42 | 4 (4–4) | 0 (0–0) | 0 (0–0) |
| chunk.c | 164 | 7 (7–7) | 0 (0–0) | 0 (0–0) |
| command.c | 125 | 33 (33–33) | 0 (0–0) | 0 (0–0) |
| libFuzzer edges (final) | | 1974 (1972–1976) | 1742 (1741–1743) | 1464 (1463–1465) |

Edges are counted inside each binary and include the harness's own code, so compare harnesses by lines, not by edges.

Settings of the first run (`meta.txt`; the others differ only in date and harness):

```
date: 2026-11-11T06:06:41Z
host: Linux 7.2.12-orbstack-00394-gbecdd6130068 aarch64, 15 cores
duration_s: 60
harnesses: h1_api_fuzzer (one core each, run in parallel)
builds: build/fuzz build/cov
libsndfile: b9103bd48b6c8fb517ae737fe3baee0c718b804c
clang: Ubuntu clang version 21.1.8 (6ubuntu1)
seeds: /work/results/baseline/corpus/sndfile_fuzzer (152 files)
```
