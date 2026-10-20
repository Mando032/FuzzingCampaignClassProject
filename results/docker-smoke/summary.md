# Coverage baseline: docker-smoke

Overall src/: 5.8% lines (1493/25814), 5.3% branches, 9.8% functions.

| Fuzzer | Execs | Edges | Features | Corpus | Exec/s | OOM | Timeout | Crash | Seconds |
|---|---|---|---|---|---|---|---|---|---|
| sndfile_alt_fuzzer | 4220642 | 1741 | 2801 | 189 | 64932 | 0 | 0 | 0 | 65 |
| sndfile_fuzzer | 3849425 | 1458 | 2953 | 125 | 59221 | 0 | 0 | 0 | 65 |

## Target minor formats

| File | Format | Lines | Line % | Functions | Branch % |
|---|---|---|---|---|---|
| avr.c | AVR | 0/101 | 0 | 0/4 | 0 |
| caf.c | CAF | 0/680 | 0 | 0/16 | 0 |
| mat5.c | MAT5 | 0/299 | 0 | 0/4 | 0 |
| ogg.c | Ogg (stub, library disabled) | 0/4 | 0 | 0/1 | 0 |
| pvf.c | PVF | 0/87 | 0 | 0/4 | 0 |
| sd2.c | Sound Designer II | 0/348 | 0 | 0/10 | 0 |
| w64.c | W64 | 0/343 | 0 | 0/4 | 0 |
| htk.c | HTK | 47/81 | 58.0 | 3/4 | 34.1 |
| mat4.c | MAT4 | 123/209 | 58.9 | 4/6 | 50 |

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
| nist.c |  | 0/219 | 0 | 0/4 | 0 |
| paf.c |  | 0/486 | 0 | 0/18 | 0 |
| raw.c |  | 0/58 | 0 | 0/1 | 0 |
| rx2.c |  | 0/4 | 0 | 0/1 | 0 |
| sds.c |  | 0/646 | 0 | 0/23 | 0 |
| svx.c |  | 0/217 | 0 | 0/4 | 0 |
| txw.c |  | 0/4 | 0 | 0/1 | 0 |
| voc.c |  | 0/304 | 0 | 0/5 | 0 |
| wve.c |  | 0/98 | 0 | 0/4 | 0 |
| xi.c |  | 0/746 | 0 | 0/38 | 0 |
| mpeg.c |  (stub, library disabled) | 4/8 | 50 | 1/2 | 0 |
| mpc2k.c |  | 41/78 | 52.6 | 3/4 | 37.5 |

## Core and codecs

| File | Format | Lines | Line % | Functions | Branch % |
|---|---|---|---|---|---|
| alac.c |  | 0/598 | 0 | 0/26 | 0 |
| alaw.c |  | 0/202 | 0 | 0/17 | 0 |
| audio_detect.c |  | 0/41 | 0 | 0/2 | 0 |
| broadcast.c |  | 0/96 | 0 | 0/5 | 0 |
| cart.c |  | 0/42 | 0 | 0/4 | 0 |
| chanmap.c |  | 0/24 | 0 | 0/2 | 0 |
| chunk.c |  | 0/164 | 0 | 0/10 | 0 |
| command.c |  | 0/125 | 0 | 0/11 | 0 |
| dither.c |  | 0/234 | 0 | 0/11 | 0 |
| dwvw.c |  | 0/381 | 0 | 0/17 | 0 |
| g72x.c |  | 0/319 | 0 | 0/15 | 0 |
| gsm610.c |  | 0/367 | 0 | 0/17 | 0 |
| ima_adpcm.c |  | 0/635 | 0 | 0/22 | 0 |
| ima_oki_adpcm.c |  | 0/62 | 0 | 0/5 | 0 |
| ms_adpcm.c |  | 0/504 | 0 | 0/18 | 0 |
| nms_adpcm.c |  | 0/611 | 0 | 0/29 | 0 |
| strings.c |  | 0/106 | 0 | 0/4 | 0 |
| ulaw.c |  | 0/203 | 0 | 0/17 | 0 |
| vox_adpcm.c |  | 0/240 | 0 | 0/12 | 0 |
| pcm.c |  | 256/1885 | 13.6 | 22/137 | 11.3 |
| sndfile.c |  | 377/2166 | 17.4 | 16/49 | 11.4 |
| float32.c |  | 113/637 | 17.7 | 9/33 | 15.7 |
| double64.c |  | 136/648 | 21.0 | 10/33 | 21.2 |
| file_io.c |  | 74/334 | 22.2 | 11/23 | 11.5 |
| common.c |  | 293/1203 | 24.4 | 12/59 | 20.5 |

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
| GSM610/add.c |  | 0/119 | 0 | 0/14 | 0 |
| GSM610/code.c |  | 0/30 | 0 | 0/1 | 0 |
| GSM610/decode.c |  | 0/23 | 0 | 0/2 | 0 |
| GSM610/gsm_create.c |  | 0/12 | 0 | 0/2 | 0 |
| GSM610/gsm_decode.c |  | 0/337 | 0 | 0/1 | 0 |
| GSM610/gsm_destroy.c |  | 0/4 | 0 | 0/1 | 0 |
| GSM610/gsm_encode.c |  | 0/341 | 0 | 0/1 | 0 |
| GSM610/gsm_option.c |  | 0/40 | 0 | 0/1 | 0 |
| GSM610/long_term.c |  | 0/232 | 0 | 0/5 | 0 |
| GSM610/lpc.c |  | 0/182 | 0 | 0/6 | 0 |
| GSM610/preprocess.c |  | 0/35 | 0 | 0/1 | 0 |
| GSM610/rpe.c |  | 0/179 | 0 | 0/8 | 0 |
| GSM610/short_term.c |  | 0/197 | 0 | 0/12 | 0 |
