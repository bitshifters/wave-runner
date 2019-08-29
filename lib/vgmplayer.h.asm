
\\ VGM Player module
\\ Include file
\\ Define ZP and constant vars only in here

VGM_ENABLE_AUDIO = TRUE		; enables output to sound chip (disable for silent testing/demo loop)
VGM_HAS_HEADER = FALSE		; set this to TRUE if the VGM bin file contains a metadata header (only useful for sound tracker type demos where you want to have the song info)  
VGM_FX = FALSE			; set this to TRUE to parse the music into vu-meter type buffers for effect purposes
VGM_DEINIT = TRUE		; set this to TRUE to silence the sound chip at tune end (if the tune doesn't do it itself)
VGM_FRAME_COUNT = TRUE		; set this to TRUE to keep a count of audio frames played
VGM_END_ALLOWED = TRUE		; set this to TRUE to permit vgm_poll_player to be called after the tune has finished
VGM_EXO_EOF = FALSE		; no FF byte at the end; rely on exo to tell us when the tune ends
VGM_65C02 = TRUE		; use 65C02 opcodes

IF VGM_65C02
	CPU 1
ENDIF

\ ******************************************************************
\ *	Define global constants
\ ******************************************************************



\ ******************************************************************
\ *	Declare FX variables
\ ******************************************************************

IF VGM_FX
VGM_FX_num_freqs = 32				; number of VU bars - can be 16 or 32
VGM_FX_num_channels = 4				; number of beat bars (one per channel)

\\ Frequency array for vu-meter effect, plus beat bars for 4 channels
\\ These two must be contiguous in memory
.vgm_freq_array				SKIP VGM_FX_num_freqs
.vgm_chan_array				SKIP VGM_FX_num_channels
.vgm_player_reg_vals		SKIP 8		; data values passed to each channel during audio playback (4x channels x pitch + volume)

.vgm_player_last_reg		SKIP 1		; last channel (register) refered to by the VGM sound data
.vgm_player_reg_bits		SKIP 1		; bits 0 - 7 set if SN register 0 - 7 updated this frame, cleared at start of player poll
.vgm_tmp			SKIP 1		; temporary counter
ENDIF ; VGM_FX

IF VGM_HAS_HEADER
\\ Copied out of the RAW VGM header
.vgm_player_packet_count	SKIP 2		; number of packets
.vgm_player_duration_mins	SKIP 1		; song duration (mins)
.vgm_player_duration_secs	SKIP 1		; song duration (secs)

.vgm_player_packet_offset	SKIP 1		; offset from start of file to beginning of packet data
ENDIF

IF VGM_END_ALLOWED
\\ Player vars
.vgm_player_ended			SKIP 1		; non-zero when player has reached end of tune
ENDIF
IF VGM_FX
.vgm_player_data			SKIP 1		; temporary variable when decoding sound data - must be separate as player running on events
ENDIF
.vgm_player_count			SKIP 1		; temporary counter
IF VGM_FRAME_COUNT
.vgm_player_counter			SKIP 2		; increments by 1 every poll (20ms) - used as our tracker line no. & to sync fx with audio update
ENDIF

\ ******************************************************************
\ *	VGM music player data area
\ ******************************************************************
IF VGM_HAS_HEADER
\\ Player
VGM_PLAYER_string_max = 42			; size of our meta data strings (title and author)
VGM_PLAYER_sample_rate = 50			; locked to 50Hz


.vgm_player_song_title_len	SKIP 1
.vgm_player_song_title		SKIP VGM_PLAYER_string_max
.vgm_player_song_author_len	SKIP 1
.vgm_player_song_author		SKIP VGM_PLAYER_string_max

.tmp_msg_idx SKIP 1

ENDIF


IF VGM_FX
.num_to_bit				; look up bit N
EQUB &01, &02, &04, &08, &10, &20, &40, &80
ENDIF
