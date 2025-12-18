;********************************************************************
;* htw saar - Fakultaet fuer Ingenieurwissenschaften				*
;* Labor fuer Eingebettete Systeme									*
;* Mikroprozessortechnik											*
;********************************************************************
;* Assembler_Startup.S: 											*
;* Programmrumpf fuer Assembler-Programme mit dem Keil				*
;* Entwicklungsprogramm uVision fuer ARM-Mikrocontroller			*
;********************************************************************
;* Aufgabe-Nr.:         	* 				2.2	               		*
;*              			*						    			*
;********************************************************************
;* Gruppen-Nr.: 			* Donnerstagsgruppe 1 (14:15-15:45)		*
;*              			*										*
;********************************************************************
;* Name / Matrikel-Nr.: 	*	Finn Öttinger 		5014272			*
;*							*	Maximilian Kany 	5016118			*
;*							*										*
;********************************************************************
;* Abgabedatum:         	*	18.12.2025              			*
;*							*										*
;********************************************************************
KONSTANTE_9 	EQU 		0x38E38E39             				; Definiert die DCD-Konstante 0x38E28E39 (z. B. für Farbdemodulation)
;********************************************************************
;* Daten-Bereich bzw. Daten-Speicher				            	*
;********************************************************************
				AREA		Daten, DATA, READWRITE  		; Definiert einen beschreibbaren Datenbereich
Datenanfang                                    				; Markiert den Anfang des Datenbereichs
Quadrat			EQU			Datenanfang            			; Definiert ein Label 'Quadrat' als Alias für 'Datenanfang'

;********************************************************************
;* Programm-Bereich bzw. Programm-Speicher							*
;********************************************************************
				AREA		Programm, CODE, READONLY  		; Definiert einen schreibgeschützten Codebereich
				ARM                             			; Wechselt in den ARM-Befehlssatz (nicht Thumb)
Reset_Handler	MSR			CPSR_c, #0x10           		; Setzt den Prozessor in den User Mode (keine Privilegien)

;********************************************************************
;* Hier das eigene (Haupt-)Programm einfuegen   					*
;********************************************************************
				LDR			R0, =X_Wert             		; Lädt die Adresse von 'X_Wert' in Register R0
				BL			Formel           				; Springt zum Unterprogramm und speichert die Rücksprungadresse in LR

;********************************************************************
;* Ende des eigenen (Haupt-)Programms                               *
;********************************************************************
endlos			B			endlos                  		; Endlosschleife, um das Programm am Laufen zu halten

;********************************************************************
;* ab hier Unterprogramme                                           *
;********************************************************************
Formel
				STMFD		SP!, {LR}        		; Speichert Register R1-R4 und LR auf dem Stack (Sicherung des Kontexts)
				
				;Konstante Laden
				LDR			R1, =X_Wert             		; Lädt den Wert von der Adresse in R0 (X_Wert) in Register R1
				LDR			R1, [R1]						; Lädt den Wert von X_Wert(100) in R1
				LDR			R2, =KONSTANTE_9        		; Lädt die Adresse der Konstante 0x38E38E39 in R2 
				
				MUL			R0, R1, R1              		; Berechnet R1 * R1 (Quadrat von X_Wert) und speichert das Ergebnis in R0
				
				UMULL		R3, R4, R0, R2          		; Führt eine 64-Bit-Multiplikation von R0 und R1 durch, Ergebnis in R3 (niederwertig) und R4 (höherwertig)
				MOV			R0, R4, LSR #1          		; Schiebt das höherwertige Ergebnis (R4) um 1 Bit nach rechts (Division durch 2)
				
				MOV			R0, R0, LSL #2          		; Schiebt das Ergebnis um 2 Bits nach links (Multiplikation mit 4)
				
				LDMFD   	SP!, {LR}        		; Stellt die gesicherten Register R1-R4 und LR vom Stack wieder her
				BX 			LR                      		; Springt zurück zur Aufrufadresse (Rückkehr aus dem Unterprogramm)

;********************************************************************
;* Konstanten im CODE-Bereich                                       *
;********************************************************************
X_Wert		DCD			100                     			; Definiert eine Konstante 'X_Wert' mit dem Wert 100

															; Konstante stammt von Folie Seite 96 (PDF S. 106)

;********************************************************************
;* Ende der Programm-Quelle                                         *
;********************************************************************
				END