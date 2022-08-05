Simple Copper
=============

The GFX core has a simple co-processor (copper) to allow register writes to gfx core registers.

The copper has a 512 x 16 bit memory for storing copper lists. The copper list starts at address zero at the start of each frame.

Copper can self-modify its own program memory, so copper lists can be dynamic.

Instruction Set
---------------

0. Nop 

  |15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
  |---|----|----|----|----|----|---|---|---|---|---|---|---|---|---|---|
  |0  | 0  | 0  | 0  |  0 | 0  | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |



1. Jump

  |15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
  |---|----|----|----|----|----|---|---|---|---|---|---|---|---|---|---|
  |0  | 0  | 0  | 1  | x  | x  | x | A | A | A | A | A | A | A | A | A |

    A[8:0] jump to copper address

2. Wait row greater than or equal


  |15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
  |---|----|----|----|----|----|---|---|---|---|---|---|---|---|---|---|
  |0  | 0  | 1  | 0  | x  | x  | R | R | R | R | R | R | R | R | R | R |

    R[9:0] : copper will idle until this row is reached

3. Wait column greater than or equal


  |15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
  |---|----|----|----|----|----|---|---|---|---|---|---|---|---|---|---|
  |0  | 0  | 1  | 1  | x  | x  | C | C | C | C | C | C | C | C | C | C |

    C[9:0] : copper will idle until this column is reached

4. Skip if row greater than or equal

  |15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
  |---|----|----|----|----|----|---|---|---|---|---|---|---|---|---|---|
  |0  | 1  | 0  | 0  | x  | x  | R | R | R | R | R | R | R | R | R | R |

    R[9:0] : copper will skip next instruction if row has been reached, 
    used to break out of loops

5. Skip if column greater than or equal

  |15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
  |---|----|----|----|----|----|---|---|---|---|---|---|---|---|---|---|
  |0  | 1  | 0  | 1  | x  | x  | C | C | C | C | C | C | C | C | C | C |

    C[9:0] : copper will skip next instruction if column has been reached,
    used to break out of loops

6. Load background color register and wait next row


  |15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
  |---|----|----|----|----|----|---|---|---|---|---|---|---|---|---|---|
  |0  | 1  | 1  | 0  | B  | B  | B | B | B | B | B | B | B | B | B | B |

    B[11:0] : color value to load background color. Once loaded,
    the copper will wait for next row (scanline). Used to add a gradient background to every
    scanline.

7. Wait for N rows


  |15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
  |---|----|----|----|----|----|---|---|---|---|---|---|---|---|---|---|
  |0  | 1  | 1  | 1  | x  | x  | N | N | N | N | N | N | N | N | N | N |

    N[9:0] : copper will idle until N rows have passed

8. Wait for N columns


  |15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
  |---|----|----|----|----|----|---|---|---|---|---|---|---|---|---|---|
  |1  | 0  | 0  | 0  | x  | x  | N | N | N | N | N | N | N | N | N | N |

    C[9:0] : copper will idle until N columns have passed

9. Register write

  |15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
  |---|----|----|----|----|----|---|---|---|---|---|---|---|---|---|---|
  |1  | 0  | 0  | 1  | A  | A  | A | A | A | A | A | A | A | A | A | A |

    A[11:0] : address of register

    Next word in the copper memory will be the data to write.

10. X pan write

  |15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
  |---|----|----|----|----|----|---|---|---|---|---|---|---|---|---|---|
  |1  | 0  | 1  | 0 | x  | x  | P | P | P | P | P | P | P | P | P | P |

    P[9:0] : x pan
	
	Short hand to write x panning register

11. X pan write + wait next scanline

  |15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
  |---|----|----|----|----|----|---|---|---|---|---|---|---|---|---|---|
  |1  | 0  | 1  | 1  | x  | x  | P | P | P | P | P | P | P | P | P | P |

    P[9:0] : x pan
	
	Short hand to write x panning register and wait for next scanline

12. Load background color register


  |15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
  |---|----|----|----|----|----|---|---|---|---|---|---|---|---|---|---|
  |1  | 1  | 0  | 0  | B  | B  | B | B | B | B | B | B | B | B | B | B |

    B[11:0] : color value to load background color. Used to add a gradient background to every
    scanline.

13. Load alpha register


  |15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
  |---|----|----|----|----|----|---|---|---|---|---|---|---|---|---|---|
  |1  | 1  | 0  | 1  | 0  | 0  | 0 | 0 | 0 | 0 | 0 | 0 | A | A | A | A |

    A[11:0] : alpha 



12 - 15. Reserved


