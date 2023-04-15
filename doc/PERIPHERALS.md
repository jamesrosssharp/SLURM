Peripherals
===========

This document describes the peripheral register space accessible using IN and OUT instructions.

The peripheral register space is 64kB (16 bit address), although much of it is unused.

0x0000 - UART
-------------

The UART is only a transmitter (I guess it's a UAT). It's base address
is 0x0000.

|  Address         | Function   | Read/Write?                              |
|------------------|------------|------------------------------------------|
|  0x0000          | TX register| Write only. Reads as status bit.         |
|  0x0000 - 0x000f | Status     | Read only. Lowest bit indicates TX done. |

The registers are repeated throughout a 4kB block (0x0000 - 0x0fff).

0x1000 - GPIO
-------------

The GPIO block sits at address 0x1000.

|  Address         |      Function    | Read/Write?                                 |
|------------------|------------------|---------------------------------------------|
|  0x1000          | Output register  | Write only. Bits 3:0 control gpios          |
|  0x1001          | Input register   | Read only. Bits 5:0 are inputs from gamepad |

TODO: This block needs to be replaced with external shift registers to support more gamepads.

0x2000 - PWM
------------

The RGB led PWM controller sits at address 0x2000.

|  Address         |      Function    | Read/Write?                                 |
|------------------|------------------|---------------------------------------------|
|  0x2000          | Red register     | Write only. Bits 5:0 are PWM value          |
|  0x2001          | Green register   | Write only		 		    |
|  0x2002	   | Blue register    | Write only				    |

0x3000 - Audio
--------------

The audio peripheral sits at base address 0x3000 on the peripheral bus.

|  Address        | Function                      | Read/Write? |
|-----------------|-------------------------------|-------------|
|  0x3000 - 0x31ff| Left Channel BRAM             | Write only  |
|  0x3200 - 0x33ff| Right Channel BRAM            | Write only  |
|  0x3400         | Control register (bit 0 = run)| Write only  |
|  0x3401         | Left read pointer             | Read only   |
|  0x3402         | Right read pointer            | Read only   |

0x4000 - SPI Flash
------------------

The SPI Flash controller has base address 0x4000

|  Address        | Function                      | Read/Write? |
|-----------------|-------------------------------|-------------|
|  0x4000         | Read address lo	          | Write only  |
|  0x4001         | Read address hi	          | Write only  |
|  0x4002         | Command register	          | Write only  |
|  0x4003         | Data reg                      | Read only   |
|  0x4004         | Status reg                    | Read only   |
|  0x4005         | DMA memory address		  | Write only  |
|  0x4006         | DMA count                     | Write only  | 

0x5000 - Video core
-------------------

Multiple video related modules (spcon, bgcon, copper) are in the 
address range 0x5000 - 0x5fff on the peripheral bus.

0x6000 - Trace code
-------------------

Only really used for simulation and emulation.

0x7000 - Interrupt controller
----------------------------

0x8000 - Scratch pad RAM
------------------------

512 bytes scratchpad RAM tiled in the space 0x8000 - 0x8fff

0x9000 - Timer counter
----------------------

16 bit timer counter with configurable prescaler

Used by e.g. the game/demo system RTOS to profile tasks. 
Could also be used for preemptive sheduling.

|  Address        | Function                      | Read/Write? |
|-----------------|-------------------------------|-------------|
|  0x9000         | control		          | Write only  |
|  0x9001         | count  		          | Read only   |

Control reg:

| 15 - 5 |  4 - 2 |    1    |    0   |
---------|--------|---------|--------|
|   x    |Prescale|  Up /Dn |   En   |

TODO: Match interrupt?

