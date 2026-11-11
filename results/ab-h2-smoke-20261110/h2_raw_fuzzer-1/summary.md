# Coverage baseline: h2_raw_fuzzer-1

Overall src/: 11.3% lines (2926/25814), 9.2% branches, 20.9% functions.

| Fuzzer | Execs | Edges | Features | Corpus | Exec/s | OOM | Timeout | Crash | Seconds |
|---|---|---|---|---|---|---|---|---|---|
| h2_raw_fuzzer | 830086 | 3662 | 11091 | 944 | 12770 | 0 | 0 | 0 | 65 |

## Target minor formats

| File | Format | Lines | Line % | Functions | Branch % |
|---|---|---|---|---|---|
| avr.c | AVR | 0/101 | 0 | 0/4 | 0 |
| caf.c | CAF | 0/680 | 0 | 0/16 | 0 |
| htk.c | HTK | 0/81 | 0 | 0/4 | 0 |
| mat4.c | MAT4 | 0/209 | 0 | 0/6 | 0 |
| mat5.c | MAT5 | 0/299 | 0 | 0/4 | 0 |
| ogg.c | Ogg (stub, library disabled) | 0/4 | 0 | 0/1 | 0 |
| pvf.c | PVF | 0/87 | 0 | 0/4 | 0 |
| sd2.c | Sound Designer II | 0/348 | 0 | 0/10 | 0 |
| w64.c | W64 | 0/343 | 0 | 0/4 | 0 |

## Mainstream formats

| File | Format | Lines | Line % | Functions | Branch % |
|---|---|---|---|---|---|
| aiff.c |  | 0/1167 | 0 | 0/20 | 0 |
| au.c |  | 0/252 | 0 | 0/5 | 0 |
| flac.c |  (stub, library disabled) | 0/4 | 0 | 0/1 | 0 |
| rf64.c |  | 0/516 | 0 | 0/11 | 0 |
| wav.c |  | 0/977 | 0 | 0/14 | 0 |
| wavlike.c |  | 0/856 | 0 | 0/18 | 0 |

## Other containers

| File | Format | Lines | Line % | Functions | Branch % |
|---|---|---|---|---|---|
| dwd.c |  | 0/4 | 0 | 0/1 | 0 |
| id3.c |  | 0/42 | 0 | 0/3 | 0 |
| ircam.c |  | 0/160 | 0 | 0/6 | 0 |
| mpc2k.c |  | 0/78 | 0 | 0/4 | 0 |
| mpeg.c |  (stub, library disabled) | 0/8 | 0 | 0/2 | 0 |
| nist.c |  | 0/219 | 0 | 0/4 | 0 |
| paf.c |  | 0/486 | 0 | 0/18 | 0 |
| rx2.c |  | 0/4 | 0 | 0/1 | 0 |
| sds.c |  | 0/646 | 0 | 0/23 | 0 |
| svx.c |  | 0/217 | 0 | 0/4 | 0 |
| txw.c |  | 0/4 | 0 | 0/1 | 0 |
| voc.c |  | 0/304 | 0 | 0/5 | 0 |
| wve.c |  | 0/98 | 0 | 0/4 | 0 |
| xi.c |  | 0/746 | 0 | 0/38 | 0 |
| raw.c |  | 56/58 | 96.6 | 1/1 | 89.1 |

## Core and codecs

| File | Format | Lines | Line % | Functions | Branch % |
|---|---|---|---|---|---|
| alac.c |  | 0/598 | 0 | 0/26 | 0 |
| audio_detect.c |  | 0/41 | 0 | 0/2 | 0 |
| broadcast.c |  | 0/96 | 0 | 0/5 | 0 |
| cart.c |  | 0/42 | 0 | 0/4 | 0 |
| chanmap.c |  | 0/24 | 0 | 0/2 | 0 |
| chunk.c |  | 0/164 | 0 | 0/10 | 0 |
| command.c |  | 0/125 | 0 | 0/11 | 0 |
| dither.c |  | 0/234 | 0 | 0/11 | 0 |
| g72x.c |  | 0/319 | 0 | 0/15 | 0 |
| ima_adpcm.c |  | 0/635 | 0 | 0/22 | 0 |
| ms_adpcm.c |  | 0/504 | 0 | 0/18 | 0 |
| strings.c |  | 0/106 | 0 | 0/4 | 0 |
| file_io.c |  | 31/334 | 9.3 | 9/23 | 3.6 |
| common.c |  | 147/1203 | 12.2 | 7/59 | 9.6 |
| sndfile.c |  | 354/2166 | 16.3 | 13/49 | 12.9 |
| double64.c |  | 125/648 | 19.3 | 9/33 | 17.1 |
| float32.c |  | 129/637 | 20.3 | 9/33 | 17.9 |
| pcm.c |  | 659/1885 | 35.0 | 61/137 | 29.1 |
| alaw.c |  | 87/202 | 43.1 | 9/17 | 32.7 |
| ulaw.c |  | 88/203 | 43.3 | 9/17 | 32.7 |
| gsm610.c |  | 161/367 | 43.9 | 8/17 | 37.3 |
| nms_adpcm.c |  | 315/611 | 51.6 | 17/29 | 50.4 |
| dwvw.c |  | 203/381 | 53.3 | 11/17 | 46.4 |
| vox_adpcm.c |  | 128/240 | 53.3 | 7/12 | 34.7 |
| ima_oki_adpcm.c |  | 36/62 | 58.1 | 3/5 | 70 |

## Bundled codec libraries

| File | Format | Lines | Line % | Functions | Branch % |
|---|---|---|---|---|---|
| ALAC/ALACBitUtilities.c |  | 0/126 | 0 | 0/13 | 0 |
| ALAC/ag_dec.c |  | 0/196 | 0 | 0/9 | 0 |
| ALAC/ag_enc.c |  | 0/208 | 0 | 0/8 | 0 |
| ALAC/alac_decoder.c |  | 0/406 | 0 | 0/5 | 0 |
| ALAC/alac_encoder.c |  | 0/670 | 0 | 0/11 | 0 |
| ALAC/dp_dec.c |  | 0/269 | 0 | 0/2 | 0 |
| ALAC/dp_enc.c |  | 0/280 | 0 | 0/4 | 0 |
| ALAC/matrix_dec.c |  | 0/187 | 0 | 0/9 | 0 |
| ALAC/matrix_enc.c |  | 0/168 | 0 | 0/4 | 0 |
| G72x/g721.c |  | 0/38 | 0 | 0/2 | 0 |
| G72x/g723_16.c |  | 0/42 | 0 | 0/2 | 0 |
| G72x/g723_24.c |  | 0/39 | 0 | 0/2 | 0 |
| G72x/g723_40.c |  | 0/39 | 0 | 0/2 | 0 |
| G72x/g72x.c |  | 0/373 | 0 | 0/16 | 0 |
| GSM610/code.c |  | 0/30 | 0 | 0/1 | 0 |
| GSM610/gsm_encode.c |  | 0/341 | 0 | 0/1 | 0 |
| GSM610/gsm_option.c |  | 0/40 | 0 | 0/1 | 0 |
| GSM610/lpc.c |  | 0/182 | 0 | 0/6 | 0 |
| GSM610/preprocess.c |  | 0/35 | 0 | 0/1 | 0 |
| GSM610/long_term.c |  | 14/232 | 6.0 | 1/5 | 7.9 |
| GSM610/add.c |  | 16/119 | 13.4 | 3/14 | 9 |
| GSM610/rpe.c |  | 58/179 | 32.4 | 4/8 | 28.3 |
| GSM610/gsm_decode.c |  | 111/337 | 32.9 | 1/1 | 50 |
| GSM610/short_term.c |  | 107/197 | 54.3 | 8/12 | 39.7 |
| GSM610/gsm_create.c |  | 8/12 | 66.7 | 1/2 | 50 |
| GSM610/decode.c |  | 23/23 | 100 | 2/2 | 100 |
| GSM610/gsm_destroy.c |  | 4/4 | 100 | 1/1 | 50 |
