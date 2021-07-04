	;;
	;; Commander 16 CodeX Interactive Assembly Environment
	;; Symbol debugger tool.
	;; 
	;;    Copyright 2020 Michael J. Allison
	;; 
	;;    Redistribution and use in source and binary forms, with or without
	;;    modification, are permitted provided that the following conditions are met:
	;;
	;; 1. Redistributions of source code must retain the above copyright notice,
	;; this list of conditions and the following disclaimer.
	;;
	;; 2. Redistributions in binary form must reproduce the above copyright notice,
	;; this list of conditions and the following disclaimer in the documentation
	;; and/or other materials provided with the distribution.
	;; 
	;;	
	;;    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
	;; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
	;; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
	;; PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
	;; CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
	;; EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
	;; PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
	;; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
	;; WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	;; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
	;; POSSIBILITY OF SUCH DAMAGE.

	.psc02                    ; Enable 65c02 instructions
	.feature labels_without_colons

	COL_INST_BYTES=8          ;; Column to start printing the instruction bytes
	COL_INSTRUCTION=17        ;; Column to start printing instruction
	COL_ARGUMENTS=COL_INSTRUCTION + 7

	ROW_MAX = 59

	ROW_FIRST_INSTRUCTION=3   ;; First row to display instructions
	ROW_LAST_INSTRUCTION=ROW_MAX - 4

	DBG_BOX_WIDTH=18          ;; Registers, breakpoints, watch locations
	DBG2_BOX_WIDTH=12         ;; Stack, Zero page registers

	ASSY_LAST_COL=50
	SIDE_BAR_X = ASSY_LAST_COL

	STACK_COL = SIDE_BAR_X + DBG_BOX_WIDTH
	STACK_ROW = DATA_ROW
	STACK_BOX_HEIGHT = 20
	
	REGISTER_COL = SIDE_BAR_X + 6
	REGISTER_ROW = STACK_ROW
	REGISTER_BOX_HEIGHT = 20
	
	PSR_COL = SIDE_BAR_X
	PSR_ROW = REGISTER_ROW + REGISTER_BOX_HEIGHT 
	PSR_BOX_HEIGHT = 15
	PSR_BOX_WIDTH = 15
	
	WATCH_COL = SIDE_BAR_X
	WATCH_ROW = PSR_ROW + PSR_BOX_HEIGHT 
	WATCH_BOX_HEIGHT = 20
	WATCH_BOX_WIDTH = DBG_BOX_WIDTH + DBG2_BOX_WIDTH
	
	VERA_COL = PSR_COL + PSR_BOX_WIDTH
	VERA_ROW = PSR_ROW
	VERA_BOX_WIDTH = 15
	VERA_BOX_HEIGHT = PSR_BOX_HEIGHT

	MEM_NUMBER_OF_BYTES=$10

;;      R0 - Parameters, saved in routines
;;      R1 - Parameters, saved in routines
;;      R2 - Parameters, saved in routines
;;      R3 - Parameters, saved in routines
;;      R4 - Parameters, saved in routines
;;      R5 - Parameters, saved in routines
	
;;      R6
;;      R7
;;      R8
;;      R9
;;      R10 - decoded_str
	
;;      R11 - scratch, not saved
;;      R12 - scratch, not saved
;;      R13 - scratch, not saved
;;      R14 - scratch, not saved
;;      R15 - scratch, not saved

;;      x16 - SCR_COL, SCR_ROW
;;      x17 - ERR_MSG, pointer to error string
;;      x18
;;      x19
;;      x20
	
	.code
	             
	.include "bank.inc"
	.include "cx_vecs.inc"
	.include "screen.inc"
	.include "bank_assy.inc"
	.include "petsciitoscr.inc"
	.include "screen.inc"
	.include "utility.inc"
	.include "kvars.inc"
	.include "x16_kernal.inc"
	.include "vera.inc"

	.include "bank_assy_vars.inc"
	.include "screen_vars.inc"
	.include "dispatch_vars.inc"
	.include "decoder_vars.inc"
	.include "encode_vars.inc"
	.include "cx_vars.inc"
	
	.include "decoder.inc"
	.include "dispatch.inc"
	.include "meta.inc"
	.include "meta_i.inc"
	.include "fio.inc"

;;
;; Main mode display dispatchers
;;
;; Read keys, dispatch based on function key pressed.
;; Since these are relatively short (right now), they are
;; hard coded. Should the volume of these grow too much
;; a data driven (table) version can be coded.
;;
;; Main loop, and dispatch
;; 
	.proc main
;;; -------------------------------------------------------------------------------------
	.code

	.export main_entry
	
main_entry: 
	lda     orig_color
	sta     K_TEXT_COLOR

;	callR1   print_header,view_symbol_header

	jsr     clear_content
	
	lda      #DATA_ROW
	asl
	sta      r13L
	LoadW    r4,label_data_start

:
	lda     r13L
	
	cmp     #((LAST_ROW-4)*2) 
	bne     view_symbols_no_pause
	
	; Pause before showing next group
	callR1  wait_for_keypress,str_done
	jsr     clear_content
	lda     #DATA_ROW
	asl
	sta     r13L
	
view_symbols_no_pause
	lsr
	sta     SCR_ROW
	
	bcc     @view_col_0
 
@view_col_1
	lda     #(HDR_COL + 40)
	bra     @view_symbol_continue

@view_col_0
	lda     #HDR_COL

@view_symbol_continue
	sta     SCR_COL
	jsr     vera_goto
	
	jsr     view_symbol_prt_line
	bcs     view_symbols_exit
	
	inc     r13L

	bra     :-

view_symbols_exit
	callR1  wait_for_keypress,str_done_exit

	jsr     clear_content

	sec
	rts
	
;;
;; Print the next symbol to the screen
;; Input R4 - ptr to next entry	
;;
view_symbol_prt_line
	ifNe16  r4,selected_label,view_symbol_no_highlight
	lda     orig_color
	and     #$0F
	ora     #(COLOR_CDR_BACK_HIGHLIGHT << 4)
	sta     K_TEXT_COLOR
	bra     view_symbol_set_color

view_symbol_no_highlight
	lda     orig_color
view_symbol_set_color	
	sta     K_TEXT_COLOR

	jsr     vec_meta_get_label
	
	lda     r0L
	ora     r0H
	ora     r1L
	ora     r1H
	beq     view_symbol_prt_line_done

	PushW   r1             ; save string for later
	
	;; value
	ldx     r0H
	jsr     prthex
	ldx     r0L
	jsr     prthex

	;; spacer
	lda     #' '
	jsr     vera_out_a
	lda     #' '
	jsr     vera_out_a
	
	PopW    r1              ; restore string ptr to r1 (instead of original r0)
	jsr     prtstr
	
	;; point to next
	lda     #4
	clc
	adc     r4L
	sta     r4L
	bcc     :+
	inc     r4H
	
:
	clc
	rts

view_symbol_prt_line_done
	sec
	rts

;;
;; Create a new symbol value
;;
view_symbol_new
	rts
	
;;
;; Delete the selected symbol
;;
view_symbol_delete
	rts
	
;;
;; Edit the selected symbol
;;
view_symbol_edit
	rts
	
;;
;; Wait for a key press
;;
wait_for_keypress
	ldx      #HDR_COL
	ldy      #58
	lda      r1L
	ora      r1H
	beq      :+
	jsr      prtstr_at_xy
:  
	kerjsr   GETIN
	beq      wait_for_keypress
	rts
;;	
;;	Clear the area under the header
;;	
clear_content
	vgotoXY 0,HDR_ROW+3
	ldx     #80
	ldy     #57
	jsr     erase_box
	rts
	
	;; Constants
	
str_done:			.byte "PRESS ANY KEY TO CONTINUE: ", 0
str_done_exit:		.byte "PRESS ANY KEY TO EXIT: ", 0

;;; -------------------------------------------------------------------------------------
view_symbol_header   .byte " MEM  SCRN  SYMB                      BACK", 0
	
view_symbol_dispatch_table                
	.word   view_symbol_new    ; F1
	.word   view_symbol_edit   ; F3
	.word   0                  ; F5
	.word   0                  ; F7
	.word   view_symbol_delete ; F2
	.word   0                  ; F4
	.word   0                  ; F6

	;; Variables

selected_label:	.word $a012

	.endproc
