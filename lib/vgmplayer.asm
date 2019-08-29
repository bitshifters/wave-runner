\ ******************************************************************
\\ VGM Player
\\ Code module
\ ******************************************************************

.vgm_player_start

\ ******************************************************************
\ *	VGM music player routines
\ * Plays a RAW format VGM music stream from an Exomiser compressed data stream
\ ******************************************************************

\\ Initialise the VGM player with an Exomizer compressed data stream
\\ X - lo byte of data stream to be played
\\ Y - hi byte of data stream to be played
.vgm_init_stream
{
	\\ Initialise exomizer - must have some data ready to decrunch
	JSR exo_init_decruncher

	\\ Initialise music player - parses header
	; fall through
}

.vgm_init_player
{
IF VGM_HAS_HEADER
	; non-zero return in A on error only if VGM_HAS_HEADER is defined
\\ <header section>
\\  [byte] - header size - indicates number of bytes in header section

	LDA #1
	STA vgm_player_packet_offset

	jsr exo_get_decrunched_byte
	STA vgm_player_count
	CMP #5
	BCS parse_header			; we need at least 5 bytes to parse!
	JMP error

	.parse_header
	CLC
	ADC vgm_player_packet_offset
	STA vgm_player_packet_offset

\\  [byte] - indicates the required playback rate in Hz eg. 50/60/100

	jsr exo_get_decrunched_byte		; should really check carry status for EOF
	CMP #VGM_PLAYER_sample_rate		; we only support 50Hz files
	BEQ is_50HZ					; return non-zero to indicate error
	JMP error
	.is_50HZ
	DEC vgm_player_count

\\  [byte] - packet count lsb

	jsr exo_get_decrunched_byte		; should really check carry status for EOF
	STA vgm_player_packet_count
	DEC vgm_player_count

\\  [byte] - packet count msb

	jsr exo_get_decrunched_byte		; should really check carry status for EOF
	STA vgm_player_packet_count+1
	DEC vgm_player_count

\\  [byte] - duration minutes

	jsr exo_get_decrunched_byte		; should really check carry status for EOF
	STA vgm_player_duration_mins
	DEC vgm_player_count

\\  [byte] - duration seconds

	jsr exo_get_decrunched_byte		; should really check carry status for EOF
	STA vgm_player_duration_secs

	.header_loop
	DEC vgm_player_count
	BEQ done_header

	jsr exo_get_decrunched_byte		; should really check carry status for EOF
	\\ don't know what this byte is so ignore it
	JMP header_loop

	.done_header

\\ <title section>
\\  [byte] - title string size

	INC vgm_player_packet_offset

	jsr exo_get_decrunched_byte		; should really check carry status for EOF
	STA vgm_player_count

	CLC
	ADC vgm_player_packet_offset
	STA vgm_player_packet_offset

\\  [dd] ... - ZT title string

	LDX #0
	.title_loop
	STX tmp_msg_idx
	LDA vgm_player_count
	BEQ done_title				; make sure we consume all the title string
	DEC vgm_player_count

	jsr exo_get_decrunched_byte		; should really check carry status for EOF
	LDX tmp_msg_idx
	CPX #VGM_PLAYER_string_max
	BCS title_loop				; don't write if buffer full
	STA vgm_player_song_title,X
	INX
	JMP title_loop

	\\ Where title string is smaller than our buffer
	.done_title
	STX vgm_player_song_title_len
	LDA #' '
	.title_pad_loop
	CPX #VGM_PLAYER_string_max
	BCS done_title_padding
	STA vgm_player_song_title,X
	INX
	JMP title_pad_loop
	.done_title_padding

\\ <author section>
\\  [byte] - author string size

	INC vgm_player_packet_offset

	jsr exo_get_decrunched_byte		; should really check carry status for EOF
	STA vgm_player_count

	CLC
	ADC vgm_player_packet_offset
	STA vgm_player_packet_offset

\\  [dd] ... - ZT author string

	LDX #0
	.author_loop
	STX tmp_msg_idx
	LDA vgm_player_count
	BEQ done_author				; make sure we consume all the author string
	DEC vgm_player_count

	jsr exo_get_decrunched_byte		; should really check carry status for EOF
	LDX tmp_msg_idx
	CPX #VGM_PLAYER_string_max
	BCS author_loop
	STA vgm_player_song_author,X	; don't write if buffer full
	INX
	JMP author_loop

	\\ Where author string is smaller than our buffer
	.done_author
	STX vgm_player_song_author_len
	LDA #' '
	.author_pad_loop
	CPX #VGM_PLAYER_string_max
	BCS done_author_padding
	STA vgm_player_song_author,X
	INX
	JMP author_pad_loop
	.done_author_padding
ENDIF ;VGM_HAS_HEADER

	\\ Initialise vars
IF VGM_FRAME_COUNT
	LDA #&FF
	STA vgm_player_counter
	STA vgm_player_counter+1
ENDIF
IF VGM_END_ALLOWED
IF VGM_65C02
	STZ vgm_player_ended
ELSE
	LDA #0
	STA vgm_player_ended
ENDIF
ENDIF
IF VGM_FX
IF VGM_65C02
	STZ vgm_player_last_reg
	STZ vgm_player_reg_bits
ELSE
	LDA #0
	STA vgm_player_last_reg
	STA vgm_player_reg_bits
ENDIF
ENDIF
	\\ Return zero 
	RTS

IF VGM_HAS_HEADER
	\\ Return error
.error
	LDA #&FF
	RTS
ENDIF
}

IF VGM_DEINIT
.vgm_deinit_player
{
	\\ Zero volume on all channels
	LDA #&9F: JSR psg_strobe
	LDA #&BF: JSR psg_strobe
	LDA #&DF: JSR psg_strobe
	LDA #&FF
IF VGM_END_ALLOWED	
	STA vgm_player_ended
ENDIF
	; fall-through
}
.psg_strobe
{
IF VGM_ENABLE_AUDIO
	ldy #255
	sty $fe43
	sta $fe4f ; not $fe41!
IF VGM_65C02
	stz $fe40
ELSE
	lda #0
	sta $fe40
ENDIF
	pha
	pla ; 7 cycles, 2 bytes
	lda #$08
	sta $fe40 ;4+3+2+4+1(stretched)=14*2=28 PSG cycles ~WE was held low
ENDIF ; VGM_ENABLE_AUDIO
	rts
}
ENDIF

\\ call every 20ms with interrupts disabled
.vgm_poll_player
{
IF VGM_FX
IF VGM_65C02
	STZ vgm_player_reg_bits
ELSE
	LDA #0
	STA vgm_player_reg_bits
ENDIF
ENDIF
IF VGM_END_ALLOWED
	LDA vgm_player_ended
	BNE _sample_end
ENDIF
\\ <packets section>
\\  [byte] - indicating number of data writes within the current packet (max 11)
\\  [dd] ... - data
\\  [byte] - number of data writes within the next packet
\\  [dd] ... - data
\\  ...`
\\ <eof section>
\\  [0xff] - eof

	\\ Get next byte from the stream
	jsr exo_get_decrunched_byte
	bcs _player_end ; exo stream done?
	tay ; set flags
	beq wait_20_ms
IF VGM_EXO_EOF=0
	bmi _player_end
ENDIF
	ldy #255
	sty $fe43

	\\ Byte is #data bytes to send to sound chip:
	sta vgm_player_count
IF VGM_ENABLE_AUDIO
	bne _first ; always
ENDIF
.sound_data_loop
IF VGM_ENABLE_AUDIO
	sta $fe40 ; 2+6+3+4+1(stretched)=16*2=32 PSG clock cycles ~WE was held low
ENDIF
._first	jsr exo_get_decrunched_byte
	; if C is not clear here something's gone terribly wrong
IF VGM_FX
	JSR psg_decode
ENDIF
IF VGM_ENABLE_AUDIO
	sta $fe4f ; not $fe41!
IF VGM_65C02
	stz $fe40
ELSE
	lda #0
	sta $fe40
ENDIF
	lda #$08
ENDIF ; VGM_ENABLE_AUDIO
	dec vgm_player_count
	bne sound_data_loop
	clc
IF VGM_ENABLE_AUDIO
	sta $fe40 ; 2+6+2+4+2=16*2=32 PSG clock cycles ~WE was held low
ENDIF
.wait_20_ms
IF VGM_FRAME_COUNT
	INC vgm_player_counter	; indicate we have completed another frame of audio
	BNE no_carry
	INC vgm_player_counter+1
.no_carry
	CLC
ENDIF
IF (VGM_EXO_EOF=0) OR VGM_END_ALLOWED OR VGM_FRAME_COUNT OR VGM_DEINIT
	RTS
ENDIF
._player_end
IF VGM_DEINIT
	\\ Silence sound chip
	JSR vgm_deinit_player
ELSE
IF VGM_END_ALLOWED
	STA vgm_player_ended
ENDIF
ENDIF
IF VGM_FRAME_COUNT
	INC vgm_player_counter	; indicate we have completed one last frame of audio
	BNE _sample_end
	INC vgm_player_counter+1
ENDIF
._sample_end
IF (VGM_EXO_EOF=0) OR VGM_END_ALLOWED OR VGM_FRAME_COUNT
	SEC
ENDIF
	RTS
}

IF VGM_FX

.psg_decode
{
	STA vgm_player_data
	AND #&80	; bit 7 is a LATCH command if 1, DATA if 0
	BEQ second_byte

	\\ First byte

	\\ Obtain register fields
	
	\\ Get register from bits 7,6,5
	LDA vgm_player_data
	AND #&70 ; bits 6,5,4 are the register number
	LSR A:LSR A:LSR A:LSR A
	STA vgm_player_last_reg

	\\ Y is our register number
	TAY

	\\ Set bit field for each register used this frame
	LDA num_to_bit,Y				; look up bit for reg number
	ORA vgm_player_reg_bits				; mask in bit
	STA vgm_player_reg_bits

	\\ Is this tone or volume register?
	TYA
	AND #&01
	BEQ process_tone_data

	\\ Volume data
	LDA vgm_player_data
	AND #&0F ; volume is bottom 4 bits
	STA vgm_player_reg_vals,Y

	\\ Invert volume (0 = max 15 = off)
	SEC
	LDA #&0F ; max volume
	SBC vgm_player_reg_vals,Y
	STA vgm_player_reg_vals,Y
	JMP return

	\\ Frequency / tone data
	.process_tone_data
	CPY #&40 ; SN_REG_NOISE_CTRL				; Y already register number
	BNE tone_channel

	\\ Noise channel
	LDA vgm_player_data
	AND #&07 ;  (SN_NF_MASK OR SN_FB_MASK)		; store noise freq data
	STA vgm_player_reg_vals,Y

	JMP trigger_beat

	.tone_channel
	LDA vgm_player_data
	AND #&0f ; SN_FREQ_FIRST_BYTE_MASK		; F3 - F0
	LSR A: LSR A						; lose bottom 2 bits
	STA vgm_player_reg_vals,Y

	.trigger_beat
	\\ trigger the beat effect for this channel
	TYA:LSR A:TAY						; channel is register / 2
	LDA #9
	STA vgm_chan_array, Y

	BNE return ; always

	.second_byte
	LDA vgm_player_data
	AND #&3F; SN_FREQ_SECOND_BYTE_MASK		; F9 - F4
	STA vgm_tmp
	ASL A: ASL A						; put 6 bits to top of byte
	LDY vgm_player_last_reg
	ORA vgm_player_reg_vals,Y				; combine with bottom 2 bits
	STA vgm_player_reg_vals,Y

	\\ trigger the beat effect for this channel
; technically correct, but better visuals without this.
;	TYA:LSR A:TAY						; channel is register / 2
;	LDA #9
;	STA vgm_chan_array, Y

	LDA vgm_tmp
IF VGM_FX_num_freqs == 16
	\\ 16 frequency bars, so use top 4 bits
	LSR A : LSR A
ELSE
	\\ 32 frequency bars, so use top 5 bits
	LSR A
ENDIF
	
	\\ clamp final frequency to array range and invert 
	AND #VGM_FX_num_freqs-1
	STA vgm_tmp
	LDA #VGM_FX_num_freqs-1
	SEC
	SBC vgm_tmp
	TAX
	LDA #15
	STA vgm_freq_array,X

.return
	LDA vgm_player_data
	RTS
}

ENDIF ; VGM_FX

.vgm_player_end

