\\ ******************************************************************
\\ EXOMISER (compression library)
\\ ******************************************************************


\\ Declare ZP vars
.EXO_zp_src_hi	SKIP 1
.EXO_zp_src_lo	SKIP 1
.EXO_zp_src_bi	SKIP 1
.EXO_zp_bitbuf	SKIP 1

.EXO_zp_len_lo	SKIP 1
.EXO_zp_len_hi	SKIP 1

.EXO_zp_bits_lo	SKIP 1
.EXO_zp_bits_hi	SKIP 1

.EXO_zp_dest_hi	SKIP 1
.EXO_zp_dest_lo	SKIP 1	; dest addr lo
.EXO_zp_dest_bi	SKIP 1	; dest addr hi

INLINE_GET_CRUNCHED_BYTE=1
IF INLINE_GET_CRUNCHED_BYTE
.EXO_zp_src_ptr_lo	SKIP 1	; src addr lo
.EXO_zp_src_ptr_hi	SKIP 1	; src addr hi
ENDIF
