;  SECU-3  - An open source, free engine control unit
;  Copyright (C) 2007 Alexey A. Shabelnikov. Ukraine, Gorlovka
;
;  This program is free software: you can redistribute it and/or modify
;  it under the terms of the GNU General Public License as published by
;  the Free Software Foundation, either version 3 of the License, or
;  (at your option) any later version.
;
;  This program is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;  GNU General Public License for more details.
;
;  You should have received a copy of the GNU General Public License
;  along with this program.  If not, see <http://www.gnu.org/licenses/>.
;
;  contacts:
;             http://secu-3.org
;             email: shabelnikov@secu-3.org


; ��� ࠡ��� �����稪� ����室���:
; ࠧ��� �����稪� ������ �� ��࠭��� ������� (mega16, mega32, mega64).
; BOOTRST = 0, BOOTSZ1 = 1, BOOTSZ0 = 0, JTAGEN = 1, WDTON = 1(mega64), M103C = 0(mega64), ����� - 16.000 ��� 
; 1 - ��� �� ���ணࠬ��஢��

; - �� ����᪥ ���ப���஫��� �ࠢ����� ��।����� �����稪�. �஢������ ���ﭨ� 
;   ����� LDR_P_INIT ���� C. �᫨ ��  ��� ������ �஢���, � �ந�������� �த������� ࠡ��� 
;   �����稪�. ���� �ந�������� ����� �ਫ������ (Application section).  
; - �����稪 ����� ���� ��⨢�஢�� �������� ���室� �� �᭮���� �ணࠬ��
; ���� ���室� - START_FROM_APP

;          ���ᠭ�� ������ ॠ���㥬�� �१ UART
;----------------------------------------------------------------------------------+
;   �ணࠬ��஢���� 㪠������ ��࠭��� ����� �ணࠬ�                            |
;    !PNNdata<CS                     size      dir                                 |
;    P    - ��� �������               1        in                                  |
;    NN   - ����� ��࠭���            1        in                                  |
;    data - ����� ��࠭���          256max    in                                  |
;    CS   - ����஫쭠� �㬬�         1        out                                 |
;    ��। ���뫪�� ����� ������ ����室��� ��������� �����襭�� ��࠭�� - 3-4 �� |
;----------------------------------------------------------------------------------+
;   �⥭�� 㪠������ ��࠭��� ����� �ணࠬ�                                      |
;    !RNN<dataCS                     size      dir                                 |
;    R    - ��� �������               1        in                                  |
;    NN   - ����� ��࠭���            1        in                                  |
;    data - ����� ��࠭���          256max    out                                 |
;    CS   - ����஫쭠� �㬬�         1        out                                 |
;----------------------------------------------------------------------------------+
;                                                                                  |
;   ��室 �� �����稪� � ����� �᭮���� �ணࠬ��                                |
;    !T<@                            size      dir                                 |
;    T    - ��� �������               1        in                                  |
;    @    - ���⢥ত���� ���.        1        out                                 |
;----------------------------------------------------------------------------------+
;                                                                                  |
;   �⥭�� ᮤ�ন���� EEPROM                                                      |
;    !J<dataCS                       size      dir                                 |
;    J    - ��� �������               1        in                                  |
;    data - ����� EEPROM           2048max    out                                 |
;    CS   - ����஫쭠� �㬬�         1        out                                 |
;----------------------------------------------------------------------------------+
;                                                                                  |
;   ������ ������ ᮤ�ন���� EEPROM                                               |
;    !Wdata<CS                       size      dir                                 |
;    W    - ��� �������               1        in                                  |
;    data - ����� EEPROM           2048max    in                                  |
;    CS   - ����஫쭠� �㬬�         1        out                                 |
;    ��᫥ ���뫪� ������� ���� ����室��� ��������� 10ms                         |
;----------------------------------------------------------------------------------+
;                                                                                  |
;   ��।�� ���ଠ樨 � ��⫮����                                               |
;    !I<data                         size      dir                                 |
;    I    - ��� �������               1        in                                  |
;    data - ��।��. ���ଠ��       24       out                                 |
;----------------------------------------------------------------------------------+
;
; ����� ��।������ �����稊�  ��稭����� � ᨬ���� !
; ����� ��।������ �����稊�� ��稭����� � ᨬ���� <
; size 㪠��� � �����, � ᨬ����� (��।������� �१ UART) �㤥� � 2 ���� �����
;
;   E᫨ ��������� �訡��, � ������稪 ���뫠�� � �⢥� <?
;

#ifdef _PLATFORM_M16_
.INCLUDE "m16def.inc"
#message "ATMega16 platform used"
#elif _PLATFORM_M32_
.INCLUDE "m32def.inc"
#message "ATMega32 platform used"
#elif _PLATFORM_M64_
.INCLUDE "m64def.inc"
#message "ATMega64 platform used"
 ;define UART registers, because mega 64 has two UARTS
.equ    UBRRL = UBRR0L
.equ    RXEN  = RXEN0
.equ    TXEN  = TXEN0
.equ    UDR   = UDR0
.equ    RXC   = RXC0
.equ    UDRE  = UDRE0
.equ    UCSRA = UCSR0A
.equ    UCSRB = UCSR0B

#else
 #error "Wrong platform identifier!"
#endif

.equ    LDR_P_INIT = 3                    ;����� ���� C ��� ���� �����稪� �� ����
.equ    PAGESIZEB  = PAGESIZE*2           ;PAGESIZEB is page size in BYTES, not words
.equ    UBR        = 0x67                 ;᪮���� UART-a - 9600 ���

        .org  SECONDBOOTSTART             ;��砫� ���� �����稪�
        cli                               ;���뢠��� �� �ᯮ�������

     	clr   R0
	out   DDRC,R0             	  ;������ �� ����� ���� C �室���
	sbic  PINC,LDR_P_INIT	       	  ;�᫨ 0 � bootloader ࠡ�⠥� �����
      	rjmp  FLASHEND+1	          ;���� ���� �᭮���� �ணࠬ��
START_FROM_APP:
        cli                               ;�᫨ �� ��諨 �� �ணࠬ�� � ���뢠��� ���� ��易⥫쭮 �������
        ;���樠�����㥬 㪠��⥫� �⥪�
        ldi   R24,low(RAMEND)             ; SP = RAMEND
        ldi   R25,high(RAMEND)
        out   SPL,R24
        out   SPH,R25

        ;���樠�����㥬 UART
        ldi   R24,UBR                     ; set Baud rate
        out   UBRRL,R24
        ldi   R24,(1<<RXEN)|(1<<TXEN)     ; Enable receiver & transmitter, 8-bit mode
        out   UCSRB,R24

        ;�᭮���� 横� �ணࠬ�� - �������� ������

wait_cmd:    ;�������� ����� �������
        rcall uartGet
        CPI   R16, '!'
        brne  wait_cmd
        ; �ਥ� ���� ��।��� �������
wait_cc:
        rcall uartGet
        CPI   R16,'P'
        brne  CMD100
        ; ������� 'P' �ணࠬ��஢���� 㪠������ ��࠭��� ����� �ணࠬ�
        rcall recv_hex                    ;R16 <--- NN
        rcall page_num                    ;Z <-- ����� ��࠭���

        ;��ࠥ� ��࠭���
        ldi   R17, (1<<PGERS) | (1<<SPMEN)
        rcall Do_spm
        ;ࠧ���� ������ ������ RWW
        ldi   R17, (1<<RWWSRE) | (1<<SPMEN)
        rcall Do_spm

        clr   R20                         ;���⨫� ���� ����஫쭮� �㬬�
        ;�����뢠�� ����� �� UART-a � ���� ��࠭���
        ldi   R24, low(PAGESIZEB)         ;����������஢��� ���稪 (���-�� ���� � ��࠭��)

Wr_loop:  ;64(mega16, mega32), 128(mega64) ���樨 - �� ���� ����� ��� ���� (���� ᫮��)
        rcall recv_hex                    ;R16 <--- LO
        mov   R0,R16
        eor   R20,R16

        rcall recv_hex                    ;R16 <--- HI
        mov   R1,R16
        eor   R20,R16

        ldi   R17, (1<<SPMEN)
        rcall Do_spm
        adiw  ZH:ZL,2                     ;Z+=2, ���室 � ᫥���饬� ᫮�� � ��࠭��
        subi  R24,  2                     ;R24-=2, 㬥��訫� ���稪 ᫮� 
        brne  Wr_loop

        ; ����⠭�������� 㪠��⥫� � �ந������ ������ ��࠭���
        subi  ZL, low(PAGESIZEB)          ;restore pointer
        sbci  ZH, high(PAGESIZEB)

        ldi   R17, (1<<PGWRT) | (1<<SPMEN)
        rcall Do_spm

        rcall sendAnswer

        ;��।��� ���� ����஫쭮� �㬬�
        mov   R16,R20
        rcall send_hex

        rjmp  wait_cmd                    ; �� �������� ����� �������
       ;------------------------------------------------------------------------------
CMD100:
        CPI   R16,'R'
        brne  CMD200
        ; ������� 'R'- �⥭�� 㪠������ ��࠭��� ����� �ணࠬ�

        rcall recv_hex
        rcall page_num                    ;Z <-- ����� ��࠭���

        rcall sendAnswer

        ;ࠧ���� ������ ������ RWW
        ldi   R17, (1<<RWWSRE) | (1<<SPMEN)
        rcall Do_spm

        clr   R20                         ;���⨫� ���� ����஫쭮� �㬬�
        ; �⥭�� ��࠭��� � UART
        ldi   R24, low(PAGESIZEB)         ;����������஢��� ���稪
Rdloop:  ;64(mega16, mega32), 128(mega64) ���樨
        lpm   R16, Z+
        eor   R20,R16
        rcall send_hex
        subi  R24, 1
        brne  Rdloop

        ;��।��� ���� ����஫쭮� �㬬�
        mov   R16,R20
        rcall send_hex

        rjmp  wait_cmd
        ;------------------------------------------------------------------------------
CMD200:
        CPI   R16,'J'
        brne  CMD300
        ; ������� 'J' - �⥭�� EEPROM

        rcall sendAnswer
 
        clr   R20                         ;���⨫� ���� ����஫쭮� �㬬�
        clr   R26
        clr   R27
        ldi   R17,0x01                    ; �⥭�� EEPROM
L23:
        rcall EepromTalk
        eor   R20,R16              
        rcall send_hex
        cpi   R27,high(EEPROMEND+1)       ;512? 1024? 2048?
        BRNE  L23

        ;��।��� ���� ����஫쭮� �㬬�
        mov   R16,R20
        rcall send_hex

        rjmp  wait_cmd
        ;------------------------------------------------------------------------------
CMD300:
        CPI   R16,'W'
        brne  CMD400
        ; ������� 'W' - ������ EEPROM

        clr   R20                         ;���⨫� ���� ����஫쭮� �㬬�
        clr   R26                         ;���樠����஢��� 㪠��⥫� �� �祩�� EEPROM
        clr   R27                         ;
        ldi   R17,0x06                    ;������ EEPROM
L24:
        rcall recv_hex
        out   EEDR,R16
        rcall EepromTalk                  ;������
        eor   R20,R16
        cpi   R27,high(EEPROMEND+1)       ;512? 1024? 2048?
        BRNE  L24

        rcall sendAnswer

        ;��।��� ���� ����஫쭮� �㬬�
        mov   R16,R20
        rcall send_hex

        rjmp  wait_cmd
        ;------------------------------------------------------------------------------
CMD400:
        CPI   R16,'T'
        brne  CMD500
        ; ������� 'T' - ��室 �� �����稪� (���室 �� $0000)

        rcall sendAnswer
        ldi   R16,'@'
        rcall uartSend                    ; ���뫪� ���⢥ত����

        ;�������� �����襭�� ��।��, � ��⥬ ��室
w00:
        sbis  UCSRA,UDRE
        rjmp  w00

Return:
#ifdef _PLATFORM_M64_
        lds   R16,SPMCR                   ;<--memory mapped
#else
        in    R16,SPMCR
        nop                               ;to get the same code size
#endif
        sbrs  R16,RWWSB
      	rjmp  do_strt_app	          ; Start the application program 
        ; re-enable the RWW section
        ldi   R17, (1<<RWWSRE) | (1<<SPMEN)
        rcall Do_spm
      	rjmp  Return

        ;Enable watchdog timer and wait for system reset. Note: we rely that safety level 
        ;is 0 (actual only for mega 64)
do_strt_app:
        ldi   R16, (1 << WDE)             ;16 ms
        out   WDTCR, R16        
wait_rst:
        rjmp  wait_rst                    

        ;------------------------------------------------------------------------------
CMD500:
        CPI   R16,'I'
        brne  CMD_NA
        ;������� 'I' - ��।�� ���ଠ樨 � ��⫮����

        rcall sendAnswer

	ldi ZL,low(2*info)                ; ���⮢� ���� ᮮ�饭��
	ldi ZH,high(2*info)
isloop:
	lpm R16,Z+		          ; string pointer (the Z-register)
	tst R16
	breq end_loop	                  ; exit the character output loop if character was '\0'
	rcall uartSend 		          ; send the read character via the UART
	rjmp isloop                       ; go to start of loop for next character
end_loop:
        rjmp  wait_cmd
        ;------------------------------------------------------------------------------
CMD_NA:
        ;������᭠� �������, ���뫠�� ��� �訡��
        rcall sendAnswer
        ldi   R16,'?'
        rcall uartSend
        rjmp  wait_cmd

       ;-------------------------------------------------------------------------------



;���뫠�� <
sendAnswer:
        ldi   R16,'<'
        rcall uartSend
        ret


;�⠥� ���� ���� �� UART � �����頥� ��� � R16
uartGet:
        sbis  UCSRA,RXC                   ; wait for incoming data (until RXC==1)
        rjmp  uartGet
        in    R16,UDR                     ; return received data in R16
        ret

;�����뢠�� ���� ���� �� ॣ���� R16 � UART
uartSend:
        sbis  UCSRA,UDRE                  ; wait for empty transmit buffer (until UDRE==1)
        rjmp  uartSend
        out   UDR,R16                     ; UDR = R16, start transmission
        ret


;��ॢ���� ����筮� �᫮ �� R16 � ��⭠����筮� �᫮ � R17:R16
;� ��� ॣ����� ��⭠����筮� �᫮ �।�⠢���� ���� ASCII ᨬ������
btoh:
        push  R18
        mov   R17,R16                     ;��ॢ���� ������ ��ࠤ� �᫠ � HEX
        SWAP  R17                         ;������ ������ ��ࠤ� ����襩
        andi  R17,0x0F
        cpi   R17,0x0A
        BRLO  _b00                        ;�᫨ ��� � �ਡ���塞 0x30, �᫨ �㪢� � 0x37
        ldi   R18,7
        add   R17,R18
_b00:
        ldi   R18,0x30
        add   R17,R18
        andi  R16,0x0F                    ;��ॢ���� ������� ��ࠤ� �᫠ � HEX
        CPI   R16,0x0A
        BRLO  _b01
        ldi   R18,7
        add   R16,R18
_b01:
        ldi   R18,0x30
        add   R16,R18
        pop   R18
        ret


;��ॢ���� ��⭠����筮� �᫮ �� R17:R16 � ����筮� � R16
;� ॣ����� R17:R16 ��⭠����筮� �᫮ �।�⠢���� ���� ASCII ᨬ������
htob:
        push   R17
        cpi    R16,0x3A
        BRLO   _h00
        SUBI   R16,7                      ;�᫨ �㪢�, � ���⠥� ��
_h00:   ;���
        subi   R16,0x30
        cpi    R17,0x3A
        BRLO   _h01
        SUBI   R17,7                      ;�᫨ �㪢�, � ���⠥� ��
_h01:   ;���
        subi   R17,0x30
        SWAP   R17                        ;� R17 ����� ��ࠤ� - �� ���� ��...
        OR     R16,R17
        pop    R17
        ret



;��ॢ���� ����筮� �᫮ �� R16 � ��⭠����筮� � ��।��� ���
send_hex:
        push  R16
        push  R17
        rcall btoh                        ;R17:R16 ᮤ�ঠ� ᨬ���� HEX-�᫠
        push  R16                         ;��࠭塞 R16 ⠪ ��� ᭠砫� ����室��� ��।��� ���訩 ����
        mov   R16,R17
        rcall uartSend
        pop   R16
        rcall uartSend                    ;��।��� ����訩 ���� �᫠
        pop   R17
        pop   R16
        ret 


;�ਭ����� ��� ᨬ���� ��⭠����筮�� �᫠ � ��ॢ���� �� � ����筮�
;१���� � R16
recv_hex:
        push  R17
        rcall uartGet
        CPI   R16,'!'
        breq  new_cmd                     ;����祭 ᨬ��� ����� �������
        mov   R17,R16
        rcall uartGet
        CPI   R16,'!'
        breq  new_cmd                     ;����祭 ᨬ��� ����� �������
        call  htob
        pop   R17
        ret
new_cmd:
        pop   R17
        pop   R16                         ;㤠�塞 �� �⥪� ᮤ�ন��� ���稪� ������
        pop   R16
        rjmp  wait_cc



;�����뢠�� ����� ��࠭��� �� R16 � Z (� ᮮ⢥�����騥 ����)
; ॣ���� Z
; 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
; x  x  *  *  *  *  *  *  *  0  0  0  0  0  0  0   mega16
; x  *  *  *  *  *  *  *  *  0  0  0  0  0  0  0   mega32
; *  *  *  *  *  *  *  *  0  0  0  0  0  0  0  0   mega64
;
; x - �� ����� ���祭��
; * - ����� ��࠭���
; 0 - ࠢ�� 0
Page_num:
        mov   ZH,R16
#ifdef _PLATFORM_M64_
        nop
        clr   ZL
        nop
        nop
#else
        lsr   ZH
        clr   ZL
        bst   R16,0
        bld   ZL,7
#endif
        ret


; �����⢤���� 㪠������ ����樨 �ணࠬ��஢����
; R17 - ⥪��� ������
Do_spm:
        ;�஢�ઠ �����襭�� �।���饩 SPM ����樨 � �������� �᫨ �� �����襭�
#ifdef _PLATFORM_M64_
        lds   R16,SPMCR                   ;<--memory mapped
#else
        in    R16,SPMCR
        nop                               ;to get the same code size
#endif
        sbrc   R16, SPMEN
        rjmp   Do_spm
        ;�஢��塞 ����� � EEPROM � �᫨ �� �����, � ���� �����襭�� ����樨
Wait_ee:
        sbic   EECR, EEWE
        rjmp   Wait_ee
        ;�� ��ଠ�쭮 - ॠ���㥬 SPM ������
#ifdef _PLATFORM_M64_
        sts   SPMCR, R17                  ;<--memory mapped
#else
        out   SPMCR, R17
        nop                               ;to get the same code size
#endif
        spm
        ret


;��⠥� ��� �����뢠�� EEPROM
;if R17 == 6 then Write, if R17 == 1 then Read
EepromTalk:
	out EEARL,R26 		          ; EEARL = address low
	out EEARH,R27 		          ; EEARH = address high
	adiw R27:R26,1 		          ; address++
	sbrc R17,1 		          ; skip if R17 == 1 (read Eeprom)
	sbi EECR,EEMWE 		          ; EEMWE = 1 (write Eeprom)
	out EECR,R17 		          ; EECR = R17 (6 write, 1 read)
L90:
	sbic EECR,EEWE 		          ; wait until EEWE == 0
	rjmp L90
	in R16,EEDR 		          ; R16 = EEDR
	ret

; ࠧ��� ������ ���� 24 |----------------------|       
info:             .db  "Boot loader v1.2.[08.10]",0,0 ;[mm.yy]
