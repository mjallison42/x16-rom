; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Console I/O: LoadCharSet syscalls

.export GRAPH_set_font   ; [GEOS]

.export font_init

font_init:
	LoadB windowTop, 0
	LoadB windowBottom, SC_PIX_HEIGHT-1
	LoadW leftMargin, 0
	LoadW rightMargin, SC_PIX_WIDTH-1
	bra set_system_font

GRAPH_set_font:
	lda r0L
	ora r0H
	bne set_font2
set_system_font:
	LoadW r0, SystemFont
set_font2:
	ldy #0
	lda (r0),y
	sta baselineOffset
	iny
	lda (r0),y
	sta curSetWidth
	iny
	lda (r0),y
	sta curSetWidth+1
	iny
	lda (r0),y
	sta curHeight
	iny
	lda (r0),y
	sta curIndexTable
	iny
	lda (r0),y
	sta curIndexTable+1
	iny
	lda (r0),y
	sta cardDataPntr
	iny
	lda (r0),y
	sta cardDataPntr+1
	AddW r0, curIndexTable
	AddW r0, cardDataPntr
	rts
