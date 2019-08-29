
\ ******************************************************************
\ *	Exomiser (decompression library)
\ ******************************************************************
EXO_65C02=TRUE
IF EXO_65C02
	CPU 1
ENDIF
.exo_start

\ ******************************************************************
\ *	Space reserved for runtime buffers not preinitialised
\ ******************************************************************

\\ Compress data using the streamed option:
\\ exomizer.exe raw -c -m <buffersize, e.g. 1024> <file.raw> -o <file.exo>
\\ where bufferSize is the compression buffer size, ie EXO_buffer_len.
\\ A larger buffer gives better compression.

EXO_buffer_end = EXO_buffer_start + EXO_buffer_len

; -------------------------------------------------------------------
; this 156 byte table area may be relocated. It may also be clobbered
; by other data between decrunches.
; -------------------------------------------------------------------

EXO_TABL_SIZE = 156
exo_tabl_bi = EXO_table

exo_tabl_lo = exo_tabl_bi + 52
exo_tabl_hi = exo_tabl_bi + 104

; -------------------------------------------------------------------
; Fetch byte from an exomiser compressed data stream
; for this exo_get_crunched_byte routine to work the crunched data has to be
; crunced using the -m <buffersize> and possibly the -l flags. Any other
; flag will just mess things up.
IF INLINE_GET_CRUNCHED_BYTE
IF EXO_65C02=0
ERROR "Nope"
ENDIF	
EXO_crunch_byte_lo = EXO_zp_src_ptr_lo
EXO_crunch_byte_hi = EXO_zp_src_ptr_hi
MACRO get_crunched_byte
{
	lda (EXO_zp_src_ptr_lo)
	inc EXO_zp_src_ptr_lo
	bne _nocarry
	inc EXO_zp_src_ptr_hi
._nocarry
}
ENDMACRO
ELSE
	
.exo_get_crunched_byte
{

._byte
	lda &ffff ; EXO data stream address	; **SELF-MODIFIED CODE**
_byte_lo = _byte + 1
_byte_hi = _byte + 2

	\\ advance input stream memory address
	INC _byte_lo
	bne _byte_skip_hi
	INC _byte_hi			; forward decrunch
._byte_skip_hi:

	rts						; decrunch_file is called.
}
EXO_crunch_byte_lo = exo_get_crunched_byte + 1
EXO_crunch_byte_hi = exo_get_crunched_byte + 2

MACRO get_crunched_byte
	jsr exo_get_crunched_byte
ENDMACRO
ENDIF
	
; -------------------------------------------------------------------
	
MACRO exo_bit_get_bit1
{	
	lsr EXO_zp_bitbuf
	bne _bit_ok
	get_crunched_byte
	ror a
	sta EXO_zp_bitbuf
._bit_ok
}
ENDMACRO

; -------------------------------------------------------------------
; jsr this label to init the decruncher, it will init used zeropage
; zero page locations and the decrunch tables
; no constraints on register content, however the
; decimal flag has to be #0 (it almost always is, otherwise do a cld)
; X/Y contains address of EXO crunched data stream
; -------------------------------------------------------------------
.exo_init_decruncher				; pass in address of (crunched data-1) in X,Y
{
	stx EXO_crunch_byte_lo
	sty EXO_crunch_byte_hi

	get_crunched_byte
	sta EXO_zp_bitbuf

	ldx #0
	stx EXO_zp_dest_lo
	stx EXO_zp_dest_hi
	stx EXO_zp_len_lo
	stx EXO_zp_len_hi
	ldy #0
; -------------------------------------------------------------------
; calculate tables (49 bytes)
; x and y must be #0 when entering
;
._init_nextone
	inx
	tya
	and #$0f
	beq _init_shortcut		; starta p� ny sekvens

	txa			; this clears reg a
	lsr a			; and sets the carry flag
	ldx EXO_zp_bits_lo
._init_rolle
	rol a
	rol EXO_zp_bits_hi
	dex
	bpl _init_rolle		; c = 0 after this (rol EXO_zp_bits_hi)

	adc exo_tabl_lo-1,y
	tax

	lda EXO_zp_bits_hi
	adc exo_tabl_hi-1,y
._init_shortcut
	sta exo_tabl_hi,y
	txa
	sta exo_tabl_lo,y

	ldx #4
	jsr exo_bit_get_bits		; clears x-reg.
	sta exo_tabl_bi,y
	iny
	cpy #52
	bne _init_nextone
}
\\ Fall through!	

._do_exit
	rts

; -------------------------------------------------------------------
; decrunch one byte
;

{
; -------------------------------------------------------------------
; count zero bits + 1 to get length table index (10 bytes)
; y = x = 0 when entering
;
._get_sequence
._seq_next1
	iny
	exo_bit_get_bit1
	bcc _seq_next1
	cpy #$11
	bcc _seq2
	rts
.*exo_get_decrunched_byte
	ldy EXO_zp_len_lo
IF 0
	beq _not_do_sequence
	jmp _do_sequence
._not_do_sequence
ELSE	
	bne _do_sequence
ENDIF
	ldx EXO_zp_len_hi
	bne _do_sequence2

	exo_bit_get_bit1
	bcc _get_sequence
; -------------------------------------------------------------------
; literal handling (13 bytes)
;	
	get_crunched_byte
IF 0
	jmp _do_literal
ELSE
	bcs _do_literal ; always
ENDIF
._seq2
; -------------------------------------------------------------------
; calulate length of sequence (zp_len) (17 bytes)
;
	ldx exo_tabl_bi - 1,y
	jsr exo_bit_get_bits
	adc exo_tabl_lo - 1,y
	sta EXO_zp_len_lo
	lda EXO_zp_bits_hi
	adc exo_tabl_hi - 1,y
	sta EXO_zp_len_hi
; -------------------------------------------------------------------
; here we decide what offset table to use (20 bytes)
; x is 0 here
;
	bne _seq_nots123
	ldy EXO_zp_len_lo
	cpy #$04
	bcc _seq_size123
._seq_nots123
	ldy #$03
._seq_size123
	ldx exo_tabl_bit - 1,y
	jsr exo_bit_get_bits
	adc exo_tabl_off - 1,y
	tay
; -------------------------------------------------------------------
; calulate absolute offset (zp_src) (27 bytes)
;
	ldx exo_tabl_bi,y
	jsr exo_bit_get_bits
	adc exo_tabl_lo,y
	bcc _seq_skipcarry
	inc EXO_zp_bits_hi
	clc
._seq_skipcarry
	adc EXO_zp_dest_lo
	sta EXO_zp_src_lo
	lda EXO_zp_bits_hi
	adc exo_tabl_hi,y
	adc EXO_zp_dest_hi
; -------------------------------------------------------------------
	cmp #HI(EXO_buffer_len)
	bcc _seq_offset_ok
	sbc #HI(EXO_buffer_len)
	clc
; -------------------------------------------------------------------
._seq_offset_ok
	sta EXO_zp_src_hi
	adc #HI(EXO_buffer_start)
	sta EXO_zp_src_bi
._do_sequence
IF EXO_65C02=0
	ldy #0
ENDIF
._do_sequence2
	ldx EXO_zp_len_lo
	bne _seq_len_dec_lo
	dec EXO_zp_len_hi
._seq_len_dec_lo
	dec EXO_zp_len_lo
; -------------------------------------------------------------------
	ldx EXO_zp_src_lo
	bne _seq_src_dec_lo
	ldx EXO_zp_src_hi
	bne _seq_src_dec_hi
; ------- handle buffer wrap problematics here ----------------------
IF 1
	ldx #HI(EXO_buffer_len-$100)
	stx EXO_zp_src_hi
	ldx #HI(EXO_buffer_end-$100)
	stx EXO_zp_src_bi
	bne _seq_src_dec_lo ; always
ELSE
	ldx #HI(EXO_buffer_len)
	stx EXO_zp_src_hi
	ldx #HI(EXO_buffer_end)
	stx EXO_zp_src_bi
ENDIF
; -------------------------------------------------------------------
._seq_src_dec_hi
	dec EXO_zp_src_hi
	dec EXO_zp_src_bi
._seq_src_dec_lo
	dec EXO_zp_src_lo
; -------------------------------------------------------------------
IF EXO_65C02
	lda (EXO_zp_src_lo)
ELSE
	lda (EXO_zp_src_lo),y
ENDIF
; -------------------------------------------------------------------
._do_literal
	ldx EXO_zp_dest_lo
	bne _seq_dest_dec_lo
	ldx EXO_zp_dest_hi
	bne _seq_dest_dec_hi
; ------- handle buffer wrap problematics here ----------------------
IF 1
	ldx #HI(EXO_buffer_len-$100)
	stx EXO_zp_dest_hi
	ldx #HI(EXO_buffer_end-$100)
	stx EXO_zp_dest_bi
	bne _seq_dest_dec_lo ; always
ELSE
	ldx #HI(EXO_buffer_len)
	stx EXO_zp_dest_hi
	ldx #HI(EXO_buffer_end)
	stx EXO_zp_dest_bi
ENDIF
; -------------------------------------------------------------------
._seq_dest_dec_hi
	dec EXO_zp_dest_hi
	dec EXO_zp_dest_bi
._seq_dest_dec_lo
	dec EXO_zp_dest_lo
; -------------------------------------------------------------------
IF EXO_65C02
	sta (EXO_zp_dest_lo)
ELSE
	sta (EXO_zp_dest_lo),y
ENDIF
	clc
	rts
}

; -------------------------------------------------------------------
; two small static tables (6 bytes)
;
.exo_tabl_bit
{
	EQUB 2,4,4
}
.exo_tabl_off
{
	EQUB 48,32,16
}

IF 0
; -------------------------------------------------------------------
; get x + 1 bits (1 byte)
;
.exo_bit_get_bit1
	inx
ENDIF
; -------------------------------------------------------------------
; get bits (31 bytes)
;
; args:
;   x = number of bits to get
; returns:
;   a = #bits_lo
;   x = #0
;   c = 0
;   EXO_zp_bits_lo = #bits_lo
;   EXO_zp_bits_hi = #bits_hi
; notes:
;   y is untouched
;   other status bits are set to (a == #0)
; -------------------------------------------------------------------
.exo_bit_get_bits
{
IF EXO_65C02
	stz EXO_zp_bits_lo
	stz EXO_zp_bits_hi
	beq _bit_bits_done2
ELSE
	beq _bit_bits_done2
	lda #$00
	sta EXO_zp_bits_lo
	sta EXO_zp_bits_hi
ENDIF
	;cpx #$01
	;bcc _bit_bits_done
	lda EXO_zp_bitbuf
._bit_bits_next
	lsr a
	bne _bit_ok
	get_crunched_byte
	ror a
._bit_ok
	rol EXO_zp_bits_lo
	rol EXO_zp_bits_hi
	dex
	bne _bit_bits_next
	sta EXO_zp_bitbuf
	lda EXO_zp_bits_lo
._bit_bits_done
	rts
._bit_bits_done2
	lda #$00
IF EXO_65C02=0
	sta EXO_zp_bits_lo
	sta EXO_zp_bits_hi
ENDIF
	rts

}

IF 0
.exo_bit_get_bit1_worko
{
	stz EXO_zp_bits_lo
	lda EXO_zp_bitbuf
._bit_bits_next
	lsr a
	bne _bit_ok
	jsr exo_get_crunched_byte
	ror a
._bit_ok
	sta EXO_zp_bitbuf
	rol EXO_zp_bits_lo
	;rol EXO_zp_bits_hi
	dex
	bpl _bit_bits_next
	lda EXO_zp_bits_lo
._bit_bits_done
	rts
}

.exo_bit_get_bit1_worko2
{
	lsr EXO_zp_bitbuf
	bne _bit_ok
	jsr exo_get_crunched_byte
	ror a
	sta EXO_zp_bitbuf
._bit_ok
	lda #0
	rol a
._bit_bits_done
	rts
}
ENDIF
; -------------------------------------------------------------------
; end of decruncher
; -------------------------------------------------------------------

.exo_end
