; Port Definitionlist
IOY0            EQU 0600H
MY8254_COUNT0   EQU IOY0+00H*2       ;8254 counter 0
MY8254_COUNT1   EQU IOY0+01H*2       ;8254 counter 1
MY8254_COUNT2   EQU IOY0+02H*2       ;8254 counter 2
MY8254_MODE     EQU IOY0+03H*2       ;8254 control word register

DATA    SEGMENT 
   
    PROMPT      DB 'Playing Music: Ode to Joy', 0DH, 0AH, '$'
    
    FREQ_LIST   DW  371, 371, 393, 441, 441, 393, 371, 330, 294, 294, 330, 371, 371, 330, 330       ;Frequency list
                DW  221, 221, 221, 221, 221, 248, 278, 294, 221, 221, 221, 278, 294, 294, 278, 278
                DW  294, 294, 330, 371, 371, 330, 294, 278, 294, 371, 393, 441, 441, 441, 441
                DW  294, 294, 294, 294, 221, 221, 221, 196, 185, 185, 165, 147, 221, 221, 221, 0
                
    TIME_LIST   DB  4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 6, 2, 4       ;Beat list
                DB  4, 4, 4, 4, 4, 2, 2, 4, 4, 4, 4, 4, 4, 6, 2, 4 
                DB  4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 6, 2, 4
                DB  4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 6, 2, 4
                
    NOTE_LIST   DB  3, 3, 4, 5, 5, 4, 3, 2, 1, 1, 2, 3, 3, 2, 2    
                DB  5, 5, 5, 5, 5, 6, 7, 1, 5, 5, 5, 7, 1, 1, 7, 7
                DB  1, 1, 2, 3, 3, 2, 1, 7, 1, 3, 4, 5, 5, 5, 5
                DB  1, 1, 1, 1, 5, 5, 5, 4, 3, 3, 2, 1, 5, 5, 5, 0

    LINE_CNT    DB  0 
    NOTES_DONE  DB  0               ; Counter for notes in current line
    LINE_NO     DB  0               ; Current line number (0-3)
   
DATA        ENDS

CODE    SEGMENT
    assume  CS:CODE, DS:DATA
    
    PRINT_SPACE PROC
        PUSH AX
        PUSH DX
        MOV AH, 2
        MOV DL,' '    
        INT 21H
        POP DX
        POP AX
        RET
    PRINT_SPACE ENDP
    
    PRINT_DOT PROC
        PUSH AX
        PUSH DX
        MOV AH, 2
        MOV DL,'.'    ; Print dot
        INT 21H
        POP DX
        POP AX
        RET
    PRINT_DOT ENDP
    
    PRINT_CRLF PROC
        PUSH AX 
        PUSH DX
        MOV AH, 2
        MOV DL, 0DH
        INT 21H
        MOV AH, 2
        MOV DL, 0AH 
        INT 21H
        POP DX
        POP AX
        RET
    PRINT_CRLF ENDP
    
    ; Check if we need a new line
    CHECK_NEWLINE PROC
        PUSH AX
        PUSH BX
        
        MOV AL, LINE_NO
        CMP AL, 0
        JE LINE1
        CMP AL, 1
        JE LINE2
        CMP AL, 2
        JE LINE3
        ; Must be line 3 (0-based, so actually line 4)
        
        ; Line 4: 15 notes
        MOV AL, NOTES_DONE
        CMP AL, 15
        JNE NO_NEWLINE_CHECK
        JMP DO_NEWLINE
        
LINE1:  ; Line 1: 15 notes
        MOV AL, NOTES_DONE
        CMP AL, 15
        JNE NO_NEWLINE_CHECK
        JMP DO_NEWLINE
        
LINE2:  ; Line 2: 16 notes
        MOV AL, NOTES_DONE
        CMP AL, 16
        JNE NO_NEWLINE_CHECK
        JMP DO_NEWLINE
        
LINE3:  ; Line 3: 15 notes
        MOV AL, NOTES_DONE
        CMP AL, 15
        JNE NO_NEWLINE_CHECK
        
DO_NEWLINE:
        CALL PRINT_CRLF
        MOV NOTES_DONE, 0           ; Reset notes counter
        INC LINE_NO                 ; Move to next line
        CMP LINE_NO, 4              ; Check if we have used all 4 lines
        JB NO_NEWLINE_CHECK
        MOV LINE_NO, 0              ; Reset to first line
        
NO_NEWLINE_CHECK:
        POP BX
        POP AX
        RET
    CHECK_NEWLINE ENDP
    
    ; Check if frequency is in low range (147-278) and print dot
    ; Input: Current frequency is at [SI]
    CHECK_AND_PRINT_DOT PROC
        PUSH AX
        PUSH DX
        PUSH SI
        
        MOV AX, [SI]               ; Get current frequency
        
        ; Check if frequency is 0 (end of song marker)
        CMP AX, 0
        JE NO_DOT_NEEDED
        
        ; Check if frequency is in low range (147-278)
        CMP AX, 147
        JL NO_DOT_NEEDED           ; If < 147, no dot
        
        CMP AX, 278
        JG NO_DOT_NEEDED           ; If > 278, no dot
        
        ; Frequency is in 147-278 range, print dot
        CALL PRINT_DOT
        JMP DOT_DONE
        
NO_DOT_NEEDED:
        ; Frequency is 0, <147, or >278, no dot needed
        ; Just print a space instead
        CALL PRINT_SPACE
        
DOT_DONE:
        POP SI
        POP DX
        POP AX
        RET
    CHECK_AND_PRINT_DOT ENDP
        
START:    
    MOV AX, DATA
    MOV DS, AX
    MOV DX, MY8254_MODE         ;Working mode of 8254
    MOV AL, 36H                 ;Timer0, mode 3
    OUT DX, AL
     
    ; Print the prompt
    MOV DX, OFFSET PROMPT
    MOV AH, 9 
    INT 21H
            
BEGIN:    
    MOV LINE_CNT, 0   
    MOV LINE_NO, 0
    MOV NOTES_DONE, 0
    MOV SI, OFFSET FREQ_LIST    ;Load offset of FREQ_LIST 
    MOV DI, OFFSET TIME_LIST    ;Load offset of TIME_LIST
    MOV BX, OFFSET NOTE_LIST
    
PLAY:    
    MOV DX, 0FH                 ;Input CLK = 1MHz = 0F4240H  
    MOV AX, 4240H
    DIV WORD PTR [SI]           ;Fetch the frequency of each music note: 0F4240H / frequency
                                ;AX = quotient = initial value    
                                
    MOV DX, MY8254_COUNT0
    OUT DX, AL                  ;Load the low byte of initial value
    MOV AL, AH
    OUT DX, AL                  ;Load the high byte of initial value
           
    MOV DL, [DI]               ;Fetch the beat from TIME_LIST to delay 
    CALL DALLY 
    CALL PRINT_SPACE
    
    ; Print the note number
    MOV DL, [BX]
    ADD DL, 30H
    MOV AH, 2
    INT 21H
    
    ; Check if we need to print a dot based on frequency
    CALL CHECK_AND_PRINT_DOT
    
    ; Increment notes counter
    INC NOTES_DONE
    
    ; Check if we need a new line
    CALL CHECK_NEWLINE
    
    ADD SI, 2
    INC DI  
    INC BX
    
    ; Check for end of song (0 in FREQ_LIST or NOTE_LIST)
    CMP WORD PTR [SI], 0    
    JE BEGIN                   ;Play repeatedly   
    
    JMP PLAY                   ;Play the next music note

DALLY PROC                      ;delay, parameter is DL   
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX   
    
D0:        
    MOV CX, 0010H              ;Delay Time = DL * CX * 0F00H
D1:        
    MOV AX, 0F00H
D2:        
    DEC AX
    JNZ D2
    LOOP D1
    DEC DL
    JNZ D0 
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DALLY ENDP  

CODE ENDS
    END START