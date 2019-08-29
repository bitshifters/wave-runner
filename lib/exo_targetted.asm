; -------------------------------------------------------------------
; Controls if the shared get_bits routines should be inlined or not.
INLINE_GET_BITS=1
; -------------------------------------------------------------------
; if literal sequences is not used (the data was crunched with the -c
; flag) then the following line can be uncommented for shorter and.
; slightly faster code.
LITERAL_SEQUENCES_NOT_USED = 1
; -------------------------------------------------------------------
; if the sequence length is limited to 256 (the data was crunched with
; the -M256 flag) then the following line can be uncommented for
; shorter and slightly faster code.
MAX_SEQUENCE_LENGTH_256 = 1

EXO_TGT_decrunch_table = $101 ; yes! we have enough stack space to use page 1 here
;.EXO_TGT_decrunch_table SKIP 156
	
EXO_TGT_tabl_bi = EXO_TGT_decrunch_table
EXO_TGT_tabl_lo = EXO_TGT_decrunch_table + 52
EXO_TGT_tabl_hi = EXO_TGT_decrunch_table + 104

MACRO mac_get_crunched_byte
{
	LDA (EXO_TGT_inpos)
	inc EXO_TGT_inpos
	bne skip
	inc EXO_TGT_inpos+1
	.skip
}
ENDMACRO

;; refill bits is always inlined
MACRO mac_refill_bits
        pha
        mac_get_crunched_byte
        rol a
        sta EXO_TGT_zp_bitbuf
        pla
ENDMACRO

IF INLINE_GET_BITS
MACRO mac_get_bits
{
        adc #$80                ; needs c=0, affects v
        asl a
        bpl gb_skip
.gb_next
        asl EXO_TGT_zp_bitbuf
        bne gb_ok
        mac_refill_bits
.gb_ok
        rol a
        bmi gb_next
.gb_skip
        bvc skip
.gb_get_hi
        sec
        sta EXO_TGT_zp_bits_hi
        mac_get_crunched_byte
.skip
}
ENDMACRO
ELSE
MACRO mac_get_bits
        jsr get_bits
ENDMACRO
.get_bits
        adc #$80                ; needs c=0, affects v
        asl a
        bpl gb_skip
.gb_next
        asl EXO_TGT_zp_bitbuf
        bne gb_ok
        mac_refill_bits
.gb_ok
        rol a
        bmi gb_next
.gb_skip
        bvs gb_get_hi
        rts
.gb_get_hi
        sec
        sta EXO_TGT_zp_bits_hi
        mac_get_crunched_byte
	rts
ENDIF
; -------------------------------------------------------------------
; no code below this comment has to be modified in order to generate
; a working decruncher of this source file.
; However, you may want to relocate the tables last in the file to a
; more suitable address.
; -------------------------------------------------------------------

; -------------------------------------------------------------------
; jsr this label to decrunch, it will in turn init the tables and
; call the decruncher
; no constraints on register content, however the
; decimal flag has to be #0 (it almost always is, otherwise do a cld)
.EXO_TGT_decrunch
; -------------------------------------------------------------------
; init zeropage, x and y regs. (12 bytes)
{
	stx EXO_TGT_inpos
        sty EXO_TGT_inpos+1
        ldy #0
        ldx #3
.init_zp
        mac_get_crunched_byte
        sta EXO_TGT_zp_bitbuf - 1,x
        dex
        bne init_zp
; -------------------------------------------------------------------
; calculate tables (62 bytes) + get_bits macro
; x and y must be #0 when entering
;
        clc
.table_gen
        tax
        tya
        and #$0f
        sta EXO_TGT_tabl_lo,y
        beq shortcut            ; start a new sequence
; -------------------------------------------------------------------
        txa
        adc EXO_TGT_tabl_lo - 1,y
        sta EXO_TGT_tabl_lo,y
        lda EXO_TGT_zp_len_hi
        adc EXO_TGT_tabl_hi - 1,y
.shortcut
        sta EXO_TGT_tabl_hi,y
; -------------------------------------------------------------------
        lda #$01
        sta <EXO_TGT_zp_len_hi
        lda #$78                ; %01111000
        mac_get_bits
; -------------------------------------------------------------------
        lsr a
        tax
        beq rolled
        php
.rolle
        asl EXO_TGT_zp_len_hi
        sec
        ror a
        dex
        bne rolle
        plp
.rolled
        ror a
        sta EXO_TGT_tabl_bi,y
        bmi no_fixup_lohi
        lda EXO_TGT_zp_len_hi
        stx EXO_TGT_zp_len_hi
        equb $24
.no_fixup_lohi
        txa
; -------------------------------------------------------------------
        iny
        cpy #52
        bne table_gen
; -------------------------------------------------------------------
; prepare for main decruncher
        ldy EXO_TGT_zp_dest_lo
        stx EXO_TGT_zp_dest_lo
        stx EXO_TGT_zp_bits_hi
; -------------------------------------------------------------------
; copy one literal byte to destination (11 bytes)
;
.literal_start1
        tya
        bne no_hi_decr
        dec EXO_TGT_zp_dest_hi
.no_hi_decr
        dey
        mac_get_crunched_byte
        sta (EXO_TGT_zp_dest_lo),y
; -------------------------------------------------------------------
; fetch sequence length index (15 bytes)
; x must be #0 when entering and contains the length index + 1
; when exiting or 0 for literal byte
.next_round
        dex
        lda EXO_TGT_zp_bitbuf
.no_literal1
        asl a
        bne nofetch8
        mac_get_crunched_byte
        rol a
.nofetch8
        inx
        bcc no_literal1
        sta EXO_TGT_zp_bitbuf
; -------------------------------------------------------------------
; check for literal byte (2 bytes)
;
        beq literal_start1
; -------------------------------------------------------------------
; check for decrunch done and literal sequences (4 bytes)
;
        cpx #$11
IF INLINE_GET_BITS
        bcc skip_jmp
        jmp exit_or_lit_seq
.skip_jmp
ELSE
        bcs exit_or_lit_seq
ENDIF
; -------------------------------------------------------------------
; calulate length of sequence (zp_len) (18(11) bytes) + get_bits macro
;
        lda EXO_TGT_tabl_bi - 1,x
        mac_get_bits
        adc EXO_TGT_tabl_lo - 1,x       ; we have now calculated EXO_TGT_zp_len_lo
        sta EXO_TGT_zp_len_lo
IF MAX_SEQUENCE_LENGTH_256
        tax
ELSE
        lda EXO_TGT_zp_bits_hi
        adc EXO_TGT_tabl_hi - 1,x       ; c = 0 after this.
        sta EXO_TGT_zp_len_hi
; -------------------------------------------------------------------
; here we decide what offset table to use (27(26) bytes) + get_bits_nc macro
; z-flag reflects EXO_TGT_zp_len_hi here
;
        ldx EXO_TGT_zp_len_lo
ENDIF
        lda #$e1
        cpx #$03
        bcs gbnc2_next
        lda tabl_bit,x
.gbnc2_next
        asl EXO_TGT_zp_bitbuf
        bne gbnc2_ok
        tax
        mac_get_crunched_byte
        rol a
        sta EXO_TGT_zp_bitbuf
        txa
.gbnc2_ok
        rol a
        bcs gbnc2_next
        tax
; -------------------------------------------------------------------
; calulate absolute offset (zp_src) (21 bytes) + get_bits macro
;
IF MAX_SEQUENCE_LENGTH_256=0
        lda #0
        sta EXO_TGT_zp_bits_hi
ENDIF
        lda EXO_TGT_tabl_bi,x
        mac_get_bits
        adc EXO_TGT_tabl_lo,x
        sta EXO_TGT_zp_src_lo
        lda EXO_TGT_zp_bits_hi
        adc EXO_TGT_tabl_hi,x
        adc EXO_TGT_zp_dest_hi
        sta EXO_TGT_zp_src_hi
; -------------------------------------------------------------------
; prepare for copy loop (2 bytes)
;
.pre_copy
        ldx EXO_TGT_zp_len_lo
; -------------------------------------------------------------------
; main copy loop (30 bytes)
;
.copy_next
        tya
        bne copy_skip_hi
        dec EXO_TGT_zp_dest_hi
        dec EXO_TGT_zp_src_hi
.copy_skip_hi
        dey
IF LITERAL_SEQUENCES_NOT_USED=0
        bcs get_literal_byte
ENDIF
        lda (EXO_TGT_zp_src_lo),y
.literal_byte_gotten
        sta (EXO_TGT_zp_dest_lo),y
        dex
        bne copy_next
IF MAX_SEQUENCE_LENGTH_256=0
        lda EXO_TGT_zp_len_hi
IF INLINE_GET_BITS
        bne copy_next_hi
ENDIF
ENDIF
.begin_stx
        stx EXO_TGT_zp_bits_hi
IF INLINE_GET_BITS=0
        beq next_round
ELSE
        jmp next_round
ENDIF
IF MAX_SEQUENCE_LENGTH_256=0
.copy_next_hi
        dec EXO_TGT_zp_len_hi
        jmp copy_next
ENDIF
IF LITERAL_SEQUENCES_NOT_USED=0
.get_literal_byte
        mac_get_crunched_byte
        bcs literal_byte_gotten
ENDIF
; -------------------------------------------------------------------
; exit or literal sequence handling (16(12) bytes)
;
.exit_or_lit_seq
IF LITERAL_SEQUENCES_NOT_USED=0
        beq decr_exit
        mac_get_crunched_byte
IF MAX_SEQUENCE_LENGTH_256=0
        sta EXO_TGT_zp_len_hi
ENDIF
        mac_get_crunched_byte
        tax
        bcs copy_next
.decr_exit
ENDIF
        rts
; -------------------------------------------------------------------
; the static stable used for bits+offset for lengths 3, 1 and 2 (3 bytes)
; bits 4, 2, 4 and offsets 16, 48, 32
; -------------------------------------------------------------------
; end of decruncher
; -------------------------------------------------------------------
.tabl_bit
 equb %11100001, %10001100, %11100010
}

