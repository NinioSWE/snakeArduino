;
; Snake.asm
;
; Created: 2019-04-24 16:07:30
; Author : lukas
;


; Replace with your application code
start:
//[En lista med registerdefinitioner]
.Def rRandom= r13
.Def rOldDirX= r14
.Def rOldDirY= r15
.DEF rTemp 	= r16
.DEF rTemp2	= r17	
.DEF rTemp3	= r18
.DEF rTemp4	= r19
.DEF rTemp5	= r20
.DEF rTemp6	= r21
.DEF rInX  	= r22
.DEF rInY  	= r23
.Def rGLC	= r24
.Def rApplePos	= r25




//[En lista med konstanter]
/* t ex
.EQU NUM_COLUMNS   = 8
.EQU MAX_LENGTH    = 25
…
*/

//[Datasegmentet]
.DSEG
Matrix:	.BYTE 8
Length: .BYTE 1
BodyPositions:	.BYTE 65

//[Kodsegmentet]
/* t ex */
.CSEG
// Interrupt vector table
.ORG 0x0000
     jmp init // Reset vector
//... fler interrupts
.ORG INT_VECTORS_SIZE
init:

	 //setting start direction to left (x = -1, y = 0)
	 ldi rtemp, -1
	 mov rolddirx, rtemp
 	 ldi rtemp, 0
	 mov rolddiry, rtemp


	 //setting start length to 3 
	 ldi rtemp, 3
	 ldi YH, high(length)
	 ldi YL, low(length)
	 st y, rtemp

     // Setting stack pointer
     ldi rTemp, HIGH(RAMEND)
     out SPH, rTemp
     ldi rTemp, LOW(RAMEND)
     out SPL, rTemp

	 //startup input axises (joystick) 
    lds  rTemp, ADMUX
    andi rTemp, 0b0001_1111
    ori  rTemp, 0b0110_0000
    sts  ADMUX, rTemp

    lds  rTemp,  ADCSRA
    andi rTemp,  0b0111_1000
    ori  rTemp,  0b1000_0111
    sts  ADCSRA, rTemp

	//Sets the bodyPositions list to 0 
	ldi YH, HIGH(BodyPositions)
	ldi YL, LOW(BodyPositions)
	ldi rTemp2, 64
	ldi rTemp, 0
	loop:
	subi rtemp2, 1
	subi YL, -1
	st Y, rTemp
	cpi rtemp2, 0 
	brne  loop

	//           00_YYY_XXX
	//           sets startposition to 36
	ldi rTemp, 0b00_100_100 
	ldi YL, LOW(BodyPositions)
	st Y, rTemp


	 /*
	 // SETUP timer scaling
	 in rTemp, TCCR0B
	 andi rTemp, 0b11111000
	 ori rTemp, 0b00000101
	 out TCCR0B, rTemp
	 */
	//set portD for out put no override..
	in  rTemp , DDRD
	ori rTemp ,0b1111_1100
	out	DDRD, rTemp
	//set portC for out put no override..
	in  rTemp , DDRC
	ori rTemp ,0b0000_1111
	out	DDRC, rTemp
	//set portB for out put no override..
	in  rTemp , DDRB
	ori rTemp ,0b0011_1111
	out	DDRB, rTemp
	//create matrix and set all to zero
	ldi rTemp, 0b0000_0000
	
	ldi YH, HIGH(Matrix)
	ldi YL, LOW(Matrix)
	st	Y, rTemp
	std	Y+1, rTemp
	std	Y+2, rTemp
	std	Y+3, rTemp
	std	Y+4, rTemp
	std	Y+5, rTemp
	std	Y+6, rTemp
	std	Y+7, rTemp
	
	//create an Apple
    call createApple

gameLoop:
	// add rGlC with 1
	subi rGLC, -1
	call getDirection
	cpi rGLC, 0b1111_1111


	brne callDrawCall
	//if rGLC == 255 run game logic
	//call getInput
	/*ldi YH, HIGH(Matrix)
	ldi YL, LOW(Matrix)
	st	Y, rInY
	std	Y+1, rInX*/
	call getInput
	call moveHead
	call checkCollision

	callDrawCall:
	call drawCall

jmp gameLoop

drawCall:
	//Set srow[t3] to 1
ldi YH, HIGH(Matrix)
ldi YL, LOW(Matrix)

//row bitmask
ldi rTemp4, 0b1

drawRows:
	// set current row to 1 and stop all other rows
	mov rTemp, rTemp4
	//Take first 4 from bitmask
	andi rTemp, 0b0000_1111

	in rTemp2, PORTC
	andi rTemp2, 0b1111_0000
	//keep last 4 in PortC
	or rTemp2, rTemp
	mov rTemp3, rTemp2

	mov rTemp, rTemp4
	lsr rTemp
	lsr rTemp
	andi rTemp, 0b0011_1100
	in rTemp2, PORTD
	andi rTemp2, 0b1100_0011
	or rTemp2, rTemp
	mov rTemp6, rTemp2

	//sets all columns
	call drawColumns

	out PORTB, rTemp2
	out PORTC, rTemp3
	out PORTD, rTemp6

	call wait

	ldi rTemp2, 0
	out PORTB, rTemp2
	out PORTC, rTemp2
	out PORTD, rTemp2


	lsl rTemp4
	cpi rTemp4, 0
	brne drawRows
ret

wait:
	ldi rTemp2, 128
waitLoop:
	ldi rTemp, 0
	out TCNT0, rTemp
	sei
	sleep
	subi rTemp2, 1
	cpi rTemp2, 0
	brne waitLoop
ret

drawColumns:
//D columns
	ld	rTemp2, Y
	andi rTemp2, 0b1100_0000

	in  rTemp, portd
	andi  rTemp, 0b0011_1111
	mov rTemp5, rTemp2
	andi rTemp5, 0b1000_0000
	andi rTemp2, 0b0100_0000
	lsr rTemp5
	lsl rTemp2
	or rTemp2, rTemp5
	or rTemp2, rTemp
	or rTemp6, rTemp2
//B columns

	ld	rTemp2, Y+


	mov rTemp5, rTemp2
	mov rTemp, rTemp2
	andi rTemp5, 0b0000_0001
	andi rTemp, 0b0010_0000
	lsl rTemp5
	lsl rTemp5
	lsl rTemp5
	lsl rTemp5
	lsl rTemp5
	
	lsr rTemp
	lsr rTemp
	lsr rTemp
	lsr rTemp
	lsr rTemp

	andi rTemp2, 0b1101_1111
	or rTemp2, rTemp5
	andi rTemp2, 0b1111_1110
	or rTemp2, rTemp


	mov rTemp5, rTemp2
	mov rTemp, rTemp2
	andi rTemp5, 0b0000_0010
	andi rTemp, 0b0001_0000
	lsl rTemp5
	lsl rTemp5
	lsl rTemp5

	lsr rTemp
	lsr rTemp
	lsr rTemp

	andi rTemp2, 0b1110_1111
	or rTemp2, rTemp5
	andi rTemp2, 0b1111_1101
	or rTemp2, rTemp

	mov rTemp5, rTemp2
	mov rTemp, rTemp2
	andi rTemp5, 0b0000_0100
	andi rTemp, 0b0000_1000
	lsl rTemp5

	lsr rTemp
	andi rTemp2, 0b1111_0111
	or rTemp2, rTemp5
	andi rTemp2, 0b1111_1011
	or rTemp2, rTemp


ret

	
getInput:
    //setup for y
    lds rTemp, ADMUX
    andi rTemp, 0b1111_0000
    ori rTemp, 0b0000_0100
    sts ADMUX, rTemp

    lds rTemp, ADCSRA
    andi rTemp,0b1011_1111
    ori rTemp, 0b0100_0000
    sts ADCSRA, rTemp
        
    waituntil:
	lds rTemp, ADCSRA
    sbrc rTemp, ADSC
    jmp waituntil
    
    //store analog-y value in rInY
    lds rInY, ADCH

    //setup for x
    lds rTemp, ADMUX
    andi rTemp, 0b1111_0000
    ori rTemp,  0b0000_0101
    sts ADMUX, rTemp

    lds rTemp, ADCSRA
    andi rTemp, 0b1011_1111
    ori rTemp,  0b0100_0000
    sts ADCSRA, rTemp
        
    waituntil2:
	lds rTemp, ADCSRA
    sbrc rTemp,ADSC
    jmp waituntil2

    //store analog-x value in rInX
    lds rInX, ADCH
ret

moveHead:
	
	ldi ZH, HIGH(length)
	ldi ZL, LOW(length)
	ld rTemp, Z
	mov rtemp6, rTemp
	// "important bytes" depends on the length of the snake
	// move all "important bytes" up one position in memory
	ldi YH, HIGH(bodypositions)
	ldi YL, LOW(bodypositions) 
	add YL, rTemp
	subi YL, 1
	loopagain:
	cpi rTemp, 0 
	breq doneloopagain

	ld rtemp2, Y

	std Y+1, rtemp2

	subi YL, 1 
	subi rtemp, 1
	jmp loopagain
	doneloopagain:

	//turn off tail
	//get last position in the bodypositions list and store it in rtemp3
	ldi ZH, HIGH(bodypositions)
	ldi ZL, LOW(bodypositions)
	add ZL , rtemp6
	ld rtemp3, Z
	
	//mask out the x and y value of the last position in the bodypositions list and store it in rtemp2(x) and rtemp3(y).
	mov rtemp2, rtemp3
	andi rtemp2, 0b0000_0111
	andi rtemp3, 0b0011_1000
	lsr rtemp3
	lsr rtemp3
	lsr rtemp3


	//load matrix with correct y value and store the byte in rtemp
	ldi YH, HIGH(Matrix)
	ldi YL, LOW(Matrix)
	add YL, rtemp3
	ld rtemp, y

	//get bitmask for x in matrixrow 
	//right shift as many times as the x value
	mov rtemp3,rtemp2
	ldi rtemp2, 0b1000_0000
	shiftloop2:
	cpi rtemp3, 0
	breq doneWithMask2
	lsr rtemp2
	subi rtemp3,1
	jmp shiftloop2
	doneWithMask2:
	//turn off the bit that was the overflowing tail
	com rtemp2
	and rtemp,rtemp2
	//store the byte in matrix
	st Y, rTemp







	//oldheadposition in bodyposition + 1
	ldi YH, HIGH(bodypositions)
	ldi YL, LOW(bodypositions)
	ldd rtemp3, Y+1
	mov rtemp2, rtemp3
	andi rtemp2, 0b0000_0111
	andi rtemp3, 0b0011_1000
	lsr rtemp3
	lsr rtemp3
	lsr rtemp3
	//rTemp2 = oldhead x
	//rtemp3 = oldead y

	call getDirection
	//direction in rtemp4(x) and rtemp5(y)

	//add direction y to old head position(y) to get the new head position(y)
	add rtemp3, rtemp5
	andi rtemp3, 0b0000_0111
	//get the row thats gonna have the new head
	ldi YH, HIGH(Matrix)
	ldi YL, LOW(Matrix)
	add YL, rtemp3
	//matrix byte stored in rtemp
	ld	 rTemp, Y
	
	//add direction x to old head position(x) to get the new head position(x)
	add rtemp2, rtemp4
	andi rtemp2, 0b0000_0111

	//set rtemp3 to xy position (in this way 0b00yyyxxx)
	// rtemp3 = y(0b00000yyy) and rtemp2 = x(0b00000xxx)
	mov rtemp4, rtemp3 
	lsl rtemp3
	lsl rtemp3
	lsl rtemp3
	add rtemp3, rtemp2
	
	//store the new headposition in bodypositions
	ldi XH, HIGH(bodypositions)
	ldi XL, LOW(bodypositions)
	st  X, rtemp3

	//draw new head in matrix
	// rtemp4 = y(0b00000yyy) 
	// rtemp2 = x(0b00000xxx) 
	//get the correct row for the new head and store the byte in rtemp
	ldi YH, HIGH(matrix)
	ldi YL, LOW(matrix)
	add yl, rtemp4
	ld rtemp, Y

	//get bitmask for x in matrixrow 
	//right shift as many times as the x value
	mov rtemp3,rtemp2
	ldi rtemp2, 0b1000_0000
	shiftloop3:
	cpi rtemp3, 0
	breq doneWithMask3
	lsr rtemp2
	subi rtemp3,1
	jmp shiftloop3
	doneWithMask3:
	//bitmask for x in matrix row -> temp2
	//set x bit as 1 in rtemp
	or rtemp,rtemp2
	//store the new byte in matrix
	st Y, rTemp
	
	 done:
ret


getDirection:
//får inte ändra på rtemp2 och rtemp3 ska även returnera rtemp4(x) och rtemp5(y)
	//subtract 2 from rRandom to make it "feel more random"
	ldi rtemp4, 2
	sub rRandom, rtemp4

	//reset dirX and dirY to 0 
	ldi rtemp5, 0
	ldi rtemp4, 0
	//set rtemp5 to -1 or 1 if direction was up or down
	//set rtemp4 to -1 or 1 if direction was left or right
	up:
	cpi rInY, 240
	brlo down 
	ldi rtemp5, -1
	ldi rtemp4, 0
	jmp returnDirection
	down:
	cpi rInY, 10
	brsh left
	ldi rtemp5, 1
	ldi rtemp4, 0
	jmp returnDirection
	left:
	cpi rInX, 240
	brlo right
	ldi rtemp5, 0
	ldi rtemp4, -1
	jmp returnDirection
	right:
	cpi rInX, 10
	brsh normalCase
	ldi rtemp5, 0
	ldi rtemp4, 1
	jmp returnDirection

	//will not work with most analog sticks.
	//change to range 100-140
	//Make more random "feel"
	normalCase:
	cpi rInX, 127
	breq newNormalCase
	cpi rInY, 138
	breq newNormalCase
	add rRandom, rInX
	com rRandom
	lsr rRandom
	add rRandom, rInY
	lsr rRandom
	lsr rRandom
	newNormalCase:

	//keep moving in the same direction
	mov rtemp4, rolddirx
	mov rtemp5, rolddiry
	jmp rt

	returnDirection:


	//store input in rolddirx, rolddiry
	//
	neg rolddirx
	neg rolddiry
	cp rolddirx, rtemp4
	brne retdir
	cp rolddiry, rtemp5
	brne retdir

	//if direction was not allowed (example going from right to left)
	// use old direction
	neg rolddirx
	mov rtemp4, rolddirx
	neg rolddirx
	
	neg rolddiry
	mov rtemp5, rolddiry
	neg rolddiry

	retdir:
	//make rolddirx and rolddiry to its "normal" value
	neg rolddirx
	neg rolddiry
	
	//store direction in rolddirx, rolddiry
	mov rolddirx, rtemp4
	mov rolddiry, rtemp5

	rt:
ret


checkCollision:
	//rtemp2 = (length - 1)
	// Z is a pointer to length
	ldi ZH, HIGH(length)
	ldi ZL, LOW(length)
	ld rtemp4, Z
	mov rtemp2, rtemp4
	subi rtemp2, 1


	//rtemp is position of head
	ldi YH, HIGH(bodypositions)
	ldi YL, LOW(bodypositions)
	ld rtemp, Y

	//loop bodypositions
	loopColision:
	cpi rtemp2, 0
	breq noCollision
	subi yl, -1
	//rtemp3 is position of the current body in the loop
	ld rtemp3, Y
	//if head position is the same as current bodyposition then the game is over
	cp rtemp3, rtemp
	breq yesCollision
	//subtract 1 from rtemp2 and loop next bodypart
	subi rtemp2, 1
	jmp loopColision
	yesCollision:
	//restart the game
	jmp init
	noCollision:
	//check if head is colliding with an apple
	cp rtemp, rApplePos
	brne doneCollision
	//if collision with apple add 1 to length
	subi rtemp4, -1
	st Z, rtemp4
	call createApple
	doneCollision:
ret

createApple:
	//copy rRandom to rApplePos and mask out the first 6 bits so we get a value between 0-63
	mov rApplePos, rRandom 
	andi rApplePos, 0b0011_1111
	
	//set Z to as a pointer to address length
	ldi ZH, HIGH(length)
	ldi ZL, LOW(length)
	//set Y to as a pointer to address bodypositions
	ldi YH, HIGH(bodypositions)
	ldi YL, LOW(bodypositions)

	CheckCollisionAgain:
	ldi YL, LOW(bodypositions)
	
	//rTemp2 = length
	ld rtemp2, Z
	//forloop
	PositionLoop:
	//rtemp = current bodyposition
	ld rtemp, Y
	// check if rtemp2 == 0
	cpi rtemp2, 0
	breq PositionLoopDone
	
	// rApplePos != rtemp (check if applePosition is the same as the current bodyPart)
	cp rApplePos, rtemp
	brne reloop
	//rApplePos == bodyPart.Position add 1 to rApplePos and mask out the first 6 bits and check collision again 
	subi rApplePos,-1
	andi rApplePos ,0b0011_1111
	jmp CheckCollisionAgain
	// if collision did not occur
	reLoop:
	//add 1 to YLow so that it points to the next body part in our list(bodypositions) 
	//subtract rtemp2 with 1 and jump to PositionLoop again
	subi yl, -1
	subi rtemp2,1
	jmp PositionLoop
	PositionLoopDone:
	//forloopdone

	//rtemp = x rtemp2 = y
	mov rtemp, rApplePos
	mov rtemp2, rApplePos
	andi  rtemp, 0b0000_0111
	andi  rtemp2, 0b0011_1000
	lsr rtemp2
	lsr rtemp2
	lsr rtemp2
	
	//set Z as a pointer to Matrix and add rtemp2(y) so that we get the right row byte
	ldi ZH, HIGH(Matrix)
	ldi ZL, LOW(Matrix)
	add ZL, rtemp2
	ld rtemp4, Z
	//rightrow byte in rtemp4
	
	// rtemp3 = x
	// right shift (0b1000_0000) x times and set bit for apple to 1 with out overriding the other bits
	mov rtemp3,rtemp
	ldi rtemp2, 0b1000_0000
	shiftloop4:
	cpi rtemp3, 0
	breq doneWithMask4
	lsr rtemp2
	subi rtemp3,1
	jmp shiftloop4
	doneWithMask4:
	//bit mask for x in matrix row temp2
	// this might be unnecessary
	com rtemp2
	and rtemp4,rtemp2
	com rtemp2
	
	or rtemp4,rtemp2

	//store the new byte in Z(Matrix)
	st Z, rtemp4

ret
