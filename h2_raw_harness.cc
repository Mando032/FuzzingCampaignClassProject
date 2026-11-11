// H2: RAW container with an explicit codec.
//
// A RAW file has no header, so libsndfile only opens one when the caller puts
// SF_FORMAT_RAW | codec in SF_INFO. The upstream harnesses always pass a zeroed
// SF_INFO, which is why raw.c, vox_adpcm.c and ima_oki_adpcm.c (used by VOX)
// get no upstream fuzzing at all. This harness picks the codec, endianness,
// channel count and sample rate from control bytes and decodes the rest.
//
// Not reachable this way: G72x (sf_format_check rejects it for RAW; only AU and
// WAV use it) and G72x/g723_16.c (no format selects it at our pin).
//
// Input layout: control bytes at the end (FuzzedDataProvider takes integers
// from the end); everything before them is the headerless audio data.

#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sndfile.h>
#include <inttypes.h>
#include <vector>
#include <fuzzer/FuzzedDataProvider.h>

#include "sndfile_fuzz_header.h"

// Every codec raw_open() accepts. sf_format_check() only allows the
// mono_only ones with channels == 1, so we never pick a combination that
// would just be rejected.
struct Codec { int format ; bool mono_only ; } ;
static const Codec CODECS [] =
{	{ SF_FORMAT_PCM_S8, false }, { SF_FORMAT_PCM_U8, false }, { SF_FORMAT_PCM_16, false },
	{ SF_FORMAT_PCM_24, false }, { SF_FORMAT_PCM_32, false }, { SF_FORMAT_FLOAT, false },
	{ SF_FORMAT_DOUBLE, false }, { SF_FORMAT_ULAW, false }, { SF_FORMAT_ALAW, false },
	{ SF_FORMAT_GSM610, true }, { SF_FORMAT_VOX_ADPCM, true },
	{ SF_FORMAT_NMS_ADPCM_16, true }, { SF_FORMAT_NMS_ADPCM_24, true }, { SF_FORMAT_NMS_ADPCM_32, true },
	{ SF_FORMAT_DWVW_12, true }, { SF_FORMAT_DWVW_16, true }, { SF_FORMAT_DWVW_24, true },
} ;
// pcm.c, float32.c and double64.c have separate big- and little-endian paths.
static const int ENDIANS [] = { SF_ENDIAN_FILE, SF_ENDIAN_LITTLE, SF_ENDIAN_BIG, SF_ENDIAN_CPU } ;

// Each codec has one converter per sample type, so the type is fuzzed too.
template <typename T>
static void read_all (SNDFILE *sf, int channels, sf_count_t (*readf) (SNDFILE *, T *, sf_count_t))
{	std::vector<T> buf (1024 * channels) ;
	while (readf (sf, buf.data (), 1024) > 0)
		;
}

static void read_as (SNDFILE *sf, int channels, int type)
{	switch (type)
	{	case 0 : read_all<short> (sf, channels, sf_readf_short) ; break ;
		case 1 : read_all<int> (sf, channels, sf_readf_int) ; break ;
		case 2 : read_all<float> (sf, channels, sf_readf_float) ; break ;
		default : read_all<double> (sf, channels, sf_readf_double) ; break ;
		} ;
}

extern "C" int LLVMFuzzerTestOneInput (const uint8_t *data, size_t size)
{	FuzzedDataProvider fdp (data, size) ;
	const Codec codec = fdp.PickValueInArray (CODECS) ;
	int endian = fdp.PickValueInArray (ENDIANS) ;
	int channels = codec.mono_only ? 1 : fdp.ConsumeIntegralInRange<int> (1, 8) ;
	// Real audio rates only, so an overflow found here can't be blamed on an
	// absurd value from the caller.
	int samplerate = fdp.ConsumeIntegralInRange<int> (1, 384000) ;
	uint8_t ops = fdp.ConsumeIntegral<uint8_t> () ;
	sf_count_t seek_to = fdp.ConsumeIntegralInRange<sf_count_t> (0, 4096) ;
	std::vector<uint8_t> file = fdp.ConsumeRemainingBytes<uint8_t> () ;
	if (file.empty ())
		return 0 ;

	VIO_DATA vio_data = { 0, (sf_count_t) file.size (), file.data () } ;
	SF_VIRTUAL_IO vio = { vfget_filelen, vfseek, vfread, vfwrite, vftell } ;
	SF_INFO info ;
	memset (&info, 0, sizeof (info)) ;
	info.format = SF_FORMAT_RAW | codec.format | endian ;
	info.channels = channels ;
	info.samplerate = samplerate ;

	SNDFILE *sf = sf_open_virtual (&vio, SFM_READ, &info, &vio_data) ;
	if (sf == NULL)
		return 0 ;

	// At our pin dwvw_byterate() divides by frames without a zero check
	// (fixed upstream in e82eb494, after our pin). Unguarded, that SIGFPE ends
	// most fork-mode jobs and hides everything else H2 could reach. Set
	// H2_BYTERATE_UNGUARDED=1 to reproduce it.
	if (info.frames > 0 || getenv ("H2_BYTERATE_UNGUARDED") != NULL)
		sf_current_byterate (sf) ;

	read_as (sf, channels, ops & 3) ;
	// dwvw.c and gsm610.c have their own seek functions; the rest use the generic one.
	if ((ops & 4) && sf_seek (sf, seek_to, SEEK_SET) >= 0)
		read_as (sf, channels, (ops >> 3) & 3) ;

	sf_close (sf) ;
	return 0 ;
}
