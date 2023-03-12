/*

flash_control.h: Routines for programming the flash controller

License: MIT License

Copyright 2023 J.R.Sharp

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#ifndef FLASH_CONTROL_H
#define FLASH_CONTROL_H

void _do_flash_dma(unsigned short base_lo, unsigned short base_hi, unsigned short offset_lo, unsigned short offset_hi, void* address, short count, short wait);
void do_flash_dma(unsigned short base_lo, unsigned short base_hi, unsigned short offset_lo, unsigned short offset_hi, void* address, short count);
void do_flash_dma_full_address(unsigned short base_lo, unsigned short base_hi, unsigned short offset_lo, unsigned short offset_hi, void* address, short count);

#endif
