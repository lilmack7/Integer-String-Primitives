TITLE String Primitives & Macros     (Proj6_mackenai.asm)

; Author: Aidan MacKenzie
; Last Modified: 03/18/2023
; OSU email address: mackenai@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number:    Project 6             Due Date: 03/19/2023
; Description:	This program will introduce itself and the programmer. It will use macros to display a prompt, then receive
;				the user's input, as well as to print a string which is stored in a specified memory location. From there,
;				it will use string primitives to convert the user input to the appropriate numeric value representations, 
;				validating the user's input to ensure that it in fact translates to a proper numeric value. It will then
;				use another procedure to then convert a numberical value to its ASCII representation, which will be printed
;				by the macro detailed earlier. Finally, the numbers input by the user will be stored in an array, and displayed
;				along with their sum and truncated average; it will then bid the user farewell.

INCLUDE Irvine32.inc

;----------------------------------------------------------------------------------
; Name: mGetString
;
; Prompts user for string input, stores string and length of string
;
; Preconditions: none
;
; Postconditions: Restores registers EAX, EBX, ECX, EDX
;
; Receives: inputPrompt = prompt address
;			userValue = buffer address
;			allowedLength = buffer size
;			lengthRead = address for number of characters entered
;
; Returns: Fills userInput with user's input, fills lengthRead  with input length
;----------------------------------------------------------------------------------

mGetString MACRO inputPrompt:REQ, userValue:REQ, allowedLength:REQ, lengthRead:REQ
	
   ; Saves used registers
   PUSH EDX
   PUSH	ECX
   PUSH	EBX
   PUSH	EAX

   ; Displays prompt to user
   MOV	EDX, inputPrompt
   CALL	WriteString

   ; Takes user input, stores number of characters
   MOV	EDX, userValue
   MOV	ECX, allowedLength
   CALL	ReadString
   MOV	userValue, EDX
   MOV	[lengthRead], EAX

   ; Restores used registers
   POP	EDX
   POP	ECX
   POP	EBX
   POP	EAX

ENDM

;----------------------------------------------------------------------------------
; Name: mDisplayString
;
; Prints string stored in a specific memory location
;
; Preconditions: none
;
; Postconditions: Restores register EDX
;
; Receives: inputString = string address
;
; Returns: Prints the specified string
;----------------------------------------------------------------------------------

mDisplayString MACRO inputString:REQ

   ; Displays string, restores used register
   PUSH	EDX
   MOV	EDX, inputString
   CALL	WriteString
   POP	EDX

ENDM

MAXLENGTH = 200
MAXPOSITIVE = 2147483647
MAXNEGATIVE = 2147483648

.data

intro			BYTE "Programming Project 6: Building low-level I/O procedures-", 13, 10,
					 "By Aidan MacKenzie", 13, 10, 13, 10, 0

instruction		BYTE "Enter ten signed decimal integers. Please note that each number needs to be small", 13, 10,
					 "enough to fit in a 32 bit register. After number input is complete, I will show", 13, 10,
					 "you a list of the integers, their sum, and their truncated average. Do enjoy.", 13, 10, 13, 10, 0

userArray		SDWORD 10 DUP (?)

prompt			BYTE "Enter a signed number: ", 0
userInput		BYTE 201 DUP (0)
inputLength		DWORD ?
errorMsg		BYTE "ERROR: Your input isn't a signed number or the number was too large. Please try again.", 13, 10, 0
currentInt		SDWORD ?

summaryMsg		BYTE "You entered the following valid numbers:", 13, 10, 0
negativeSign	BYTE "-", 0
comma			BYTE ", ", 0
currentStr		BYTE 12 DUP(0)

userSum			SDWORD 0
sumMsg			BYTE 13, 10, "The sum of these numbers is: ", 0

userAverage		SDWORD ?
averageMsg		BYTE 13, 10, "The truncated average is: ", 0

goodbyeMsg		BYTE 13, 10, 13, 10, "Hope you had a real blast! Goodbye!", 13, 10, 0

.code
main PROC

   mDisplayString offset negativeSign

   ; Display intro and instructions
   PUSH	OFFSET intro
   PUSH	OFFSET instruction
   CALL	introduction

   ; Prepare loop and array for filling
   MOV	ECX, 10
   MOV	EDI, OFFSET userArray

_FillArray:

   ; Fills userArray with numeric values
   PUSH	OFFSET currentInt
   PUSH	OFFSET errorMsg
   PUSH	OFFSET inputLength
   PUSH	OFFSET userInput
   PUSH	OFFSET prompt
   CALL	ReadVal

   MOV	EAX, currentInt
   MOV	[EDI], EAX
   ADD	EDI, 4
   LOOP	_FillArray

   MOV	ESI, OFFSET userArray

   ; Prepare and display input summary, set counter
   CALL	CrLf
   mDisplayString OFFSET summaryMsg
   MOV	ECX, 10

_DisplayEntered:

   PUSH	OFFSET negativeSign
   PUSH	OFFSET currentStr
   PUSH	[ESI]
   CALL	WriteVal

   CMP	ECX, 1
   JE	_SkipComma
   mDisplayString OFFSET comma
   ADD	ESI, 4

_SkipComma:

   LOOP	_DisplayEntered

   ; Calculates sum and average of user inputs
   PUSH	OFFSET userAverage
   PUSH	OFFSET userSum
   PUSH	OFFSET userArray
   CALL	sumAndAverage

   ; Displays sum message and sum value
   mDisplayString OFFSET sumMsg
   PUSH	OFFSET negativeSign
   PUSH	OFFSET currentStr
   PUSH	userSum
   CALL WriteVal

   ; Displays truncated average message and value
   mDisplayString OFFSET averageMsg
   PUSH	OFFSET negativeSign
   PUSH	OFFSET currentStr
   PUSH	userAverage
   CALL	WriteVal

   PUSH	OFFSET goodbyeMsg
   CALL farewell


	Invoke ExitProcess,0	; exit to operating system
main ENDP

; ---------------------------------------------------------------
; Name: introduction
;
; Displays introduction, coder, and program instructions to user.
;
; Preconditions: none
;
; Postconditions: Restores register EBP
;
; Receives: memory OFFSETs:
;							[EBP + 8] = address of intro
;							[EBP + 12] = address of instructions
;
; Returns: Prints strings to the console.
; ---------------------------------------------------------------

introduction PROC

   ; Set up stack frame, call macro to display intro and instructions
   PUSH	EBP
   MOV	EBP, ESP
   mDisplayString [EBP + 12]
   mDisplayString [EBP + 8]

   ; Restores used registers, dereferences appropriate bytes
   POP	EBP
   RET	8

introduction ENDP

; --------------------------------------------------------------------
; Name: ReadVal
;
; Prompts user for input, converts the user's input into its
; numeric representation. Displays error in event string is too 
; large, or contains non-digits. Reprompts user until valid input.
;
; Preconditions: mGetString macro exists
;
; Postconditions: Restores registers EDI, ESI, EDX, ECX, EBX, EAX, EBP
;
; Receives: memory OFFSETs: 
;							[EBP + 8] = address of prompt
;							[EBP + 12] = address of userInput
;							[EBP + 16] = address of inputLength
;							[EBP + 20] = address of errorMsg
;                           [EBP + 24] = address of currentInt
;
; Returns: Places numeric representation of user string in currentInt
; --------------------------------------------------------------------

ReadVal PROC

 ; Sets up stack frame, saves registers that will be used
   LOCAL dlStorage:DWORD, signStorage: DWORD, intInProgress: DWORD
   PUSH EDI
   PUSH	ESI
   PUSH	EDX
   PUSH	ECX
   PUSH	EBX
   PUSH	EAX

   ; Set/reset local variables
   MOV	intInProgress, 0
   MOV	dlStorage, 0
   MOV	signStorage, 0

_Start:

   ; Invoke macro to get user's input
   mGetString [EBP + 8], [EBP + 12], MAXLENGTH, [EBP + 16]

   ; Validate that input is appropriate length
   MOV	EBX, [EBP + 16]
   CMP	EBX, 0
   JE	_Error
   CMP	EBX, MAXLENGTH
   JAE	_Error

   ; Prepare for use of primitives, set counter
   MOV	ESI, [EBP + 12]
   CLD
   MOV	ECX, [EBP + 16]

_Calculate:

   ; Loads byte, checks if currently on first character of user input
   CMP	ECX, 0
   JE	_FinalValidate
   LODSB
   CMP	ECX, [EBP + 16]
   JE	_FirstCharCheck
   JMP	_CharCheck

_FirstCharCheck:

   ; Skips sign check if there is only 1 character total
   MOV	EDX, [EBP + 16]
   CMP	EDX, 1
   JE	_CharCheck

   ; Checks first character to see if it's a sign
   CMP	AL, 43  ; Checks if character is plus sign
   JE	_NextChar
   CMP	AL, 45 ; Checks if character is minus sign
   JE	_SetSign

_CharCheck:

   ; Checks character to see if it's a digit
   CMP	AL, 48
   JB	_Error
   CMP	AL, 57
   JA	_Error

   ; Converts positive signed string into numerical value
   SUB	AL, 48
   MOV	DL, AL
   MOV	EAX, intInProgress
   MOV	EBX, 10
   MOV	dlStorage, EDX
   MUL	EBX
   JC	_Error
   ADD	EAX, dlStorage
   JC	_Error
   MOV	intInProgress, EAX
   JMP	_NextChar

_SetSign:

   ; Sets currentSign to 1, to represent being a negative value
   MOV	signStorage, 1

_NextChar:

   DEC	ECX
   JMP	_Calculate

_Error:

   ; Displays error message, reprompts user
   mDisplayString [EBP + 20]
   MOV	intInProgress, 0
   MOV	signStorage, 0
   JMP	_Start


_FinalValidate:

   ; Checks if sign of intInProgress needs changed
   CMP	signStorage, 1
   JE	_SignFlip
   JMP	_NoFlip

_SignFlip:

   ; Checks value fits in negative range of SDWORD
   CMP	intInProgress, MAXNEGATIVE
   JA	_Error

   ; Flips sign of intInProgress
   MOV	EAX, intInProgress
   NEG	EAX
   JMP	_Validated

_NoFlip:

   ; Checks that value fits in positive range of SDWORD
   CMP	intInProgress, MAXPOSITIVE
   JA	_Error
   MOV	EAX, intInProgress

_Validated:

   ; Shifts intInProgress into currentInt
   MOV	EDI, [EBP + 24]
   MOV	[EDI], EAX

   ; Restores used registers, dereferences appropriate bytes
   POP	EAX
   POP	EBX
   POP	ECX
   POP	EDX
   POP	ESI
   POP	EDI
   RET	24

ReadVal ENDP

; --------------------------------------------------------------------
; Name: WriteVal
;
; Converts an integer into the appropriate ASCII characters, then
; displays the ASCII representation.
;
; Preconditions: [EBP + 8] is an integer
;
; Postconditions: Restores registers EDI, EAX, EBX, ECX, EDX, EBP
;
; Receives: memory OFFSETs: [EBP + 8] = value from userArray
;						    [EBP + 12] = address of currentStr
;                           [EBP + 16] = address of negativeSign
;
; Returns: Prints string representation of integer
; --------------------------------------------------------------------

WriteVal PROC

   ; Sets up stack frame, saves registers that will be used
   PUSH	EBP
   MOV	EBP, ESP
   PUSH	EDX
   PUSH	ECX
   PUSH	EBX
   PUSH	EAX
   PUSH	EDI

   ; Checks if value is negative, if negative prints negative sign, makes positive
   MOV	EAX, [EBP + 8]
   OR	EAX, EAX
   JNS	_StringConvert
   mDisplayString [EBP + 16]
   NEG	EAX

_StringConvert:

   ; Prepares divisor, counter, currentStr and final null character
   MOV	EBX, 10
   MOV	ECX, 0
   MOV	EDI, [EBP + 12]
   CLD
   PUSH	0
   INC	ECX

_AsciiConvert:
   ; Converts each digit besides last to ASCII equivalent
   MOV	EDX, 0
   DIV	EBX
   CMP	EAX, 0
   JE	_FinalCharacter
   ADD	EDX, 48
   PUSH	EDX
   INC	ECX
   JMP	_AsciiConvert

_FinalCharacter:

   ; Converts final character to ASCII, starts moving values into currentStr, clears EAX
   ADD	EDX, 48
   PUSH	EDX
   INC	ECX
   MOV	EAX, 0

_TransferAscii:

   ; Moves each ASCII value into currentStr in order via popping
   POP	EAX
   STOSB
   LOOP	_TransferAscii

   ; Display now filled currentStr
   mDisplayString [EBP + 12]

   ; Restores used registers, dereferences appropriate bytes
   POP	EDI
   POP	EAX
   POP	EBX
   POP	ECX
   POP	EDX
   POP	EBP
   RET	12

WriteVal ENDP

; ------------------------------------------------------------------
; Name: sumAndAverage
;
; Calculates the sum and average of user's 10 valid inputs
;
; Preconditions: user must have completed inputting values
;
; Postconditions: Restores registers EAX, EBX, ECX, ESI, EBP
;
; Receives: memory OFFSETs: [EBP + 8] = address of userArray
;							[EBP + 12] = address of userSum
;                           [EBP + 16] = address of userAverage
;
; Returns: userSum = generated sum, userAverage = generated average
; ------------------------------------------------------------------

sumAndAverage PROC

   ; Sets up stack frame, saves registers that will be used
   PUSH	EBP
   MOV	EBP, ESP
   PUSH EAX
   PUSH	EBX
   PUSH	ECX
   PUSH	ESI
  
  ; Set up counter for loop, value from userArray, prepares register for adding
  MOV	ECX, 10
  MOV	ESI, [EBP + 8]
  MOV	EAX, 0

_Summation:

   ; Calculates sum of user inputs
   MOV	EBX, [ESI]
   ADD	EAX, EBX
   ADD	ESI, 4
   LOOP	_Summation

   ; Copies total sum to appropriate variable
   MOV	ECX, [EBP + 12]
   MOV	[ECX], EAX

   ; Calculates the truncated average of user inputs
   MOV	EBX, 10
   CDQ
   IDIV	EBX

   ; Copies truncated average to appropriate variable
   MOV	ECX, [EBP + 16]
   MOV	[ECX], EAX

   ; Restores used registers, dereferences appropriate bytes
   POP	ESI
   POP	ECX
   POP	EBX
   POP	EAX
   POP	EBP
   RET	12

sumAndaverage ENDP

; ---------------------------------------------------------------
; Name: farewell
;
; Displays farewell message to user
;
; Preconditions: none
;
; Postconditions: Restores register EBP
;
; Receives: memory OFFSETs:
;							[EBP + 8] = address of goodbyeMsg
;
; Returns: Prints strings to the console.
; ---------------------------------------------------------------

farewell PROC

   ; Set up stack frame, call macro to display intro and instructions
   PUSH	EBP
   MOV	EBP, ESP
   mDisplayString [EBP + 8]

   ; Restores used registers, dereferences appropriate bytes
   POP	EBP
   RET	4

farewell ENDP

END main
