        .org 0h

CHAR_H  equ  'H' // 0x0048
CHAR_E  equ  'e' // 0x0065
CHAR_L  equ CHAR_E + 7
CHAR_O  equ  'o' // 0x006f

        // set up a stack

        load r0, (StackEnd & 0x0000ffff)
        load r1, (StackEnd & 0xffff0000) >> 16
        ldspr s8, r0

start:

        // print "Hello World!"

        load r1, CHAR_H
        load r2, CHAR_E
        load r3, CHAR_L
        load r4, CHAR_O
        out  r1, r0 // write 'H' to uart FIFO
        out  r2, r0 // write 'e' to uart FIFO
        out  r3, r0 // write 'l' to uart FIFO
        out  r3, r0 // write 'l' to uart FIFO
        call WaitTXEmpty

        out  r4, r0 // write 'o' to uart FIFO
        load r1, 0x0020 // ' '
        load r2, 0x0057 // 'W'
        load r3, 0x006f // 'o'
        load r4, 0x0072 // 'r'
        out  r1, r0 // ' '
        out  r2, r0 // 'W'
        out  r3, r0 // 'o'
        call WaitTXEmpty

        out r4,  r0     // 'r'
        load r1, 0x006c // 'l'
        load r2, 0x0064 // 'd'
        load r3, 0x0021 // '!'
        out r1, r0 // 'l'
        out r2, r0 // 'd'
        out r3, r0 // '!'
        call WaitTXEmpty

        load r1,  0x000d // '\r'
        load r2,  0x000a // '\n'
        out  r1, r0
        out  r2, r0
        call WaitTXEmpty

        // start night rider animation


        // loop back to start

        jump start

WaitTXEmpty:


        ret


        .align 100h
TheString:
        dw "Hello World!\r\n"


        .align 100h
StackStart:
        .times 100h dw 0x0
StackEnd:

        .end

