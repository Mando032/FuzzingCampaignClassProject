/* Build a valid WAV/GSM610 file whose header carries a sample rate high enough
 * that sf_current_byterate() overflows int at sndfile.c:1665
 * (samplerate * channels * 13000, GSM610 case).
 *
 * We let libsndfile write the file so the header is unquestionably valid: this
 * is what decides whether the overflow is reachable from a real file, not just
 * from the sample rate our H2 harness passes as the caller.
 *
 * 13000 * samplerate overflows int (max 2,147,483,647) once samplerate > 165,191.
 * We use 200000 Hz, mono (WAV GSM610 is mono only).
 *
 * usage: make_wav_gsm610 <out.wav>
 * then read it back and call sf_current_byterate() (see README).
 */
#include <stdio.h>
#include <sndfile.h>

int main (int argc, char **argv)
{	if (argc != 2)
	{	fprintf (stderr, "usage: %s <out.wav>\n", argv [0]) ;
		return 2 ;
		} ;

	SF_INFO info = { 0 } ;
	info.samplerate = 200000 ;
	info.channels = 1 ;
	info.format = SF_FORMAT_WAV | SF_FORMAT_GSM610 ;

	if (! sf_format_check (&info))
	{	fprintf (stderr, "format rejected by sf_format_check\n") ;
		return 1 ;
		} ;

	SNDFILE *sf = sf_open (argv [1], SFM_WRITE, &info) ;
	if (sf == NULL)
	{	fprintf (stderr, "sf_open write: %s\n", sf_strerror (NULL)) ;
		return 1 ;
		} ;

	/* A few frames of silence is enough; the overflow is in the header math,
	 * not the audio data. */
	short frames [160] = { 0 } ;
	sf_writef_short (sf, frames, 160) ;
	sf_close (sf) ;
	return 0 ;
}
