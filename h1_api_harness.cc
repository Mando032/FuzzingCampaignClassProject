// H1: API-surface harness.
//
// The upstream harnesses open the input and only call sf_read_*. This one
// opens it the same way, then calls the metadata getters (sf_command,
// sf_get_string), the chunk iterator API, sf_seek and sf_read_raw, which
// upstream never reaches. Targets: command.c, broadcast.c, cart.c, chunk.c.
//
// Input layout: the last 3 bytes are control bytes (FuzzedDataProvider takes
// integers from the end); everything before them is the audio file.

#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sndfile.h>
#include <inttypes.h>
#include <vector>
#include <fuzzer/FuzzedDataProvider.h>

#include "sndfile_fuzz_header.h"

// Larger chunks are skipped, so a bogus size field cannot make us allocate GBs.
static const unsigned MAX_CHUNK = 1 << 20 ;

static void query_metadata (SNDFILE *sf, const SF_INFO *info)
{	char log [2048] ;
	sf_command (sf, SFC_GET_LOG_INFO, log, sizeof (log)) ;

	SF_INFO cur ;
	sf_command (sf, SFC_GET_CURRENT_SF_INFO, &cur, sizeof (cur)) ;
	sf_command (sf, SFC_RAW_DATA_NEEDS_ENDSWAP, NULL, 0) ;
	sf_command (sf, SFC_GET_BITRATE_MODE, NULL, 0) ;

	for (int s = SF_STR_FIRST ; s <= SF_STR_LAST ; s++)
		sf_get_string (sf, s) ;

	// Each struct is heap-allocated so ASan catches an overflow past its end.
	SF_BROADCAST_INFO *bext = (SF_BROADCAST_INFO *) malloc (sizeof (*bext)) ;
	sf_command (sf, SFC_GET_BROADCAST_INFO, bext, sizeof (*bext)) ;
	free (bext) ;

	SF_CART_INFO *cart = (SF_CART_INFO *) malloc (sizeof (*cart)) ;
	sf_command (sf, SFC_GET_CART_INFO, cart, sizeof (*cart)) ;
	free (cart) ;

	SF_INSTRUMENT *inst = (SF_INSTRUMENT *) malloc (sizeof (*inst)) ;
	sf_command (sf, SFC_GET_INSTRUMENT, inst, sizeof (*inst)) ;
	free (inst) ;

	SF_LOOP_INFO *loop = (SF_LOOP_INFO *) malloc (sizeof (*loop)) ;
	sf_command (sf, SFC_GET_LOOP_INFO, loop, sizeof (*loop)) ;
	free (loop) ;

	uint32_t cue_count = 0 ;
	sf_command (sf, SFC_GET_CUE_COUNT, &cue_count, sizeof (cue_count)) ;
	SF_CUES *cues = (SF_CUES *) malloc (sizeof (*cues)) ;
	sf_command (sf, SFC_GET_CUE, cues, sizeof (*cues)) ;
	free (cues) ;

	SF_EMBED_FILE_INFO embed ;
	sf_command (sf, SFC_GET_EMBED_FILE_INFO, &embed, sizeof (embed)) ;

	// These need one value per channel.
	std::vector<int> chan_map (info->channels) ;
	sf_command (sf, SFC_GET_CHANNEL_MAP_INFO, chan_map.data (), sizeof (int) * info->channels) ;

	double peak ;
	std::vector<double> peaks (info->channels) ;
	sf_command (sf, SFC_GET_SIGNAL_MAX, &peak, sizeof (peak)) ;
	sf_command (sf, SFC_GET_MAX_ALL_CHANNELS, peaks.data (), sizeof (double) * info->channels) ;
}

// Walk every chunk the parser recorded and copy out its data.
static void walk_chunks (SNDFILE *sf)
{	SF_CHUNK_ITERATOR *it = sf_get_chunk_iterator (sf, NULL) ;
	while (it != NULL)
	{	SF_CHUNK_INFO ci ;
		memset (&ci, 0, sizeof (ci)) ;
		if (sf_get_chunk_size (it, &ci) == SF_ERR_NO_ERROR && ci.datalen > 0 && ci.datalen <= MAX_CHUNK)
		{	ci.data = malloc (ci.datalen) ;
			sf_get_chunk_data (it, &ci) ;
			free (ci.data) ;
			} ;
		it = sf_next_chunk_iterator (it) ;
		} ;
}

// Seek around and read using the control bytes, then scan the whole file.
static void seek_and_read (SNDFILE *sf, const SF_INFO *info, uint8_t ops, int64_t pos)
{	static const int whence [] = { SEEK_SET, SEEK_CUR, SEEK_END } ;
	std::vector<uint8_t> raw (16 * info->channels) ;
	std::vector<float> frames (1024 * info->channels) ;

	for (int i = 0 ; i < 3 ; i++)
	{	sf_seek (sf, pos, whence [(ops >> (2 * i)) % 3]) ;
		if (ops & 0x40)
			sf_read_raw (sf, raw.data (), info->channels * (1 + (pos & 15))) ;
		else
			sf_readf_float (sf, frames.data (), 1024) ;
		pos = -pos / 2 ;
		} ;

	// Reads every sample from the start, through each codec's read path.
	if (ops & 0x80)
	{	double max ;
		sf_command (sf, SFC_CALC_SIGNAL_MAX, &max, sizeof (max)) ;
		} ;
}

extern "C" int LLVMFuzzerTestOneInput (const uint8_t *data, size_t size)
{	FuzzedDataProvider fdp (data, size) ;
	uint8_t ops = fdp.ConsumeIntegral<uint8_t> () ;
	int64_t pos = fdp.ConsumeIntegralInRange<int64_t> (-4096, 4096) ;
	std::vector<uint8_t> file = fdp.ConsumeRemainingBytes<uint8_t> () ;
	if (file.empty ())
		return 0 ;

	SF_INFO info ;
	VIO_DATA vio_data ;
	SF_VIRTUAL_IO vio ;
	SNDFILE *sf = NULL ;
	if (sf_init_file (file.data (), file.size (), &sf, &vio_data, &vio, &info) == 0 && sf != NULL)
	{	query_metadata (sf, &info) ;
		walk_chunks (sf) ;
		seek_and_read (sf, &info, ops, pos) ;
		} ;

	if (sf != NULL)
		sf_close (sf) ;
	return 0 ;
}
