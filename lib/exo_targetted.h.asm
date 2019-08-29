; -*- mode:beebasm -*-

; -------------------------------------------------------------------
; zero page addresses used
; -------------------------------------------------------------------

.EXO_TGT_zp_len_lo SKIP 1
.EXO_TGT_zp_len_hi SKIP 1

.EXO_TGT_zp_src_lo SKIP 1
.EXO_TGT_zp_src_hi SKIP 1

.EXO_TGT_zp_bits_hi SKIP 1
;;; EXO_TGT_zp_bits_hi needs leaving spare!!!!

.EXO_TGT_zp_bitbuf SKIP 1
.EXO_TGT_zp_dest_lo SKIP 1      ; dest addr lo
.EXO_TGT_zp_dest_hi SKIP 1      ; dest addr hi

.EXO_TGT_inpos SKIP 2

.EXO_TGT_request_address_lo SKIP 1
.EXO_TGT_request_address_hi SKIP 1
.EXO_TGT_request_pending SKIP 1
.EXO_TGT_is_decrunching SKIP 1
.EXO_TGT_SWR_bank SKIP 1
.EXO_TGT_shadow_control SKIP 1
.EXO_TGT_decrunch_start_frameCount SKIP 2
.EXO_TGT_last_decrunch_num_frames SKIP 2
