#!/usr/bin/env python3
"""Convert a legacy slurmasm source (written to be concatenated into one flat
file) into a slurmasm-ng object source:

  - the code goes in section 'text'; in top.s, everything before 'start:' (the
    interrupt vector table) goes in section 'vectors'
  - '.org' lines are dropped (the linker script places the program at 0x200)
  - '.padto 0x8000' switches to section 'hidata', placed at 0x8000 by the
    linker script
  - code following an '.align N' (N >= 16) in the text goes in section
    'aligned', which the linker script aligns to 256 bytes; the section is
    padded to a multiple of 256 so several files can share it
  - every top level label (no '.' in its name) is made global, since the
    original sources all shared one namespace
  - '.end' is appended

usage: legacy-asm.py [--top] [--hidata] in.s out.asm
  --hidata: the whole file follows a '.padto 0x8000' in the original
            concatenation order
"""
import re, sys

args = sys.argv[1:]
top = '--top' in args
hidata = '--hidata' in args
args = [a for a in args if not a.startswith('--')]
src, dst = args
lines = open(src).read().split('\n')

out = []
labels = []
section = None
used_aligned = False

def switch(name):
    global section
    if section != name:
        out.append('\t.section %s' % name)
        section = name

switch('hidata' if hidata else ('vectors' if top else 'text'))

for line in lines:
    code = re.sub(r'//.*', '', line).strip()
    if re.match(r'\.org\b', code):
        continue
    m = re.match(r'\.padto\s+(\S+)', code)
    if m:
        if int(m.group(1).rstrip('h'), 16 if m.group(1).endswith('h') or m.group(1).startswith('0x') else 10) != 0x8000:
            sys.exit('%s: unsupported .padto %s' % (src, m.group(1)))
        switch('hidata')
        continue
    m = re.match(r'([A-Za-z_][A-Za-z0-9_.]*)\s*:', code)
    if m:
        name = m.group(1)
        if top and section == 'vectors' and name == 'start':
            switch('text')
        if '.' not in name:
            labels.append(name)
    m = re.match(r'\.align\s+(\S+)', code)
    if m and section == 'text':
        n = int(m.group(1), 0) if not m.group(1).endswith('h') else int(m.group(1)[:-1], 16)
        if n >= 16:
            switch('aligned')
            used_aligned = True
    out.append(line)

if used_aligned:
    out.append('\t.section aligned')
    out.append('\t.align 0x100')
for l in labels:
    out.append('\t.global %s' % l)
out.append('\t.end')
open(dst, 'w').write('\n'.join(out) + '\n')
