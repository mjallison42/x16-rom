; ROM banks
BANK_KERNAL  = 0
BANK_KEYBD   = 1
BANK_CBDOS   = 2
BANK_GEOS    = 3
BANK_BASIC   = 4
BANK_MONITOR = 5
BANK_CHARSET = 6
BANK_CODEX   = 7

; XXX these constant RAM addresses are KERNAL
; XXX implementation details and need to go away!
.ifdef MACHINE_X16
cbdos_flags= $026A
status     = $0289 ; channel: status byte
jsrfar3    = $02c4 ; jsrfar: RAM part
jmpfr      = $02df ; jsrfar: core jmp instruction
imparm     = $82   ; jsrfar: temporary byte
stavec     = $03b2 ; stash: argument
banked_irq = $038b ; irq handler: RAM part
.elseif .defined(MACHINE_C64)
status     = $029F
;fa         = $029F
imparm     = $E2
.endif

; RAM banks
; 0:   KVARS
; 1-9: GEOS BG SCREEN (320x200) [not currently enabled]
; 255: CBDOS

.ifdef MACHINE_X16

.macro KVARS_START
.import kvswitch_tmp1, kvswitch_tmp2
	php
	sei
	sta kvswitch_tmp1
	pla
	sta kvswitch_tmp2
	lda ram_bank
	pha
	stz ram_bank
	lda kvswitch_tmp2
	pha
	lda kvswitch_tmp1
	plp
.endmacro

.macro KVARS_END
	php
	sei
	sta kvswitch_tmp1
	pla
	sta kvswitch_tmp2
	pla
	sta ram_bank
	lda kvswitch_tmp2
	pha
	lda kvswitch_tmp1
	plp
.endmacro

.macro KVARS_START_TRASH_A_NZ
.import kvswitch_tmp1, kvswitch_tmp2
	lda ram_bank
	pha
	stz ram_bank
.endmacro

.macro KVARS_END_TRASH_A_NZ
	pla
	sta ram_bank
.endmacro

.macro KVARS_START_TRASH_X_NZ
.import kvswitch_tmp1, kvswitch_tmp2
	ldx ram_bank
	phx
	stz ram_bank
.endmacro

.macro KVARS_END_TRASH_X_NZ
	plx
	stx ram_bank
.endmacro

; Warning: KVARS_START_TRASH_NZ and KVARS_END_TRASH_NZ can cause a race
; condition if interrupts are enabled.
.macro KVARS_START_TRASH_NZ
.import kvswitch_tmp1, kvswitch_tmp2
	sta kvswitch_tmp1
	lda ram_bank
	pha
	stz ram_bank
	lda kvswitch_tmp1
.endmacro

.macro KVARS_END_TRASH_NZ
	sta kvswitch_tmp1
	pla
	sta ram_bank
	lda kvswitch_tmp1
.endmacro

.else ; C64

.macro KVARS_START
.endmacro

.macro KVARS_END
.endmacro

.endif
