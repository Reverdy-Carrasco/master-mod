/* Made for OS 1.7.3 from the static LDR patches of master_final_v2: every address below is 1.7.3's.
 * The example pack `master-output`: fourteen small routines of ours that port master_final_v2 to open-field,
 * in one pack, minus the threshold change. Two places in `sub_8c0bb294` (MasterController input dispatch)
 * for the Master-page encoder remap and Shift-link redirect, and twelve places in the L1 compressor function
 * at 0x11a08350 for the L/R post-makeup. The four drive-stage thresholds are left at their stock ???6 dBFS value.
 *
 * None of the routines allocates, logs, or calls the firmware. The compressor routines use no P-register and
 * no stack: each ends in a hand-coded `JUMP.a` (eight-byte absolute) back to the next stock instruction
 * boundary. The two dispatch routines (DDR) jump to the stock targets `0x8c0bb354` (function exit) and
 * `0x8c0bb5e0` (Shift-link handler) through `P0.H/.L + JUMP(P0)` ??? those are the pack's local jumps, which
 * match the convention of other open-field features.
 */
.text
.align 2

/* ==================================================================
 * (A) MasterController input dispatch ??? two places in DDR
 * ==================================================================
 */

/* Entered by the jump the loader writes at 0x8c0bb5d4. Routes R7 in {6,7} to Shift-link, every other R7 to exit. */
.global op1f_master_shift_dispatch
.type op1f_master_shift_dispatch, STT_FUNC
op1f_master_shift_dispatch:
    R0 = 6 ;
    CC = R7 < R0 (IU) ;              /* R7 in {4,5} (stock Shift+bleu/ocre after Q2 remap) -> CC = 1 */
    IF CC JUMP master_to_exit ;
    R0 = 8 ;
    CC = R7 < R0 (IU) ;              /* R7 in {6,7} (Shift+gris/rouge after Q2 remap) -> CC = 1 */
    IF CC JUMP master_to_shift_link ;
    /* R7 >= 8: fall through to exit. */
master_to_exit:
    P0.H = 0x8c0b ;
    P0.L = 0xb354 ;                  /* the function's exit at 0x8c0bb354 */
    JUMP (P0) ;
master_to_shift_link:
    P0.H = 0x8c0b ;
    P0.L = 0xb5e0 ;                  /* the stock Shift-link handler at 0x8c0bb5e0 */
    JUMP (P0) ;
.size op1f_master_shift_dispatch, .-op1f_master_shift_dispatch

/* Entered by the jump the loader writes at 0x8c0bb63a. Toggles bit 1 of R7 and goes on through the room. */
.global op1f_master_bittgl
.type op1f_master_bittgl, STT_FUNC
op1f_master_bittgl:
    BITTGL (R7, 1) ;                 /* R7 ^= 2: bleu(0)<->gris(2) and ocre(1)<->rouge(3) */
    P0.H = op1f_master_bittgl_room ;
    P0.L = op1f_master_bittgl_room ;
    JUMP (P0) ;                      /* the displaced twelve bytes, then 0x8c0bb646 */
.size op1f_master_bittgl, .-op1f_master_bittgl

/* ==================================================================
 * (B) Master compressor tune ??? twelve places in L1
 * ==================================================================
 * Each routine emulates the patched bytes (byte-for-byte equivalent to master_final_v2 minus its threshold
 * change) and ends in a hand-coded `JUMP.a` back to the next stock instruction boundary. No P-register, no
 * stack: safe for the audio thread.
 */

/* --- (B.1) L/R pre-gain: swap one mul operand with R7 (~1.0), four sites --- */

.global op1f_master_pre_1
.type op1f_master_pre_1, STT_FUNC
op1f_master_pre_1:
    .short 0xc231; .short 0x2079   /* R1 = R7 * R1 (T) ; patched 69->79 */
    .short 0xc404; .short 0x6038   /* R0 = R7 - R0 (S) ; stock, kept */
    .short 0xdc00; .short 0x11a0; .short 0x8544; .short 0x0000  /* JUMP.a 0x11a08544 */
.size op1f_master_pre_1, .-op1f_master_pre_1

.global op1f_master_pre_2
.type op1f_master_pre_2, STT_FUNC
op1f_master_pre_2:
    .short 0xca31; .short 0x213d   /* R4 = R7 * R5 (T) + parallel slot 1 : patched 35->3d */
    .short 0xbbc3; .short 0xb9f5   /* [FP - 0x10] = R3 || R5 = [FP - 0x4] ; stock slaves */
    .short 0xdc00; .short 0x11a0; .short 0x8604; .short 0x0000  /* JUMP.a 0x11a08604 */
.size op1f_master_pre_2, .-op1f_master_pre_2

.global op1f_master_pre_3
.type op1f_master_pre_3, STT_FUNC
op1f_master_pre_3:
    .short 0xca31; .short 0x20ba   /* R2 = R7 * R2 (T) + parallel : patched 82->ba */
    .short 0xb9c0; .short 0x0000   /* R0 = [FP - 0x10] || NOP ; stock slaves */
    .short 0xdc00; .short 0x11a0; .short 0x86e2; .short 0x0000  /* JUMP.a 0x11a086e2 */
.size op1f_master_pre_3, .-op1f_master_pre_3

.global op1f_master_pre_4
.type op1f_master_pre_4, STT_FUNC
op1f_master_pre_4:
    .short 0xca31; .short 0x217c   /* R5 = R7 * R4 (T) + parallel : patched 54->7c */
    .short 0xa374; .short 0x0000   /* R4 = [SP + 0x34] || NOP ; stock slaves */
    .short 0xdc00; .short 0x11a0; .short 0x87d2; .short 0x0000  /* JUMP.a 0x11a087d2 */
.size op1f_master_pre_4, .-op1f_master_pre_4

/* --- (B.2) L/R post-15 LDI replacements, four sites --- */

.global op1f_master_post_ldi_1
.type op1f_master_post_ldi_1, STT_FUNC
op1f_master_post_ldi_1:
    .short 0xb9c3                  /* R3 = [FP - 0x10] */
    .short 0xc231; .short 0x20eb   /* R3 = R5 * R3 (T) */
    .short 0x0000                  /* NOP */
    .short 0xdc00; .short 0x11a0; .short 0x85ba; .short 0x0000  /* JUMP.a 0x11a085ba */
.size op1f_master_post_ldi_1, .-op1f_master_post_ldi_1

.global op1f_master_post_ldi_2
.type op1f_master_post_ldi_2, STT_FUNC
op1f_master_post_ldi_2:
    .short 0xc231; .short 0x2096   /* R2 = R2 * R6 (T) */
    .short 0xc682; .short 0x07fa   /* R3 = R2 >>> 1 */
    .short 0xdc00; .short 0x11a0; .short 0x867e; .short 0x0000  /* JUMP.a 0x11a0867e */
.size op1f_master_post_ldi_2, .-op1f_master_post_ldi_2

.global op1f_master_post_ldi_3
.type op1f_master_post_ldi_3, STT_FUNC
op1f_master_post_ldi_3:
    .short 0xb9d3                  /* R3 = [FP - 0xc] */
    .short 0xc231; .short 0x20e3   /* R3 = R4 * R3 (T) */
    .short 0x0000                  /* NOP */
    .short 0xdc00; .short 0x11a0; .short 0x8744; .short 0x0000  /* JUMP.a 0x11a08744 */
.size op1f_master_post_ldi_3, .-op1f_master_post_ldi_3

.global op1f_master_post_ldi_4
.type op1f_master_post_ldi_4, STT_FUNC
op1f_master_post_ldi_4:
    .short 0xc231; .short 0x20da   /* R3 = R3 * R2 (T) */
    .short 0xc682; .short 0x0bfb   /* R5 = R3 >>> 1 */
    .short 0xdc00; .short 0x11a0; .short 0x8844; .short 0x0000  /* JUMP.a 0x11a08844 */
.size op1f_master_post_ldi_4, .-op1f_master_post_ldi_4

/* --- (B.3) L/R post-15 short (4+4), two sites --- */

.global op1f_master_post_s_1
.type op1f_master_post_s_1, STT_FUNC
op1f_master_post_s_1:
    .short 0xc682; .short 0x0bfb   /* R5 = R3 >>> 1 ; patched */
    .short 0xc404; .short 0x2c26   /* R6 = R4 + R6 (S) ; stock, kept */
    .short 0xdc00; .short 0x11a0; .short 0x85c2; .short 0x0000  /* JUMP.a 0x11a085c2 */
.size op1f_master_post_s_1, .-op1f_master_post_s_1

.global op1f_master_post_s_2
.type op1f_master_post_s_2, STT_FUNC
op1f_master_post_s_2:
    .short 0x0000; .short 0x0000   /* NOP NOP ; patched (drive-4 mul zeroed) */
    .short 0xc404; .short 0x2231   /* R1 = R6 + R1 (S) ; stock, kept */
    .short 0xdc00; .short 0x11a0; .short 0x8856; .short 0x0000  /* JUMP.a 0x11a08856 */
.size op1f_master_post_s_2, .-op1f_master_post_s_2

/* --- (B.4) L/R post-15 extended (4 patched + 8 stock bundle), two sites --- */

.global op1f_master_post_x_1
.type op1f_master_post_x_1, STT_FUNC
op1f_master_post_x_1:
    .short 0x0000; .short 0x0000   /* NOP NOP ; patched (drive-2 output mul zeroed) */
    .short 0xcc04; .short 0x2221   /* R1 = R4 + R1 (S) + parallel : stock bundle, kept */
    .short 0xa0bc; .short 0x0000   /* R4 = [FP + 0x8] || NOP ; stock slaves, kept */
    .short 0xdc00; .short 0x11a0; .short 0x8694; .short 0x0000  /* JUMP.a 0x11a08694 */
.size op1f_master_post_x_1, .-op1f_master_post_x_1

.global op1f_master_post_x_2
.type op1f_master_post_x_2, STT_FUNC
op1f_master_post_x_2:
    .short 0xc682; .short 0x09fb   /* R4 = R3 >>> 1 ; patched (drive-3 output mul becomes shift) */
    .short 0xce82; .short 0x4408   /* R2 = R0 << 1 (S) + parallel : stock bundle, kept */
    .short 0xa0f8; .short 0x0000   /* R0 = [FP + 0xc] || NOP ; stock slaves, kept */
    .short 0xdc00; .short 0x11a0; .short 0x8758; .short 0x0000  /* JUMP.a 0x11a08758 */
.size op1f_master_post_x_2, .-op1f_master_post_x_2

/* --- The one trampoline room (BSS) used by op1f_master_bittgl --- */
.section .bss
.balign 4
.global op1f_master_bittgl_room
.type op1f_master_bittgl_room, STT_OBJECT
op1f_master_bittgl_room:
    .space 20
.size op1f_master_bittgl_room, .-op1f_master_bittgl_room

/* --- Minimal frame function (required by card level 1) --- */
.text
.align 2
.global master_mod_frame
.type master_mod_frame, STT_FUNC
master_mod_frame:
    RTS;
.size master_mod_frame, .-master_mod_frame
