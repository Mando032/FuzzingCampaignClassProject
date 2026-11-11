#!/usr/bin/env python3
"""Compare the runs of one scripts/ab.sh experiment.

usage: ab_summary.py results/<name>
Every sub-directory <harness>-<rep> is one baseline.sh run of one harness.
Writes into results/<name>/:
  ab.csv             per harness and source file: median, min, max lines hit
  ab.md              the same for the src/ total and the H1 target files
  cov_over_time.csv  libFuzzer edges against seconds, from the fuzzer logs
"""
import csv
import glob
import json
import os
import re
import statistics
import sys
from collections import defaultdict

TOTAL = "src/ (all files)"
# Files our harnesses are meant to reach. H1: APIs upstream never calls.
# H2: RAW and the codecs it selects explicitly.
TARGETS = ["broadcast.c", "cart.c", "chunk.c", "command.c",
           "raw.c", "vox_adpcm.c", "ima_oki_adpcm.c", "nms_adpcm.c",
           "dwvw.c", "gsm610.c", "ulaw.c", "alaw.c"]
# Fork-mode status line, same format summarize.py reads.
STATUS = re.compile(r"cov: (\d+) ft: \d+ corp: \d+ .* time: (\d+)s")


def spread(values):
    return "{:g} ({}–{})".format(statistics.median(values), min(values), max(values))


def main():
    exp = sys.argv[1]
    hits = defaultdict(lambda: defaultdict(list))  # harness -> file -> lines hit, one per run
    lines = {}                                     # file -> lines in the file
    edges = defaultdict(list)                      # harness -> final edge count, one per run
    curve = []                                     # (harness, rep, seconds, edges)

    for run in sorted(glob.glob(os.path.join(exp, "*-*", ""))):
        harness, rep = os.path.basename(run[:-1]).rsplit("-", 1)
        with open(run + "coverage.json") as fh:
            tot = json.load(fh)["data"][0]["totals"]["lines"]
        hits[harness][TOTAL].append(tot["covered"])
        lines[TOTAL] = tot["count"]
        with open(run + "files.csv") as fh:
            for row in csv.DictReader(fh):
                hits[harness][row["file"]].append(int(row["lines_hit"]))
                lines[row["file"]] = int(row["lines"])
        last = 0
        with open(run + harness + ".log", errors="replace") as fh:
            for m in STATUS.finditer(fh.read()):
                last = int(m.group(1))
                curve.append((harness, rep, int(m.group(2)), last))
        edges[harness].append(last)

    # A median over unequal run counts would not be an equal-effort comparison.
    assert hits, "no <harness>-<rep> runs under " + exp
    assert len({len(v) for v in edges.values()}) == 1, \
        "harnesses have different numbers of runs: {}".format(dict(edges))
    names = sorted(hits)

    with open(os.path.join(exp, "ab.csv"), "w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["harness", "file", "lines", "runs", "median_hit", "min_hit", "max_hit"])
        for h in names:
            for f, v in hits[h].items():
                w.writerow([h, f, lines[f], len(v), statistics.median(v), min(v), max(v)])

    with open(os.path.join(exp, "cov_over_time.csv"), "w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["harness", "rep", "seconds", "edges"])
        w.writerows(curve)

    md = ["# A/B comparison: " + os.path.basename(os.path.abspath(exp)), "",
          "Lines hit: median (min–max) over {} runs per harness. Each run is one "
          "harness alone on one core.".format(len(edges[names[0]])), "",
          "| File | Lines | " + " | ".join(names) + " |",
          "|---|---|" + "---|" * len(names)]
    for f in [TOTAL] + TARGETS:
        md.append("| {} | {} | {} |".format(
            f, lines[f], " | ".join(spread(hits[h][f]) for h in names)))
    md.append("| libFuzzer edges (final) | | {} |".format(
        " | ".join(spread(edges[h]) for h in names)))
    md += ["", "Edges are counted inside each binary and include the harness's own "
           "code, so compare harnesses by lines, not by edges.", "",
           "Settings of the first run (`meta.txt`; the others differ only in date "
           "and harness):", "", "```"]
    with open(os.path.join(sorted(glob.glob(os.path.join(exp, "*-*", "")))[0], "meta.txt")) as fh:
        md += [fh.read().rstrip(), "```", ""]
    with open(os.path.join(exp, "ab.md"), "w") as fh:
        fh.write("\n".join(md))
    print("\n".join(md))


if __name__ == "__main__":
    main()
