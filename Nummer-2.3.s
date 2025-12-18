;********************************************************************
;* htw saar - Fakultaet fuer Ingenieurwissenschaften				*
;* Labor fuer Eingebettete Systeme									*
;* Mikroprozessortechnik											*
;********************************************************************
;* Assembler_Startup.S: 											*
;* Programmrumpf fuer Assembler-Programme mit dem Keil				*
;* Entwicklungsprogramm uVision fuer ARM-Mikrocontroller			*
;********************************************************************
;* Aufgabe-Nr.:         	* 				2.3	               		*
;*              			*						    			*
;********************************************************************
;* Gruppen-Nr.: 			* Donnerstagsgruppe 1 (14:15-15:45)		*
;*              			*										*
;********************************************************************
;* Name / Matrikel-Nr.: 	*	Finn Öttinger 		5014272			*
;*							*	Maximilian Kany 	5016118			*
;*							*										*
;********************************************************************
;* Abgabedatum:         	*			18.12.2025              	*
;*							*										*
;********************************************************************
; Symboldefinitionen												*
;********************************************************************
RAM_Size EQU 0x0800 ; z. B. 2 KB Datenspeicher 						*
;********************************************************************
;* Daten-Bereich bzw. Daten-Speicher                                *
;********************************************************************
  AREA    Daten, DATA, READWRITE
Datenanfang
        ALIGN
		
Top_Stack	 EQU Datenanfang + RAM_Size
Datenende 	 EQU Top_Stack 
        ALIGN
Ergebnis_BCD DCD 0            ; Zum Speichern des BCD-Ergebnisses

;********************************************************************
;* Programm-Bereich bzw. Programm-Speicher                          *
;********************************************************************
        AREA    Programm, CODE, READONLY               ; Setzt den Startpunkt
        ARM

Reset_Handler
        MSR     CPSR_c, #0x10   ; User Mode aktivieren

;********************************************************************
;* Hauptprogramm                                                    *
;********************************************************************
HauptProgramm

; --- Test 1: uItoBCD-Aufruf (Aufgabe 2.3)
		LDR		SP, =Top_Stack
        LDR     R0, =65535            ; Dezimalzahl 65535 in R0 laden
        BL      uItoBCD               ; Ruft uItoBCD auf (R0 = 0x00065535 erwartet)
        LDR     R1, =Ergebnis_BCD
        STR     R0, [R1]              ; BCD-Ergebnis speichern

endlos	B       endlos                ; Endlosschleife

;********************************************************************
;* Unterprogramm: uItoBCD (Unsigned Integer to Packed BCD)          *
;* Eingang: R0 = Unsigned Integer (32-Bit)                          *
;* Ausgang: R0 = Gepackte BCD-Zahl (32-Bit)                         *
;* Verwendet: R1-R5, LR                                             *
;********************************************************************
uItoBCD
        ; Sichert alle verwendeten Register (inkl. LR) und verwendet STMFD
        STMFD   sp!, {R1-R7, LR}

        MOV     R1, #0             ; R1 = BCD-Ergebnis = 0
        MOV     R3, #0             ; R3 = Bit-Verschiebung (shift_count = 0)
        LDR     R5, =INV_10_C      ; R5 = 0xCCCCCCCD (Kehrwert für Division)

LOOP_START
        ; 1. Division: R4 (Quotient) = R0 / 10
        ; R4 enthält den oberen 32-Bit-Teil des 64-Bit-Ergebnisses (Quotient)
        UMULL   R6, R4, R0, R5      ; R6:RdLo, R4:RdHi = R0 * R5
        MOVS    R4, R4, LSR #3      ; R4 = R4 / 8 (um den Faktor 8 zu kompensieren)

        ; 2. Rest (Ziffer) berechnen: Rest = Dividend - Quotient * 10
        MOV     R6, #10             ; R6 = 10
        MUL     R6, R4, R6          ; R6 = Quotient * 10

        SUB     R2, R0, R6          ; R2 = Dezimalziffer (Rest) = R0 - (Quotient * 10)

        ; 3. Nächster Dividend setzen
        MOV     R0, R4              ; R0 = Quotient (für den nächsten Schleifendurchlauf)

        ; 4. BCD-Verpackung
        LSL     R2, R2, R3          ; Schiebe die Ziffer (R2) an die richtige BCD-Position
        ORR     R1, R1, R2          ; Füge die Ziffer in das BCD-Ergebnis (R1) ein

        ADD     R3, R3, #4          ; Erhöhe den Shift-Wert um 4 Bit

        BNE     LOOP_START

CONVERSION_DONE
        MOV     R0, R1              ; Finales Ergebnis in R0 kopieren

        ; Register wiederherstellen und direkt zum PC springen (spart einen Befehl)
        LDMFD   sp!, {R1-R7, LR}
		BX 		LR
;********************************************************************
;* Konstanten im CODE-Bereich                                       *
;********************************************************************
INV_10_C        EQU 0xCCCCCCCD

;********************************************************************
;* Ende der Programm-Quelle                                         *
;********************************************************************
        END