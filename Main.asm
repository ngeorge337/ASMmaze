; Nick George
; October 2nd, 2015
; Final Project (Maze Game)


INCLUDE Irvine32.inc

.data
menuStrings BYTE "Welcome to the asm Maze Game",10,13,"1. Help/About",10,13,"2. Play",10,13,"3. Review your saved score",10,13,"4. Exit",10,13,0
helpString BYTE "@ <- YOU",10,13,"& <- Score Bonus",10,13,36," <- Bigger Score Bonus",10,13,"F <- The End of the Maze!",10,13,177," <- Impassible Wall :(",10,13,"Use the arrow keys to move around the maze",10,13,"Reach the end before the time runs out to win!",10,13,0
endgameString1 BYTE "Your Score is: ",0
endgameString2 BYTE "1. Save to scores.txt and quit",10,13,"2. Quit without saving",0
loseString BYTE "Time is up! Game Over!",10,13,0
winString BYTE "You Win! A bonus of 3x remaining time has been added to your score!",10,13,0
scoreString BYTE "Score:",0
timeString BYTE "Time:",0
askChoice BYTE "Enter your choice: ",0
askName BYTE "Enter your name: ",0
scoreSaved BYTE "Score saved!",10,13,0
failScoreString BYTE "Score file could not be opened. No score to display.",10,13,0

; the lovely hardcoded maze layout
; 20x21, bottom most y coordinate is for score/timer
; I actually mapped the maze out in an Excel spreadsheet so I had a nice visual to work with...
mazeTable	BYTE	20 DUP(177),10,13	; row 1
RowSize = ($ - mazeTable)
			BYTE	70,32,32,32,177,177,177,32,177,32,32,32,32,32,177,36,32,32,32,177,10,13 ; row 2
			BYTE	177,177,177,32,38,32,177,32,177,32,177,177,177,32,177,177,177,177,32,177,10,13 ; row 3
			BYTE	177,177,177,32,177,32,32,32,32,32,177,177,177,32,177,177,32,32,32,177,10,13 ; row 4
			BYTE	177,36,32,32,177,177,177,177,177,177,177,177,177,32,177,177,32,177,177,177,10,13 ; row 5
			BYTE	177,177,177,177,177,177,32,177,38,177,32,177,177,32,177,177,32,177,177,177,10,13 ; row 6
			BYTE	177,177,12 DUP(32),177,177,32,32,32,177,10,13 ; row 7
			BYTE	177,177,32,13 DUP(177),32,177,177,177,10,13 ; row 8
			BYTE	177,177,32,177,38,32,6 DUP(177),32,177,177,177,32,177,177,177,10,13 ; row 9
			BYTE	177,177,32,177,177,32,177,177,9 DUP(32),38,177,177,10,13 ; row 10
			BYTE	177,177,32,177,177,32,177,177,32,177,177,32,177,177,177,32,177,32,177,177,10,13 ; row 11
			BYTE	177,177,7 DUP(32),6 DUP(177),32,177,32,177,177,10,13 ; row 12
			BYTE	13 DUP(177),32,177,32,177,32,32,177,10,13 ; row 13
			BYTE	9 DUP(177),32,177,177,177,32,177,32,177,32,177,177,10,13 ; row 14
			BYTE	177,38,10 DUP(32),177,32,177,177,177,32,177,177,10,13 ; row 15
			BYTE	177,177,32,177,177,177,32,177,177,177,177,32,177,5 DUP(32),177,177,10,13 ; row 16
			BYTE	177,177,32,32,32,177,32,177,177,177,177,32,177,32,177,177,32,177,177,177,10,13 ; row 17
			BYTE	4 DUP(177),32,177,32,32,38,177,177,32,177,32,177,177,32,177,177,177,10,13 ; row 18
			BYTE	4 DUP(177),32,6 DUP(177),32,38,32,6 DUP(177),10,13 ; row 19
			BYTE	20 DUP(177),10,13 ; row 20
			BYTE	20 DUP(32),10,13,0 ; row 21



.code
player STRUCT
	Score DWORD 0
	X BYTE ?
	Y BYTE ?
player ENDS

.data
gamestate BYTE 0		; tells us the game state. In menu (0), or in the game (1), or in end-game screen (2)
gamerunning BYTE 1
wincondition BYTE 0
mazeplayer player <0,4,18>
timeleft DWORD 100
timeiter DWORD 0
lastMove BYTE 0		; 0-up, 1-down, 2-left, 3-right
nameBuffer BYTE 21 DUP(0)
nameSize DWORD 0
fileName BYTE "scores.txt",0
fileHandle DWORD ?

.code
; Resulting character is stored in al
; Offset into the table is stored in edi (for removing score items)
; zero-based!
; put X coord in esi
; put Y coord in ebx
CheckLocation PROC USES ebx esi ecx
	LOCAL row_index:DWORD, column_index:DWORD

	mov row_index,ebx
	mov column_index,esi
	mov ebx,0
	mov esi,0
	mov eax,row_index
	mov ecx,RowSize
	mul ecx

	; This sample was taken from the book and adapted as a procedure
	; this handles the 2-Dimensional array for our maze table/layout
	mov ebx,offset mazeTable
	add ebx,eax
	mov esi,column_index
	xor eax,eax
	mov al,[ebx + esi]

	;mov edi,offset mazeTable
	;add edi,eax
	;add edi,esi
	mov edi,eax
	add edi,esi
	ret
CheckLocation ENDP

ClearMazeChar PROC USES ebx esi ecx
	LOCAL row_index:DWORD, column_index:DWORD

	mov row_index,ebx
	mov column_index,esi
	mov ebx,0
	mov esi,0
	mov eax,row_index
	mov ecx,RowSize
	mul ecx

	; This sample was taken from the book and adapted as a procedure
	; this handles the 2-Dimensional array for our maze table/layout
	mov ebx,offset mazeTable
	add ebx,eax
	mov esi,column_index
	mov dl,32
	mov [ebx + esi],dl
	ret
ClearMazeChar ENDP

DrawMaze PROC USES edx
	xor edx,edx
	mov edx, offset mazeTable
	call WriteString
	ret
DrawMaze ENDP

DrawPlayer PROC USES eax edx
	mov dl,mazeplayer.X
	mov dh,mazeplayer.Y
	call Gotoxy

	mov al,'@'
	call WriteChar
	ret
DrawPlayer ENDP

DrawScore PROC USES eax edx
	mov dl,10
	mov dh,20
	call Gotoxy

	xor edx,edx
	mov edx,offset scoreString
	call WriteString

	mov eax,mazeplayer.Score
	call WriteDec
	ret
DrawScore ENDP

DrawTime PROC USES eax edx
	mov dl,0
	mov dh,20
	call Gotoxy

	xor edx,edx
	mov edx,offset timeString
	call WriteString

	mov eax,timeleft
	call WriteDec
	ret
DrawTime ENDP

DoMainMenu PROC USES edx
	mov edx,offset menuStrings
	call WriteString
	mov edx,offset askChoice
	call WriteString
	call ReadDec
	ret
DoMainMenu ENDP

ShowHelp PROC USES edx
	mov edx,offset helpString
	call WriteString
	ret
ShowHelp ENDP

ShowEndgame PROC USES edx
	call ClrScr
	.IF(wincondition == 0)	; lose the game
		mov edx,offset loseString
		call WriteString
		call WaitMsg
	.ELSEIF(wincondition == 1)
		mov edx,offset winString
		call WriteString
		mov edx,offset endgameString1
		call WriteString
		mov eax,mazeplayer.Score
		call WriteDec
		call CRLF
		mov edx,offset endgameString2
		call WriteString
		call CRLF
		call ReadDec
	.ENDIF
	ret
ShowEndgame ENDP

DoInput PROC USES eax edx ebx esi
	call ReadKey
	.IF(dx == VK_UP) ; up arrow
		dec mazeplayer.Y
		mov lastMove,0
	.ELSEIF(dx == VK_DOWN)	; down arrow
		inc mazeplayer.Y
		mov lastMove,1
	.ELSEIF(dx == VK_LEFT) ; left arrow
		dec mazeplayer.X
		mov lastMove,2
	.ELSEIF(dx == VK_RIGHT) ; right arrow
		inc mazeplayer.X
		mov lastMove,3
	.ENDIF
	
	movzx esi,mazeplayer.X
	movzx ebx,mazeplayer.Y
	call CheckLocation
	.IF(al == 177) ; undo the move if it's not valid
		.IF(lastMove == 0)
			inc mazeplayer.Y
		.ELSEIF(lastMove == 1)
			dec mazeplayer.Y
		.ELSEIF(lastMove == 2)
			inc mazeplayer.X
		.ELSEIF(lastMove == 3)
			dec mazeplayer.X
		.ENDIF
	.ELSEIF(al == 38)	; ampersand = +50 points
		add mazeplayer.Score,50
		movzx esi,mazeplayer.X
		movzx ebx,mazeplayer.Y
		mov dl,32
		call ClearMazeChar
	.ELSEIF(al == 36)	; dollar sign = +200 points
		add mazeplayer.Score,200
		movzx esi,mazeplayer.X
		movzx ebx,mazeplayer.Y
		call ClearMazeChar
	.ELSEIF(al == 'F')	; F ends the game successfully
		mov eax,3
		mul timeleft
		add mazeplayer.Score,eax
		mov wincondition,1
		mov gamestate,2
	.ENDIF
	ret
DoInput ENDP

ReadScore PROC USES edx eax
	mov edx,offset fileName
	call OpenInputFile
	.IF(eax == INVALID_HANDLE_VALUE)	; failed to open file? print out a message
		call ClrScr
		mov edx,offset failScoreString
		call WriteString
		call WaitMsg
	.ELSE
		call ClrScr
		mov fileHandle,eax
		mov edx,offset nameSize
		mov ecx,4
		call ReadFromFile
		mov eax,fileHandle
		mov edx,offset nameBuffer
		mov ecx,nameSize
		call ReadFromFile
		mov eax,fileHandle
		mov edx,offset mazeplayer.Score
		mov ecx,4
		call ReadFromFile

		mov edx,offset nameBuffer
		call WriteString
		call CRLF
		mov edx,offset scoreString
		call WriteString
		call CRLF
		mov eax,mazeplayer.Score
		call WriteDec
		call CRLF
		call WaitMsg
		mov mazeplayer.Score,0	; reset the score
		mov eax,fileHandle
		call CloseFile
	.ENDIF
	ret
ReadScore ENDP

.code
main proc
	.WHILE(gamerunning == 1)	; main menu
		.IF(gamestate == 0)
			call ClrScr
			call DoMainMenu
			.IF(eax == 1)	; help
				call ClrScr
				call ShowHelp
				call WaitMsg
			.ELSEIF(eax == 2)	; play
				call ClrScr
				mov gamestate,1
			.ELSEIF(eax == 3)	; review score (from file)
				call ReadScore
			.ELSEIF(eax == 4)	; quit
				mov gamerunning,0
			.ENDIF
		.ELSEIF(gamestate == 1)	; playing the maze
			call DoInput
			call ClrScr
			call DrawMaze
			call DrawPlayer
			call DrawTime
			call DrawScore

			; I know the following avoids the use of GetMSeconds
			; and in reality this is just a horribly lazy timer
			; but it works, and I needed a delay anyway to reduce flickering
			; (at least on my Windows 10 system, no delay caused serious flickering in the console)
			push eax
			mov eax, 50
			add timeiter,eax
			.IF(timeiter >= 1000)
				mov timeiter,0
				dec timeleft
			.ENDIF
			.IF(timeleft <= 0)
				mov gamestate,2
			.ENDIF
			call Delay
			pop eax
		.ELSEIF(gamestate == 2)	; end game screen (win/lose)
			call ShowEndgame
			.IF(eax == 1)
				call ClrScr
				mov edx,offset askName
				call WriteString
				mov edx,offset nameBuffer
				mov ecx,20
				call ReadString	; get the player's name
				mov nameSize,eax
				mov edx,offset fileName
				call CreateOutputFile	; create the file
				mov fileHandle,eax
				mov edx,offset nameSize
				mov ecx,4
				call WriteToFile	; write the length of the name first
				mov eax,fileHandle
				mov edx,offset nameBuffer
				mov ecx,nameSize
				call WriteToFile	; then write the actual name
				mov eax,fileHandle
				mov edx,offset mazeplayer.Score
				mov ecx,4
				call WriteToFile	; lastly, write the score
				mov eax,fileHandle
				call CloseFile

				call ClrScr
				mov edx,offset scoreSaved
				call WriteString
				call WaitMsg

				mov gamerunning,0
			.ELSEIF(eax == 2)
				mov gamerunning,0
			.ENDIF
		.ENDIF
	.ENDW
	
	;call WaitMsg
	exit
main endp
end main