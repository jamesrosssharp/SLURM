Peripherals
===========

This document describes the peripheral register space accessible using IN and OUT instructions.

The peripheral register space is 64kB (16 bit address), although much of it is unused.

UART
----

The UART is only a transmitter (I guess it's a UAT). It's base address
is 0x0000.

|  Address         | Function   | Read/Write?                              |
|------------------|------------|------------------------------------------|
|  0x0000          | TX register| Write only. Reads as status bit.         |
|  0x0000 - 0x000f | Status     | Read only. Lowest bit indicates TX done. |

The registers are repeated throughout a 4kB block (0x0000 - 0x0fff).

GPIO
----

The GPIO block sits at address 0x1000.

PWM
---

The RGB led PWM controller sits at address 0x2000.

Audio
-----

The audio peripheral sits at base address 0x3000 on the peripheral bus.

|  Address        | Function                      | Read/Write? |
|-----------------|-------------------------------|-------------|
|  0x3000 - 0x31ff| Left Channel BRAM             | Write only  |
|  0x3200 - 0x33ff| Right Channel BRAM            | Write only  |
|  0x3400         | Control register (bit 0 = run)| Write only  |
|  0x3401         | Left read pointer             | Read only   |
|  0x3402         | Right read pointer            | Read only   |

