;********************************************************************
;* htw saar - Fakultaet fuer Ingenieurwissenschaften				*
;* Labor fuer Eingebettete Systeme									*
;* Mikroprozessortechnik											*
;********************************************************************
;* Assembler_Startup.S: 											*
;* Programmrumpf fuer Assembler-Programme mit dem Keil				*
;* Entwicklungsprogramm uVision fuer ARM-Mikrocontroller			*
;********************************************************************
;* Aufgabe-Nr.:         	* 				2.1	               		*
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
;********************************************************************
;* Programm-Bereich bzw. Programm-Speicher							*
;********************************************************************
				AREA		Programm, CODE, READONLY
				ARM
Reset_Handler	MSR			CPSR_c, #0x10	; User Mode aktivieren

;********************************************************************
;* Hauptprogramm                                                    *
;********************************************************************
HauptProgramm
				LDR		SP, =Top_Stack
                LDR     R0, =String1       ; Adresse des Strings
                BL      AtoI               ; ruft AtoI auf
                LDR     R1, =Ergebnis
                STR     R0, [R1]           ; Ergebnis speichern


endlos         B       endlos             ; Endlosschleife

;********************************************************************
;* Unterprogramm: AtoI 
;********************************************************************
AtoI
    ; R4 (Ergebnis), R2 (Vorzeichen), R1 (temporär), LR sichern
    STMFD sp!, {R1-R4, LR}
    ; Input R0: Adresse String
    ; Output R0: Ergebnis

    MOV 	R4, #0          ; R4 = Ergebnis (Akku) = 0
    MOV 	R2, #1          ; R2 = Vorzeichen = +1

    ; 1. Vorzeichen prüfen (Zeichen an R0 laden in R3)
    LDRB 	R3, [R0], #1

    CMP 	R3, #ASCII_MINUS
    MOVEQ 	R2, #-1         ; R2 = -1 (negativ)
    CMPNE 	R3, #ASCII_PLUS
	LDRBEQ 	R3, [R0], #1   ; Zeichen laden, Pointer R0 erhöhen

parse_digits
    
    
    SUBS 	R3, R3, #ASCII_ZERO ; ASCII nach Zahl (z.B. '5' -> 5)

    ; R4 = R4 * 10 + R3 (Multiplikation mit 10)
    ADDPL	R4, R4, R4, LSL #2 ; R4 = R4 * 5
    LSLPL 	R4, R4, #1         ; R4 = R4 * 10
    ADDPL 	R4, R4, R3         ; R4 = R4 + Ziffer

	
	LDRBPL 	R3, [R0], #1   ; Zeichen laden, Pointer R0 erhöhen
    BPL 	parse_digits      ; Nächste Ziffer

; 3. Vorzeichen anwenden
apply_sign
    CMP R2, #1
    RSBNE R4, R4, #0    ; Wenn R2 != 1 (negativ), dann R4 = 0 - R4 (Negieren)

    MOV R0, R4          ; Ergebnis in R0 für den Rücksprung

    LDMFD sp!, {R1-R4, LR} ; R1-R4 wiederherstellen, LR nach PC für Rücksprung
	BX 		LR

;********************************************************************
;* Konstanten im CODE-Bereich                                        *
;********************************************************************

ASCII_ZERO  EQU '0'
ASCII_PLUS  EQU '+'
ASCII_MINUS EQU '-'
	

String1  DCB "-65535",0x00      ; Testwert 1
String2  DCB "-1234",0x00      ; Testwert 2 (Negativ)
String3  DCB "+42",0x00        ; Testwert 3 (Mit Plus)
               
Ergebnis DCD 0


;********************************************************************
;* Ende der Programm-Quelle                                          *
;********************************************************************
                END

