// slurm16-sim: a minimal, headless instruction set simulator for the SLURM16
// CPU, used to test the output of the clang backend.
//
// Semantics follow the HDL (src/slurm16_cpu_*.v), including the quirks of the
// ALU flag computation.
//
// Peripherals:
//   - port 0x0000-0x0fff: UART. Writing sends the low byte to stdout, reading
//     returns 1 (transmit done).
//   - port 0x6000-0x6002: trace port (decimal / character / hex), as
//                         src/trace.v
//   - port 0x6006:        end of test (exit 0), as used by the test programs
//   - port 0x6fff:        simulator exit. Writing exits with the value.
// Everything else reads as 0 and ignores writes.
//
// The simulation stops when "sleep" is executed (there are no interrupt
// sources) and exits with the value of r2 (the C return value register).
//
// Usage: slurm16-sim [-t] [-m max_instructions] program.elf

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

namespace {

uint8_t mem[0x20000]; // Lower and upper banks.
uint16_t r[16];
uint16_t pc;
uint16_t immHi;
uint16_t entry;
bool Z, C, S, V;
bool intEnabled;
bool trace;

uint16_t rdWord(uint32_t a) {
  a &= ~1u;
  return mem[a] | (mem[a + 1] << 8);
}

void wrWord(uint32_t a, uint16_t v) {
  a &= ~1u;
  mem[a] = v & 0xff;
  mem[a + 1] = v >> 8;
}

[[noreturn]] void die(const char *msg) {
  fflush(stdout);
  fprintf(stderr, "slurm16-sim: %s (pc=0x%04x)\n", msg, pc);
  exit(125);
}

bool cond(unsigned c) {
  switch (c & 15) {
  case 0: return Z;
  case 1: return !Z;
  case 2: return S;
  case 3: return !S;
  case 4: return C;
  case 5: return !C;
  case 6: return V;
  case 7: return !V;
  case 8: return S ^ V;
  case 9: return Z || (S ^ V);
  case 10: return (S == V) && !Z;
  case 11: return S == V;
  case 12: return C || Z;
  case 13: return !C && !Z;
  default: return true;
  }
}

// Returns the ALU result; updates flags exactly as slurm16_cpu_alu.v.
uint16_t alu(unsigned op, uint16_t A, uint16_t B) {
  uint32_t add = (uint32_t)A + B;
  uint32_t sub = ((uint32_t)A - B) & 0x1ffff;
  uint32_t adc = (uint32_t)A + B + C;
  uint32_t sbb = ((uint32_t)A - B - C) & 0x1ffff;
  int32_t mul = (int32_t)(int16_t)A * (int32_t)(int16_t)B;
  uint32_t umul = (uint32_t)A * B;
  auto sgn = [](uint32_t v) { return (v & 0x8000) != 0; };
  uint16_t out = 0;
  switch (op) {
  case 0: out = B; break;
  case 1:
    out = add;
    C = add >> 16; Z = out == 0; S = sgn(out);
    V = !(sgn(A) ^ sgn(B)) && (sgn(B) ^ sgn(add));
    break;
  case 2:
    out = adc;
    C = (adc >> 16) & 1; Z = out == 0; S = sgn(out);
    V = !(sgn(A) ^ sgn(B)) && (sgn(B) ^ sgn(add));
    break;
  case 3:
  case 12:
    out = op == 12 ? A : (uint16_t)sub;
    C = (sub >> 16) & 1; Z = (sub & 0xffff) == 0; S = sgn(sub);
    V = (sgn(A) ^ sgn(B)) && !(sgn(B) ^ sgn(sub));
    break;
  case 4:
    out = sbb;
    C = (sbb >> 16) & 1; Z = out == 0; S = sgn(out);
    V = (sgn(A) ^ sgn(B)) && !(sgn(B) ^ sgn(sub));
    break;
  case 5: out = A & B; Z = out == 0; C = 0; S = sgn(out); break;
  case 6: out = A | B; Z = out == 0; C = 0; S = sgn(out); break;
  case 7: out = A ^ B; C = 0; S = sgn(A | B); Z = out == 0; break;
  case 8: out = mul; Z = out == 0; C = 0; S = sgn(out); break;
  case 9: out = (uint32_t)mul >> 16; Z = out == 0; C = 0; S = sgn(out); break;
  case 10: out = (B >> 4) | (B << 12); break;
  case 11: out = (B << 4) | (B >> 12); break;
  case 13: out = A; Z = (A & B) == 0; break;
  case 14: out = umul >> 16; Z = out == 0; C = 0; S = sgn(out); break;
  case 15: out = (B >> 8) | (B << 8); break;
  case 16: out = (uint16_t)((int16_t)B >> 1); Z = out == 0; break;
  case 17: out = B >> 1; Z = out == 0; break;
  case 18: out = B << 1; Z = out == 0; break;
  case 19: out = (B << 1) | C; C = B >> 15; break;
  case 20: out = (B >> 1) | (C << 15); C = B & 1; break;
  case 21: out = (B << 1) | (B >> 15); break;
  case 22: out = (B >> 1) | (B << 15); break;
  case 23: C = 0; break;
  case 24: C = 1; break;
  case 25: Z = 0; break;
  case 26: Z = 1; break;
  case 27: S = 0; break;
  case 28: S = 1; break;
  case 29: out = (V << 3) | (S << 2) | (C << 1) | Z; break;
  case 30: C = (B >> 1) & 1; S = (B >> 2) & 1; Z = B & 1; V = (B >> 3) & 1; break;
  default: break;
  }
  return out;
}

void setReg(unsigned n, uint16_t v) {
  if (n != 0)
    r[n] = v;
}

uint16_t portRead(uint16_t port) {
  if (port < 0x1000)
    return 1;
  return 0;
}

void portWrite(uint16_t port, uint16_t v) {
  if (port < 0x1000) {
    putchar(v & 0xff);
    return;
  }
  // Trace port (src/trace.v): decimal, character, hex.
  if (port == 0x6000) {
    printf("%d", (int16_t)v);
    return;
  }
  if (port == 0x6001) {
    putchar(v & 0xff);
    return;
  }
  if (port == 0x6002) {
    printf("%04x", v);
    return;
  }
  // End of test (used by the existing test programs' exit routine).
  if (port == 0x6006) {
    fflush(stdout);
    exit(0);
  }
  if (port == 0x6fff) {
    fflush(stdout);
    exit(v & 0xff);
  }
}

bool loadElf(const char *path) {
  FILE *f = fopen(path, "rb");
  if (!f)
    return false;
  std::vector<uint8_t> d;
  int c;
  while ((c = fgetc(f)) != EOF)
    d.push_back(c);
  fclose(f);
  if (d.size() < 52 || memcmp(d.data(), "\x7f" "ELF", 4) != 0)
    return false;
  auto u16 = [&](size_t o) { return (uint32_t)d[o] | (d[o + 1] << 8); };
  auto u32 = [&](size_t o) { return u16(o) | (u16(o + 2) << 16); };
  uint32_t shoff = u32(32);
  uint32_t shentsize = u16(46), shnum = u16(48);
  for (uint32_t i = 0; i < shnum; ++i) {
    size_t sh = shoff + i * shentsize;
    if (sh + 40 > d.size())
      return false;
    uint32_t type = u32(sh + 4), addr = u32(sh + 12), off = u32(sh + 16),
             size = u32(sh + 20);
    if (type != 1 /*PROGBITS*/)
      continue;
    if (off + size > d.size() || addr + size > sizeof(mem))
      return false;
    memcpy(mem + addr, d.data() + off, size);
  }
  // Entry point: the "_start" (or "start") symbol, or address 0.
  for (uint32_t i = 0; i < shnum; ++i) {
    size_t sh = shoff + i * shentsize;
    if (u32(sh + 4) != 2 /*SYMTAB*/)
      continue;
    uint32_t off = u32(sh + 16), size = u32(sh + 20), link = u32(sh + 24);
    uint32_t stroff = u32(shoff + link * shentsize + 16);
    for (uint32_t o = off; o + 16 <= off + size; o += 16) {
      const char *name = (const char *)d.data() + stroff + u32(o);
      if (!strcmp(name, "_start") || (!strcmp(name, "start") && !entry))
        entry = u32(o + 4);
    }
  }
  return true;
}

} // namespace

int main(int argc, char **argv) {
  uint64_t maxInsns = 200000000;
  const char *file = nullptr;
  for (int i = 1; i < argc; ++i) {
    if (!strcmp(argv[i], "-t"))
      trace = true;
    else if (!strcmp(argv[i], "-m") && i + 1 < argc)
      maxInsns = strtoull(argv[++i], nullptr, 0);
    else
      file = argv[i];
  }
  if (!file) {
    fprintf(stderr, "usage: %s [-t] [-m max_instructions] program.elf\n",
            argv[0]);
    return 126;
  }
  if (!loadElf(file)) {
    fprintf(stderr, "slurm16-sim: cannot load %s\n", file);
    return 126;
  }

  pc = entry;
  for (uint64_t n = 0; n < maxInsns; ++n) {
    uint16_t ins = rdWord(pc);
    uint16_t thisPc = pc;
    pc += 2;
    uint16_t imm16 = (immHi << 4) | (ins & 0xf);
    unsigned cls = ins >> 12;
    unsigned rd = (ins >> 4) & 0xf, rs = ins & 0xf, ri = (ins >> 8) & 0xf;
    if (trace)
      fprintf(stderr, "%04x: %04x  r1=%04x r2=%04x r3=%04x r4=%04x r5=%04x "
                      "r13=%04x r15=%04x %c%c%c%c\n",
              thisPc, ins, r[1], r[2], r[3], r[4], r[5], r[13], r[15],
              Z ? 'Z' : '-', C ? 'C' : '-', S ? 'S' : '-', V ? 'V' : '-');

    bool keepImm = false;
    switch (cls) {
    case 0x0:
      switch ((ins >> 8) & 0xf) {
      case 0x0: // nop: does not consume imm
        keepImm = true;
        break;
      case 0x1:
        if (ins & 1) {
          pc = r[14];
          intEnabled = true;
        } else {
          pc = r[15];
        }
        break;
      case 0x2: // stix
        setReg(rs, (immHi << 4) | (V << 3) | (S << 2) | (C << 1) | Z);
        break;
      case 0x3: // rsix
        break;
      case 0x4: {
        unsigned op = 16 + ((ins >> 4) & 0xf);
        uint16_t res = alu(op, r[rs], r[rs]);
        if (op <= 22 || op == 29)
          setReg(rs, res);
        break;
      }
      case 0x6:
        intEnabled = ins & 1;
        break;
      case 0x7: // sleep: no interrupt sources, so the simulation ends.
        fflush(stdout);
        if (trace)
          fprintf(stderr, "slurm16-sim: sleep, %llu instructions\n",
                  (unsigned long long)n);
        return r[2] & 0xff;
      default:
        die("illegal instruction");
      }
      break;
    case 0x1:
      immHi = ins & 0xfff;
      keepImm = true;
      break;
    case 0x2:
    case 0x3: {
      unsigned op = (ins >> 8) & 0xf;
      uint16_t B = cls == 2 ? r[rs] : imm16;
      uint16_t res = alu(op, r[rd], B);
      if (op != 12 && op != 13)
        setReg(rd, res);
      break;
    }
    case 0x4: {
      unsigned c = (ins >> 8) & 0xf;
      if (cond(c)) {
        uint16_t target = r[rd] + imm16;
        if (c == 15)
          r[15] = pc;
        pc = target;
      }
      break;
    }
    case 0x5:
      if (cond((ins >> 8) & 0xf))
        setReg(rd, r[rs]);
      break;
    case 0x6:
      die("extended register instructions are not supported");
    case 0x7: {
      uint32_t a = 0x10000 + r[ri];
      unsigned flg = ins & 7;
      if (flg == 0)
        setReg(rd, rdWord(a));
      else if (flg == 1)
        setReg(rd, mem[a]);
      else if (flg <= 3)
        setReg(rd, (uint16_t)(int16_t)(int8_t)mem[a]);
      else if (flg <= 5)
        wrWord(a, r[rd]);
      else
        mem[a] = r[rd] & 0xff;
      break;
    }
    case 0x8:
      setReg(rd, (uint16_t)(int16_t)(int8_t)mem[(uint16_t)(r[ri] + imm16)]);
      break;
    case 0x9: {
      // The imm prefix holds the condition and ALU operation.
      unsigned op = immHi & 0xf, c = (immHi >> 4) & 0xf;
      unsigned dst = (ins >> 8) & 0xf, a = (ins >> 4) & 0xf, b = ins & 0xf;
      if (cond(c)) {
        uint16_t res = alu(op, r[a], r[b]);
        if (op != 12 && op != 13)
          setReg(dst, res);
      }
      break;
    }
    case 0xa:
      setReg(rd, mem[(uint16_t)(r[ri] + imm16)]);
      break;
    case 0xb:
      mem[(uint16_t)(r[ri] + imm16)] = r[rd] & 0xff;
      break;
    case 0xc:
      setReg(rd, rdWord((uint16_t)(r[ri] + imm16)));
      break;
    case 0xd:
      wrWord((uint16_t)(r[ri] + imm16), r[rd]);
      break;
    case 0xe:
      setReg(rd, portRead(r[ri] + imm16));
      break;
    case 0xf:
      portWrite(r[ri] + imm16, r[rd]);
      break;
    }
    if (!keepImm)
      immHi = 0;
  }
  fflush(stdout);
  fprintf(stderr, "slurm16-sim: instruction limit reached (pc=0x%04x)\n", pc);
  return 124;
}
