#!/usr/bin/env python3
"""Turn an llvm-cov JSON summary into a per-parser baseline table.

usage: summarize.py results/<run>
Writes files.csv and summary.md into the run directory.
"""
import csv
import glob
import json
import os
import re
import sys

# The minor containers named in the project abstract.
TARGETS = {
    "caf.c": "CAF", "sd2.c": "Sound Designer II", "w64.c": "W64",
    "mat4.c": "MAT4", "mat5.c": "MAT5", "pvf.c": "PVF", "htk.c": "HTK",
    "avr.c": "AVR", "ogg.c": "Ogg", "ogg_vorbis.c": "Ogg/Vorbis",
    "ogg_opus.c": "Ogg/Opus", "ogg_pcm.c": "Ogg/PCM",
    "ogg_speex.c": "Ogg/Speex", "ogg_vcomment.c": "Ogg comments",
}
MAINSTREAM = {"wav.c", "wavlike.c", "aiff.c", "flac.c", "au.c", "rf64.c"}
OTHER_CONTAINERS = {
    "paf.c", "svx.c", "nist.c", "voc.c", "ircam.c", "xi.c", "sds.c",
    "mpc2k.c", "wve.c", "dwd.c", "rx2.c", "txw.c", "raw.c", "mpeg.c",
    "mpeg_decode.c", "mpeg_l3_encode.c", "id3.c",
}
# Compiled as stubs when the external libraries are disabled.
EXTERNAL = {"flac.c", "mpeg.c", "mpeg_decode.c", "mpeg_l3_encode.c"} | {
    f for f in TARGETS if f.startswith("ogg")}


def category(rel):
    name = os.path.basename(rel)
    if os.sep in rel:
        return "codec library"
    if name in TARGETS:
        return "target"
    if name in MAINSTREAM:
        return "mainstream"
    if name in OTHER_CONTAINERS:
        return "other container"
    return "core/codec"


def fuzz_stats(run):
    """Last fork-mode status line of each fuzzer log."""
    pat = re.compile(r"#(\d+): cov: (\d+) ft: (\d+) corp: (\d+) exec/s:? (\d+) "
                     r"oom/timeout/crash: (\d+)/(\d+)/(\d+) time: (\d+)s")
    stats = {}
    for log in sorted(glob.glob(os.path.join(run, "*_fuzzer.log"))):
        last = None
        with open(log, errors="replace") as fh:
            for line in fh:
                m = pat.search(line)
                if m:
                    last = [int(x) for x in m.groups()]
        if last:
            last[4] = last[0] // max(last[8], 1)
            stats[os.path.basename(log)[:-4]] = last
    return stats


def main():
    run = sys.argv[1]
    with open(os.path.join(run, "coverage.json")) as fh:
        data = json.load(fh)["data"][0]

    src_root = os.path.commonpath([f["filename"] for f in data["files"]])
    rows = []
    for f in data["files"]:
        rel = os.path.relpath(f["filename"], src_root)
        if rel.endswith(".h") or os.path.basename(rel).startswith("test_"):
            continue
        s = f["summary"]
        rows.append({
            "file": rel,
            "category": category(rel),
            "lines": s["lines"]["count"],
            "lines_hit": s["lines"]["covered"],
            "line_pct": round(s["lines"]["percent"], 1),
            "functions": s["functions"]["count"],
            "functions_hit": s["functions"]["covered"],
            "branches": s["branches"]["count"],
            "branches_hit": s["branches"]["covered"],
            "branch_pct": round(s["branches"]["percent"], 1),
        })
    rows.sort(key=lambda r: (r["line_pct"], r["file"]))

    with open(os.path.join(run, "files.csv"), "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)

    def table(sel):
        out = ["| File | Format | Lines | Line % | Functions | Branch % |",
               "|---|---|---|---|---|---|"]
        for r in sel:
            name = os.path.basename(r["file"])
            note = " (stub, library disabled)" if name in EXTERNAL else ""
            out.append("| {} | {}{} | {}/{} | {} | {}/{} | {} |".format(
                r["file"], TARGETS.get(name, ""), note, r["lines_hit"],
                r["lines"], r["line_pct"], r["functions_hit"], r["functions"],
                r["branch_pct"]))
        return "\n".join(out)

    tot = data["totals"]
    md = ["# Coverage baseline: {}".format(os.path.basename(os.path.abspath(run))), ""]
    md.append("Overall src/: {:.1f}% lines ({}/{}), {:.1f}% branches, "
              "{:.1f}% functions.".format(
                  tot["lines"]["percent"], tot["lines"]["covered"],
                  tot["lines"]["count"], tot["branches"]["percent"],
                  tot["functions"]["percent"]))
    md.append("")
    stats = fuzz_stats(run)
    if stats:
        md += ["| Fuzzer | Execs | Edges | Features | Corpus | Exec/s | OOM | Timeout | Crash | Seconds |",
               "|---|---|---|---|---|---|---|---|---|---|"]
        for name, v in stats.items():
            md.append("| {} | {} |".format(name, " | ".join(str(x) for x in v)))
        md.append("")
    for title, cat in (("Target minor formats", "target"),
                       ("Mainstream formats", "mainstream"),
                       ("Other containers", "other container"),
                       ("Core and codecs", "core/codec"),
                       ("Bundled codec libraries", "codec library")):
        md += ["## " + title, "", table([r for r in rows if r["category"] == cat]), ""]
    with open(os.path.join(run, "summary.md"), "w") as fh:
        fh.write("\n".join(md))
    print("\n".join(md))


if __name__ == "__main__":
    main()
