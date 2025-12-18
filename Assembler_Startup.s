;********************************************************************
;* htw saar - Fakultaet fuer Ingenieurwissenschaften				*
;* Labor fuer Eingebettete Systeme									*
;* Mikroprozessortechnik											*
;********************************************************************
;* Assembler_Startup.S: 											*
;* Programmrumpf fuer Assembler-Programme mit dem Keil				*
;* Entwicklungsprogramm uVision fuer ARM-Mikrocontroller			*
;********************************************************************
;* Aufgabe-Nr.:         	* 				2.4	               		*
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

;********************************************************************
; Symboldefinitionen												*
;********************************************************************
RAM_Size EQU 0x0800 ; z. B. 2 KB Datenspeicher

;********************************************************************
;* Daten-Bereich bzw. Daten-Speicher                                *
;********************************************************************
    AREA    Daten, DATA, READWRITE
Datenanfang
    ALIGN

Top_Stack    EQU Datenanfang + RAM_Size
Datenende    EQU Top_Stack
Ergebnis_BCD  DCD 0            ; Zum Speichern des BCD-Ergebnisses

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
    LDR     SP, =Top_Stack
    LDR     R0, =TestString
    BL      Berechnung

endlos
    B       endlos                ; Endlosschleife

;********************************************************************
;* Unterprogramm: uItoBCD (Unsigned Integer to Packed BCD)          *
;* Eingang: R0 = Unsigned Integer (32-Bit)                          *
;* Ausgang: R0 = Gepackte BCD-Zahl (32-Bit)                         *
;* Verwendet: R1-R5, LR                                             *
;********************************************************************
Berechnung
    ; R0_in = Adresse String
    STMFD   sp!, {LR}

    ; 1. X bestimmen (AtoI)
    BL      AtoI                ; R0 = X (signed int)

    ; 2. Y berechnen (Formel: Y = f(X))
    BL      Formel              ; R0 = Y (signed int)

    ; 3. Y nach BCD konvertieren (uItoBCD)
    ; Achtung: Y muss positiv sein, da uItoBCD unsigned ist. (Unsere Formel liefert Y >= 0)
    BL      uItoBCD             ; R0 = Y_BCD

    LDMFD   sp!, {LR}
    BX      LR

Formel
    STMFD   SP!, {LR}           ; Speichert Register LR auf dem Stack (Sicherung des Kontexts)

    ; Konstante Laden
    MOV     R1, R0               ; Lädt den Wert von der Adresse in R0 (X_Wert) in Register R1
    LDR     R2, =KONSTANTE_9      ; Lädt die Adresse der Konstante 0x38E38E39 in R2

    MUL     R0, R1, R1           ; Berechnet R1 * R1 (Quadrat von X_Wert) und speichert das Ergebnis in R0

    UMULL   R3, R4, R0, R2       ; Führt eine 64-Bit-Multiplikation von R0 und R1 durch, Ergebnis in R3 (niederwertig) und R4 (höherwertig)
    MOV     R0, R4, LSR #1       ; Schiebt das höherwertige Ergebnis (R4) um 1 Bit nach rechts (Division durch 2)

    MOV     R0, R0, LSL #2       ; Schiebt das Ergebnis um 2 Bits nach links (Multiplikation mit 4)

    LDMFD   SP!, {LR}            ; Stellt die gesicherten Register LR vom Stack wieder her
    BX      LR                   ; Springt zurück zur Aufrufadresse (Rückkehr aus dem Unterprogramm)

AtoI
    ; R4 (Ergebnis), R2 (Vorzeichen), R1 (temporär), LR sichern
    STMFD   sp!, {LR}
    ; Input R0: Adresse String
    ; Output R0: Ergebnis

    MOV     R4, #0               ; R4 = Ergebnis (Akku) = 0
    MOV     R2, #1               ; R2 = Vorzeichen = +1

    ; 1. Vorzeichen prüfen (Zeichen an R0 laden in R3)
    LDRB    R3, [R0], #1

    CMP     R3, #ASCII_MINUS
    MOVEQ   R2, #-1              ; R2 = -1 (negativ)
    CMPNE   R3, #ASCII_PLUS
    LDRBEQ  R3, [R0], #1         ; Zeichen laden, Pointer R0 erhöhen

parse_digits
    SUBS    R3, R3, #ASCII_ZERO  ; ASCII nach Zahl (z.B. '5' -> 5)

    ; R4 = R4 * 10 + R3 (Multiplikation mit 10)
    ADDPL   R4, R4, R4, LSL #2    ; R4 = R4 * 5
    LSLPL   R4, R4, #1           ; R4 = R4 * 10
    ADDPL   R4, R4, R3           ; R4 = R4 + Ziffer

    LDRBPL  R3, [R0], #1         ; Zeichen laden, Pointer R0 erhöhen
    BPL     parse_digits         ; Nächste Ziffer

; 3. Vorzeichen anwenden
apply_sign
    CMP     R2, #1
    RSBNE   R4, R4, #0           ; Wenn R2 != 1 (negativ), dann R4 = 0 - R4 (Negieren)

    MOV     R0, R4              ; Ergebnis in R0 für den Rücksprung

    LDMFD   sp!, {LR}           ; R1-R4 wiederherstellen
    BX      LR

uItoBCD
    ; Sichert alle verwendeten Register (inkl. LR) und verwendet STMFD
    STMFD   sp!, {R1-R7, LR}

    MOV     R1, #0              ; R1 = BCD-Ergebnis = 0
    MOV     R3, #0              ; R3 = Bit-Verschiebung (shift_count = 0)
    LDR     R5, =INV_10_C        ; R5 = 0xCCCCCCCD (Kehrwert für Division)

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

    LDMFD   sp!, {R1-R7, LR}    ; Register wiederherstellen
    BX      LR

;********************************************************************
;* Konstanten im CODE-Bereich                                       *
;********************************************************************
INV_10_C    EQU 0xCCCCCCCD

ASCII_ZERO  EQU '0'
ASCII_PLUS  EQU '+'
ASCII_MINUS EQU '-'

KONSTANTE_9 EQU 0x38E38E39              ; Definiert die DCD-Konstante 0x38E28E39 (z. B. für Farbdemodulation)

TestString  DCB "+100"

Ergebnis    DCD 0

;********************************************************************
;* Ende der Programm-Quelle                                         *
;********************************************************************
    END
