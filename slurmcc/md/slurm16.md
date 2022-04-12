%{
#define INTTMP 0x03C0
#define INTVAR 0x1C00
#define FLTTMP 0x000f0ff0
#define FLTVAR 0xfff00000

#define INTRET 0x0004
#define FLTRET 0x00000003

#define readsreg(p) \
        (generic((p)->op)==INDIR && (p)->kids[0]->op==VREG+P)
#define setsrc(d) ((d) && (d)->x.regnode && \
        (d)->x.regnode->set == src->x.regnode->set && \
        (d)->x.regnode->mask&src->x.regnode->mask)

#define relink(a, b) ((b)->x.prev = (a), (a)->x.next = (b))

#include "c.h"
#define NODEPTR_TYPE Node
#define OP_LABEL(p) ((p)->op)
#define LEFT_CHILD(p) ((p)->kids[0])
#define RIGHT_CHILD(p) ((p)->kids[1])
#define STATE_LABEL(p) ((p)->x.state)
static void address(Symbol, Symbol, long);
static void blkfetch(int, int, int, int);
static void blkloop(int, int, int, int, int, int[]);
static void blkstore(int, int, int, int);
static void defaddress(Symbol);
static void defconst(int, int, Value);
static void defstring(int, char *);
static void defsymbol(Symbol);
static void doarg(Node);
static void emit2(Node);
static void export(Symbol);
static void clobber(Node);
static void function(Symbol, Symbol [], Symbol [], int);
static void global(Symbol);
static void import(Symbol);
static void local(Symbol);
static void progbeg(int, char **);
static void progend(void);
static void segment(int);
static void space(int);
static void target(Node);
static int      bitcount       (unsigned);
static Symbol   argreg         (int, int, int, int, int);

static Symbol ireg[32], freg2[32], d6;
static Symbol iregw, freg2w;
static int tmpregs[] = {3, 9, 10};
static Symbol blkreg;

static int gnum = 8;
static int pic;

static int cseg;
%}
%start stmt

%term CNSTF4=4113
%term CNSTI1=1045 CNSTI2=2069 CNSTI4=4117
%term CNSTP2=2071
%term CNSTU1=1046 CNSTU2=2070 CNSTU4=4118

%term ARGB=41
%term ARGF4=4129
%term ARGI2=2085 ARGI4=4133
%term ARGP2=2087
%term ARGU2=2086 ARGU4=4134

%term ASGNB=57
%term ASGNF4=4145
%term ASGNI1=1077 ASGNI2=2101 ASGNI4=4149
%term ASGNP2=2103
%term ASGNU1=1078 ASGNU2=2102 ASGNU4=4150

%term INDIRB=73
%term INDIRF4=4161
%term INDIRI1=1093 INDIRI2=2117 INDIRI4=4165
%term INDIRP2=2119
%term INDIRU1=1094 INDIRU2=2118 INDIRU4=4166

%term CVFF4=4209
%term CVFI2=2165 CVFI4=4213

%term CVIF4=4225
%term CVII1=1157 CVII2=2181 CVII4=4229
%term CVIU1=1158 CVIU2=2182 CVIU4=4230

%term CVPU2=2198

%term CVUI1=1205 CVUI2=2229 CVUI4=4277
%term CVUP2=2231
%term CVUU1=1206 CVUU2=2230 CVUU4=4278

%term NEGF4=4289
%term NEGI2=2245 NEGI4=4293

%term CALLB=217
%term CALLF4=4305
%term CALLI2=2261 CALLI4=4309
%term CALLP2=2263
%term CALLU2=2262 CALLU4=4310
%term CALLV=216

%term RETF4=4337
%term RETI2=2293 RETI4=4341
%term RETP2=2295
%term RETU2=2294 RETU4=4342
%term RETV=248

%term ADDRGP2=2311

%term ADDRFP2=2327

%term ADDRLP2=2343

%term ADDF4=4401
%term ADDI2=2357 ADDI4=4405
%term ADDP2=2359
%term ADDU2=2358 ADDU4=4406

%term SUBF4=4417
%term SUBI2=2373 SUBI4=4421
%term SUBP2=2375
%term SUBU2=2374 SUBU4=4422

%term LSHI2=2389 LSHI4=4437
%term LSHU2=2390 LSHU4=4438

%term MODI2=2405 MODI4=4453
%term MODU2=2406 MODU4=4454

%term RSHI2=2421 RSHI4=4469
%term RSHU2=2422 RSHU4=4470

%term BANDI2=2437 BANDI4=4485
%term BANDU2=2438 BANDU4=4486

%term BCOMI2=2453 BCOMI4=4501
%term BCOMU2=2454 BCOMU4=4502

%term BORI2=2469 BORI4=4517
%term BORU2=2470 BORU4=4518

%term BXORI2=2485 BXORI4=4533
%term BXORU2=2486 BXORU4=4534

%term DIVF4=4545
%term DIVI2=2501 DIVI4=4549
%term DIVU2=2502 DIVU4=4550

%term MULF4=4561
%term MULI2=2517 MULI4=4565
%term MULU2=2518 MULU4=4566

%term EQF4=4577
%term EQI2=2533 EQI4=4581
%term EQU2=2534 EQU4=4582

%term GEF4=4593
%term GEI2=2549 GEI4=4597
%term GEU2=2550 GEU4=4598

%term GTF4=4609
%term GTI2=2565 GTI4=4613
%term GTU2=2566 GTU4=4614

%term LEF4=4625
%term LEI2=2581 LEI4=4629
%term LEU2=2582 LEU4=4630

%term LTF4=4641
%term LTI2=2597 LTI4=4645
%term LTU2=2598 LTU4=4646

%term NEF4=4657
%term NEI2=2613 NEI4=4661
%term NEU2=2614 NEU4=4662

%term JUMPV=584

%term LABELV=600

%term LOADB=233
%term LOADF4=4321
%term LOADI1=1253 LOADI2=2277 LOADI4=4325
%term LOADP2=2279
%term LOADU1=1254 LOADU2=2278 LOADU4=4326

%term VREGP=711
%%
reg:  INDIRI1(VREGP)     "# read register\n"
reg:  INDIRU1(VREGP)     "# read register\n"

reg:  INDIRI2(VREGP)     "# read register\n"
reg:  INDIRU2(VREGP)     "# read register\n"

reg:  INDIRF4(VREGP)     "# read register\n" fp()
reg:  INDIRI4(VREGP)     "# read register\n"
reg:  INDIRP2(VREGP)     "# read register\n"
reg:  INDIRU4(VREGP)     "# read register\n"

stmt: ASGNI1(VREGP,reg)  "# write register\n"
stmt: ASGNU1(VREGP,reg)  "# write register\n"

stmt: ASGNI2(VREGP,reg)  "# write register\n"
stmt: ASGNU2(VREGP,reg)  "# write register\n"
stmt: ASGNP2(VREGP,reg)  "# write register\n"

stmt: ASGNF4(VREGP,reg)  "# write register\n" fp()
stmt: ASGNI4(VREGP,reg)  "# write register\n"
stmt: ASGNU4(VREGP,reg)  "# write register\n"

con: CNSTI1  "%a"
con: CNSTU1  "%a"
con: CNSTI2  "%a"
con: CNSTU2  "%a"
con: CNSTP2  "%a"
con: CNSTI4  "%a"
con: CNSTU4  "%a"

stmt: reg  ""
acon: con     "%0"
acon: ADDRGP2 "%a"
addr: acon  "%0"
addr: reg   "r%0"
reg: addr  "\tmov r%c,r0\n\tadd r%c, %0\n"  1
reg: ADDRFP2 "\tmov r%c, r0\n\tadd r%c, %F\n\tadd r%c, r13\n\tadd r%c, %a\n" 1
reg: ADDRLP2 "\tmov r%c, r0\n\tadd r%c, %F\n\tadd r%c, r13\n\tadd r%c, %a\n" 1
reg: CNSTI1  "# reg\n"  range(a, 0, 0)
reg: CNSTI2  "# reg\n"  range(a, 0, 0)
reg: CNSTI4  "# reg\n"  range(a, 0, 0)
reg: CNSTU1  "# reg\n"  range(a, 0, 0)
reg: CNSTU2  "# reg\n"  range(a, 0, 0)
reg: CNSTU4  "# reg\n"  range(a, 0, 0)
reg: CNSTP2  "# reg\n"  range(a, 0, 0)
stmt: ASGNI1(addr,reg)  "\tstb [%0], r%1\n"  1
stmt: ASGNU1(addr,reg)  "\tstb [%0], r%1\n"  1
stmt: ASGNI2(addr,reg)  "\tst [%0], r%1\n"  1
stmt: ASGNU2(addr,reg)  "\tst [%0], r%1\n"  1
stmt: ASGNI4(addr,reg)  "\tst [%0], r%1\n"  1
stmt: ASGNU4(addr,reg)  "\tst [%0], r%1\n"  1
stmt: ASGNP2(addr,reg)  "\tst [%0], r%1\n"  1
reg:  INDIRI1(addr)     "\tldb r%c,[%0]\n"  1
reg:  INDIRU1(addr)     "\tldb r%c,[%0]\n"  1
reg:  INDIRI2(addr)     "\tld r%c,[%0]\n"  1
reg:  INDIRU2(addr)     "\tld r%c,[%0]\n"  1
reg:  INDIRI4(addr)     "\tld r%c,[%0]\n"  1
reg:  INDIRU4(addr)     "\tld r%c,[%0]\n"  1
reg:  INDIRP2(addr)     "\tld r%c,[%0]\n"  1

reg:  CVII2(INDIRI1(addr))     "\tldb r%c,[%0]\n"  1
reg:  CVUU2(INDIRU1(addr))     "\tldb r%c,[%0]\n"  1
reg:  CVUI2(INDIRU1(addr))     "\tld r%c,[%0]\n"  1
reg:  CVII4(INDIRI1(addr))     "\tld r%c,[%0]\n"  1
reg:  CVII4(INDIRI2(addr))     "\tld r%c,[%0]\n"  1
reg:  CVUU4(INDIRU1(addr))     "\tld r%c,[%0]\n"  1
reg:  CVUU4(INDIRU2(addr))     "\tld r%c,[%0]\n"  1
reg:  CVUI4(INDIRU1(addr))     "\tld r%c,[%0]\n"  1
reg:  CVUI4(INDIRU2(addr))     "\tld r%c,[%0]\n"  1
reg:  INDIRF4(addr)     "# fp\n"  fp()
stmt: ASGNF4(addr,reg)  "# fp\n"  fp()
reg: DIVI2(reg,reg)  "\tmov r4, r%0\n\tmov r5, r%1\n\tbl _divi2\n\tmov r%c, r2\n"   1
reg: DIVI4(reg,reg)  "\tmov r4, r%0\n\tmov r5, r%1\n\tbl _divi2\n\tmov r%c, r2\n"    1
reg: DIVU2(reg,reg)  "\tmov r4, r%0\n\tmov r5, r%1\n\tbl _divu2\n\tmov r%c, r2\n"   1
reg: DIVU4(reg,reg)  "\tmov r4, r%0\n\tmov r5, r%1\n\tbl _divu2\n\tmov r%c, r2\n"   1
reg: MODI2(reg,reg)  "\tmov r4, r%0\n\tmov r5, r%1\n\tbl _modi2\n\tmov r%c, r2\n"    1
reg: MODI4(reg,reg)  "\tmov r4, r%0\n\tmov r5, r%1\n\tbl _modi2\n\tmov r%c, r2\n"    1
reg: MODU2(reg,reg)  "\tmov r4, r%0\n\tmov r5, r%1\n\tbl _modu2\n\tmov r%c, r2\n"   1
reg: MODU4(reg,reg)  "\tmov r4, r%0\n\tmov r5, r%1\n\tbl _modu2\n\tmov r%c, r2\n"   1
reg: MULI2(reg,reg)  "?\tmov r%c, r%0\n\tmul r%c,r%1\n"   1
reg: MULI4(reg,reg)  "\tbl _muli4\n"   1
reg: MULU2(reg,reg)  "?\tmov r%c, r%0\n\tmul r%c,r%1\n"   1
reg: MULU4(reg,reg)  "\tbl _mulu4\n"   1

reg: ADDI2(reg,reg)   "?\tmov r%c, r%0\n\tadd r%c,r%1\n"  1
reg: ADDI4(reg,reg)   "?\tmov r%c, r%0\n\tadd r%c,r%1\n"  1
reg: ADDP2(reg,reg)   "?\tmov r%c, r%0\n\tadd r%c,r%1\n"  1
reg: ADDU2(reg,reg)   "?\tmov r%c, r%0\n\tadd r%c,r%1\n"  1
reg: ADDU4(reg,reg)   "?\tmov r%c, r%0\n\tadd r%c,r%1\n"  1
reg: BANDI2(reg,reg)  "?\tmov r%c,r%0\n\tand r%c,r%1\n"   1
reg: BANDI4(reg,reg)  "?\tmov r%c,r%0\n\tand r%c,r%1\n"   1
reg: BORI2(reg,reg)   "?\tmov r%c,r%0\n\tor r%c,r%1\n"    1
reg: BORI4(reg,reg)   "?\tmov r%c,r%0\n\tor r%c,r%1\n"    1
reg: BXORI2(reg,reg)  "?\tmov r%c,r%0\n\txor r%c,r%1\n"   1
reg: BXORI4(reg,reg)  "?\tmov r%c,r%0\n\txor r%c,r%1\n"   1
reg: BANDU2(reg,reg)  "?\tmov r%c,r%0\n\tand r%c,r%1\n"   1
reg: BANDU4(reg,reg)  "?\tmov r%c,r%0\n\tand r%c,r%1\n"   1
reg: BORU2(reg,reg)   "?\tmov r%c,r%0\n\tor r%c,r%1\n"    1
reg: BORU4(reg,reg)   "?\tmov r%c,r%0\n\tor r%c,r%1\n"    1
reg: BXORU2(reg,reg)  "?\tmov r%c,r%0\n\txor r%c,r%1\n"   1
reg: BXORU4(reg,reg)  "?\tmov r%c,r%0\n\txor r%c,r%1\n"   1
reg: SUBI2(reg,reg)   "?\tmov r%c,r%0\n\tsub r%c,r%1\n"  1
reg: SUBI4(reg,reg)   "?\tmov r%c,r%0\n\tsub r%c,r%1\n"  1
reg: SUBP2(reg,reg)   "?\tmov r%c,r%0\n\tsub r%c,r%1\n"  1
reg: SUBU2(reg,reg)   "?\tmov r%c,r%0\n\tsub r%c,r%1\n"  1
reg: SUBU4(reg,reg)   "?\tmov r%c,r%0\n\tsub r%c,r%1\n"  1

reg: ADDI2(reg,con)   "?\tmov r%c, r%0\n\tadd r%c,%1\n"  1
reg: ADDI4(reg,con)   "?\tmov r%c, r%0\n\tadd r%c,%1\n"   1
reg: ADDP2(reg,con)   "?\tmov r%c, r%0\n\tadd r%c,%1\n"   1
reg: ADDU2(reg,con)   "?\tmov r%c, r%0\n\tadd r%c,%1\n"   1
reg: ADDU4(reg,con)   "?\tmov r%c, r%0\n\tadd r%c,%1\n"   1
reg: BANDI2(reg,con)  "?\tmov r%c,r%0\n\tand r%c,%1\n"   1
reg: BANDI4(reg,con)  "?\tmov r%c,r%0\n\tand r%c,%1\n"   1
reg: BORI2(reg,con)   "?\tmov r%c,r%0\n\tor r%c,%1\n"    1
reg: BORI4(reg,con)   "?\tmov r%c,r%0\n\tor r%c,%1\n"    1
reg: BXORI2(reg,con)  "?\tmov r%c,r%0\n\txor r%c,%1\n"   1
reg: BXORI4(reg,con)  "?\tmov r%c,r%0\n\txor r%c,%1\n"   1
reg: BANDU2(reg,con)  "?\tmov r%c,r%0\n\tand r%c,%1\n"   1
reg: BANDU4(reg,con)  "?\tmov r%c,r%0\n\tand r%c,%1\n"   1
reg: BORU2(reg,con)   "?\tmov r%c,r%0\n\tor r%c,%1\n"    1
reg: BORU4(reg,con)   "?\tmov r%c,r%0\n\tor r%c,%1\n"    1
reg: BXORU2(reg,con)  "?\tmov r%c,r%0\n\txor r%c,%1\n"   1
reg: BXORU4(reg,con)  "?\tmov r%c,r%0\n\txor r%c,%1\n"   1
reg: SUBI2(reg,con)   "?\tmov r%c,r%0\n\tsub r%c,%1\n"  1
reg: SUBI4(reg,con)   "?\tmov r%c,r%0\n\tsub r%c,%1\n"  1
reg: SUBP2(reg,con)   "?\tmov r%c,r%0\n\tsub r%c,%1\n"  1
reg: SUBU2(reg,con)   "?\tmov r%c,r%0\n\tsub r%c,%1\n"  1
reg: SUBU4(reg,con)   "?\tmov r%c,r%0\n\tsub r%c,%1\n"  1

reg: LSHI2(reg,reg)  "?\tmov r%c, r%0\n\t.shiftleft(r%c, r%1) \n"   10
reg: LSHI4(reg,reg)  "?\tmov r%c, r%0\n\t.shiftleft(r%c, r%1) \n"   10
reg: LSHU2(reg,reg)  "?\tmov r%c, r%0\n\t.shiftleft(r%c, r%1) \n"    10
reg: LSHU4(reg,reg)  "?\tmov r%c, r%0\n\t.shiftleft(r%c, r%1) \n"   10
reg: RSHI2(reg,reg)  "?\tmov r%c, r%0\n\t.ashiftright(r%c, r%1) \n"    10
reg: RSHI4(reg,reg)  "?\tmov r%c, r%0\n\t.ashiftright(r%c, r%1) \n"   10
reg: RSHU2(reg,reg)  "?\tmov r%c, r%0\n\t.shiftright(r%c, r%1) \n"    10
reg: RSHU4(reg,reg)  "?\tmov r%c, r%0\n\t.shiftright(r%c, r%1) \n"   10

reg: LSHI2(reg,con)  "?\tmov r%c, r%0\n\t.times %1 lsl r%c \n"   1
reg: LSHI4(reg,con)  "?\tmov r%c, r%0\n\t.times %1 lsl r%c \n"   1
reg: LSHU2(reg,con)  "?\tmov r%c, r%0\n\t.times %1 lsl r%c \n"   1
reg: LSHU4(reg,con)  "?\tmov r%c, r%0\n\t.times %1 lsl r%c \n"   1
reg: RSHI2(reg,con)  "?\tmov r%c, r%0\n\t.times %1 asr r%c \n"   1
reg: RSHI4(reg,con)  "?\tmov r%c, r%0\n\t.times %1 asr r%c \n"   1
reg: RSHU2(reg,con)  "?\tmov r%c, r%0\n\t.times %1 lsr r%c \n"   1
reg: RSHU4(reg,con)  "?\tmov r%c, r%0\n\t.times %1 lsr r%c \n"   1

reg: BCOMI2(reg)  "?\tmov r%c,r%0\n\txor r%c,-1\n"   1
reg: BCOMI4(reg)  "?\tmov r%c,r%0\n\txor r%c,-1\n"   1
reg: BCOMU2(reg)  "?\tmov r%c,r%0\n\txor r%c,-1\n"   1
reg: BCOMU4(reg)  "?\tmov r%c,r%0\n\txor r%c,-1\n"   1
reg: NEGI2(reg)   "\tmov r%c, r0\n\tsub r%c,r%0\n"  1
reg: NEGI4(reg)   "\tmov r%c, r0\n\tsub r%c,r%0\n"  1
reg: LOADI1(reg)  "\tmov r%c,r%0\n"  move(a)
reg: LOADU1(reg)  "\tmov r%c,r%0\n"  move(a)
reg: LOADI2(reg)  "\tmov r%c,r%0\n"  move(a)
reg: LOADU2(reg)  "\tmov r%c,r%0\n"  move(a)
reg: LOADI4(reg)  "\tmov r%c,r%0\n"  move(a)
reg: LOADP2(reg)  "\tmov r%c,r%0\n"  move(a)
reg: LOADU4(reg)  "\tmov r%c,r%0\n"  move(a)
reg: ADDF4(reg,reg)  ""  fp()
reg: DIVF4(reg,reg)  ""  fp()
reg: MULF4(reg,reg)  ""  fp()
reg: SUBF4(reg,reg)  ""  fp()
reg: LOADF4(reg)     ""       move(a)+fp()
reg: NEGF4(reg)      ""  fp()
reg: CVII2(reg)  "\tmov r%c,r%0\n"  1
reg: CVUI2(reg)  "\tmov r%c,r%0\n"   1
reg: CVUU2(reg)  "\tmov r%c,r%0\n"   1
reg: CVII4(reg)  "\tmov r%c,r%0\n"   1
reg: CVIU4(reg)  "\tmov r%c,r%0\n"   1
reg: CVUI4(reg)  "\tmov r%c,r%0\n"   1
reg: CVUU4(reg)  "\tmov r%c,r%0\n"   1
reg: CVFF4(reg)  ""  fp()
reg: CVIF4(reg)  ""  fp()
reg: CVFI2(reg)  ""  fp()
reg: CVFI4(reg)  ""  fp()
stmt: LABELV  "%a:\n"
stmt: JUMPV(acon)  "\tba %0\n"   1
stmt: JUMPV(reg)   "\tba [r%0]\n"  1

stmt: EQI2(reg,reg)  "\tcmp r%0,r%1\n\tbeq %a\n"   2
stmt: EQI4(reg,reg)  "\tcmp r%0,r%1\n\tbeq %a\n"   2
stmt: EQU2(reg,reg)  "\tcmp r%0,r%1\n\tbeq %a\n"   2
stmt: EQU4(reg,reg)  "\tcmp r%0,r%1\n\tbeq %a\n"   2
stmt: GEI2(reg,reg)  "\tcmp r%0,r%1\n\tbge %a\n"   2
stmt: GEI4(reg,reg)  "\tcmp r%0,r%1\n\tbge %a\n"   2
stmt: GEU2(reg,reg)  "\tcmp r%0,r%1\n\tbge %a\n"  2
stmt: GEU4(reg,reg)  "\tcmp r%0,r%1\n\tbge %a\n"  2
stmt: GTI2(reg,reg)  "\tcmp r%0,r%1\n\tbgt %a\n"   2
stmt: GTI4(reg,reg)  "\tcmp r%0,r%1\n\tbgt %a\n"   2
stmt: GTU2(reg,reg)  "\tcmp r%0,r%1\n\tbgt %a\n"  2
stmt: GTU4(reg,reg)  "\tcmp r%0,r%1\n\tbgt %a\n"  2
stmt: LEI2(reg,reg)  "\tcmp r%0,r%1\n\tble %a\n"   2
stmt: LEI4(reg,reg)  "\tcmp r%0,r%1\n\tble %a\n"   2
stmt: LEU2(reg,reg)  "\tcmp r%0,r%1\n\tble %a\n"  2
stmt: LEU4(reg,reg)  "\tcmp r%0,r%1\n\tble %a\n"  2
stmt: LTI2(reg,reg)  "\tcmp r%0,r%1\n\tblt %a\n"   2
stmt: LTI4(reg,reg)  "\tcmp r%0,r%1\n\tblt %a\n"   2
stmt: LTU2(reg,reg)  "\tcmp r%0,r%1\n\tblt %a\n"  2
stmt: LTU4(reg,reg)  "\tcmp r%0,r%1\n\tblt %a\n"  2
stmt: NEI2(reg,reg)  "\tcmp r%0,r%1\n\tbne %a\n"   2
stmt: NEI4(reg,reg)  "\tcmp r%0,r%1\n\tbne %a\n"   2
stmt: NEU2(reg,reg)  "\tcmp r%0,r%1\n\tbne %a\n"   2
stmt: NEU4(reg,reg)  "\tcmp r%0,r%1\n\tbne %a\n"   2

stmt: EQI2(reg,con)  "\tcmp r%0,%1\n\tbeq %a\n"   2
stmt: EQI4(reg,con)  "\tcmp r%0,%1\n\tbeq %a\n"   2
stmt: EQU2(reg,con)  "\tcmp r%0,%1\n\tbeq %a\n"   2
stmt: EQU4(reg,con)  "\tcmp r%0,%1\n\tbeq %a\n"   2
stmt: GEI2(reg,con)  "\tcmp r%0,%1\n\tbge %a\n"   2
stmt: GEI4(reg,con)  "\tcmp r%0,%1\n\tbge %a\n"   2
stmt: GEU2(reg,con)  "\tcmp r%0,%1\n\tbge %a\n"  2
stmt: GEU4(reg,con)  "\tcmp r%0,%1\n\tbge %a\n"  2
stmt: GTI2(reg,con)  "\tcmp r%0,%1\n\tbgt %a\n"   2
stmt: GTI4(reg,con)  "\tcmp r%0,%1\n\tbgt %a\n"   2
stmt: GTU2(reg,con)  "\tcmp r%0,%1\n\tbgt %a\n"  2
stmt: GTU4(reg,con)  "\tcmp r%0,%1\n\tbgt %a\n"  2
stmt: LEI2(reg,con)  "\tcmp r%0,%1\n\tble %a\n"   2
stmt: LEI4(reg,con)  "\tcmp r%0,%1\n\tble %a\n"   2
stmt: LEU2(reg,con)  "\tcmp r%0,%1\n\tble %a\n"  2
stmt: LEU4(reg,con)  "\tcmp r%0,%1\n\tble %a\n"  2
stmt: LTI2(reg,con)  "\tcmp r%0,%1\n\tblt %a\n"   2
stmt: LTI4(reg,con)  "\tcmp r%0,%1\n\tblt %a\n"   2
stmt: LTU2(reg,con)  "\tcmp r%0,%1\n\tblt %a\n"  2
stmt: LTU4(reg,con)  "\tcmp r%0,%1\n\tblt %a\n"  2
stmt: NEI2(reg,con)  "\tcmp r%0,%1\n\tbne %a\n"   2
stmt: NEI4(reg,con)  "\tcmp r%0,%1\n\tbne %a\n"   2
stmt: NEU2(reg,con)  "\tcmp r%0,%1\n\tbne %a\n"   2
stmt: NEU4(reg,con)  "\tcmp r%0,%1\n\tbne %a\n"   2

stmt: EQF4(reg,reg)  ""  fp()
stmt: LEF4(reg,reg)  ""  fp()
stmt: LTF4(reg,reg)  ""  fp()
stmt: GEF4(reg,reg)  ""  fp()
stmt: GTF4(reg,reg)  ""  fp()
stmt: NEF4(reg,reg)  ""  fp()
ar:   ADDRGP2     "%a"

reg:  CALLF4(ar)  "\tbl %0\n"  fp()
reg:  CALLI2(ar)  "\tbl %0\n"  1
reg:  CALLI4(ar)  "\tbl %0\n"  1
reg:  CALLP2(ar)  "\tbl %0\n"  1
reg:  CALLU2(ar)  "\tbl %0\n"  1
reg:  CALLU4(ar)  "\tbl %0\n"  1
stmt: CALLV(ar)  "\tbl %0\n"  1
ar: reg    "r%0"
ar: CNSTP2  "%a"   range(a, 0, 0x0ffff)
stmt: RETF4(reg)  "# ret\n"  fp()
stmt: RETI2(reg)  "# ret\n"  1
stmt: RETI4(reg)  "# ret\n"  1
stmt: RETU2(reg)  "# ret\n"  1
stmt: RETU4(reg)  "# ret\n"  1
stmt: RETP2(reg)  "# ret\n"  1
stmt: RETV(reg)   "# ret\n"  1
stmt: ARGF4(reg)  "# arg\n"  fp()
stmt: ARGI2(reg)  "# arg\n"  1
stmt: ARGI4(reg)  "# arg\n"  1
stmt: ARGP2(reg)  "# arg\n"  1
stmt: ARGU2(reg)  "# arg\n"  1
stmt: ARGU4(reg)  "# arg\n"  1

stmt: ARGB(INDIRB(reg))       "# argb %0\n"      1
stmt: ASGNB(reg,INDIRB(reg))  "# asgnb %0 %1\n"  1



%%
static void progend(void){ print(".end\n");}
static void progbeg(int argc, char *argv[]) {
        int i;

        {
                union {
                        char c;
                        int i;
                } u;
                u.i = 0;
                u.c = 1;
                swap = ((int)(u.i == 1)) != IR->little_endian;
        }
        //print(".set reorder\n");
        pic = !IR->little_endian;
        parseflags(argc, argv);
        for (i = 0; i < argc; i++)
                if (strncmp(argv[i], "-G", 2) == 0)
                        gnum = atoi(argv[i] + 2);
                else if (strcmp(argv[i], "-pic=1") == 0
                ||       strcmp(argv[i], "-pic=0") == 0)
                        pic = argv[i][5]-'0';
        for (i = 0; i < 31; i += 2)
                freg2[i] = mkreg("%d", i, 3, FREG);
        for (i = 0; i < 32; i++)
                ireg[i]  = mkreg("%d", i, 1, IREG);
        ireg[29]->x.name = "sp";
        d6 = mkreg("6", 6, 3, IREG);
        freg2w = mkwildcard(freg2);
        iregw = mkwildcard(ireg);
        tmask[IREG] = INTTMP; tmask[FREG] = FLTTMP;
        vmask[IREG] = INTVAR; vmask[FREG] = FLTVAR;
        blkreg = mkreg("8", 8, 7, IREG);
}
static Symbol rmap(int opk) {
        switch (optype(opk)) {
        case I: case U: case P: case B:
                return iregw;
        case F:
                return freg2w;
        default:
                return 0;
        }
}
static void target(Node p) {
        assert(p);
        switch (specific(p->op)) {
        case CNST+I: case CNST+U: case CNST+P:
                if (range(p, 0, 0) == 0) {
                        setreg(p, ireg[0]);
                        p->x.registered = 1;
                }
                break;
        case CALL+V:
                rtarget(p, 0, ireg[25]);
                break;
        case CALL+F:
                rtarget(p, 0, ireg[25]);
                setreg(p, freg2[0]);
                break;
        case CALL+I: case CALL+P: case CALL+U:
                rtarget(p, 0, ireg[25]);
                setreg(p, ireg[2]);
                break;
        case RET+F:
                rtarget(p, 0, freg2[0]);
                break;
        case RET+I: case RET+U: case RET+P:
                rtarget(p, 0, ireg[2]);
                break;
        case ARG+F: case ARG+I: case ARG+P: case ARG+U: {
                static int ty0;
                int ty = optype(p->op);
                Symbol q;

                q = argreg(p->x.argno, p->syms[2]->u.c.v.i, ty, opsize(p->op), ty0);
                if (p->x.argno == 0)
                        ty0 = ty;
                if (q &&
                !(ty == F && q->x.regnode->set == IREG))
                        rtarget(p, 0, q);
                break;
                }
        case ASGN+B: rtarget(p->kids[1], 0, blkreg); break;
        case ARG+B:  rtarget(p->kids[0], 0, blkreg); break;
        }
}
static void clobber(Node p) {
        assert(p);
        switch (specific(p->op)) {
        case CALL+F:
                spill(INTTMP | INTRET, IREG, p);
                spill(FLTTMP,          FREG, p);
                break;
        case CALL+I: case CALL+P: case CALL+U:
                spill(INTTMP,          IREG, p);
                spill(FLTTMP | FLTRET, FREG, p);
                break;
        case CALL+V:
                spill(INTTMP | INTRET, IREG, p);
                spill(FLTTMP | FLTRET, FREG, p);
                break;
        }
}
static void emit2(Node p) {
        int dst, n, src, sz, ty;
        static int ty0;
        Symbol q;

        switch (specific(p->op)) {
        case ARG+F: case ARG+I: case ARG+P: case ARG+U:
                ty = optype(p->op);
                sz = opsize(p->op);
                if (p->x.argno == 0)
                        ty0 = ty;
                q = argreg(p->x.argno, p->syms[2]->u.c.v.i, ty, sz, ty0);
                src = getregnum(p->x.kids[0]);
                if (q == NULL && ty == F && sz == 4)
                        print("s.s $f%d,%d($sp)\n", src, p->syms[2]->u.c.v.i);
                else if (q == NULL && ty == F)
                        print("s.d $f%d,%d($sp)\n", src, p->syms[2]->u.c.v.i);
                else if (q == NULL)
                        print("\tst r%d,[r13, %d]\n", src, p->syms[2]->u.c.v.i);
                else if (ty == F && sz == 4 && q->x.regnode->set == IREG)
                        print("mfc1 $%d,$f%d\n", q->x.regnode->number, src);
                else if (ty == F && q->x.regnode->set == IREG)
                        print("mfc1.d $%d,$f%d\n", q->x.regnode->number, src);
                break;
        case ASGN+B:
                dalign = salign = p->syms[1]->u.c.v.i;
                blkcopy(getregnum(p->x.kids[0]), 0,
                        getregnum(p->x.kids[1]), 0,
                        p->syms[0]->u.c.v.i, tmpregs);
                break;
        case ARG+B:
                dalign = 4;
                salign = p->syms[1]->u.c.v.i;
                blkcopy(29, p->syms[2]->u.c.v.i,
                        getregnum(p->x.kids[0]), 0,
                        p->syms[0]->u.c.v.i, tmpregs);
                n   = p->syms[2]->u.c.v.i + p->syms[0]->u.c.v.i;
                dst = p->syms[2]->u.c.v.i;
                for ( ; dst <= 12 && dst < n; dst += 4)
                        print("lw $%d,%d($sp)\n", (dst/4)+4, dst);
                break;
        }
}
static Symbol argreg(int argno, int offset, int ty, int sz, int ty0) {
        assert((offset&3) == 0);
        if (offset > 12)
                return NULL;
        else if (argno == 0 && ty == F)
                return freg2[12];
        else if (argno == 1 && ty == F && ty0 == F)
                return freg2[14];
        else if (argno == 1 && ty == F && sz == 8)
                return d6;  /* Pair! */
        else
                return ireg[(offset/4) + 4];
}
static void doarg(Node p) {
        static int argno;
        int align;

        if (argoffset == 0)
                argno = 0;
        p->x.argno = argno++;
        align = p->syms[1]->u.c.v.i < 4 ? 4 : p->syms[1]->u.c.v.i;
        p->syms[2] = intconst(mkactual(align,
                p->syms[0]->u.c.v.i));
}
static void local(Symbol p) {
        if (askregvar(p, rmap(ttob(p->type))) == 0)
                mkauto(p);
}
static void function(Symbol f, Symbol caller[], Symbol callee[], int ncalls) {
        int i, saved, sizefsave, sizeisave, varargs;
        Symbol r, argregs[4];

        usedmask[0] = usedmask[1] = 0;
        freemask[0] = freemask[1] = ~(unsigned)0;
        offset = maxoffset = maxargoffset = 0;
        for (i = 0; callee[i]; i++)
                ;
        varargs = variadic(f->type)
                || i > 0 && strcmp(callee[i-1]->name, "va_alist") == 0;
        for (i = 0; callee[i]; i++) {
                Symbol p = callee[i];
                Symbol q = caller[i];
                assert(q);
                offset = roundup(offset, q->type->align);
                p->x.offset = q->x.offset = offset;
                p->x.name = q->x.name = stringd(offset);
                r = argreg(i, offset, optype(ttob(q->type)), q->type->size, optype(ttob(caller[0]->type)));
                if (i < 4)
                        argregs[i] = r;
                offset = roundup(offset + q->type->size, 4);
                if (varargs)
                        p->sclass = AUTO;
                else if (r && ncalls == 0 &&
                         !isstruct(q->type) && !p->addressed &&
                         !(isfloat(q->type) && r->x.regnode->set == IREG)
) {
                        p->sclass = q->sclass = REGISTER;
                        askregvar(p, r);
                        assert(p->x.regnode && p->x.regnode->vbl == p);
                        q->x = p->x;
                        q->type = p->type;
                }
                else if (askregvar(p, rmap(ttob(p->type)))
                         && r != NULL
                         && (isint(p->type) || p->type == q->type)) {
                        assert(q->sclass != REGISTER);
                        p->sclass = q->sclass = REGISTER;
                        q->type = p->type;
                }
        }
        assert(!caller[i]);
        offset = 0;
        gencode(caller, callee);
        if (ncalls)
                usedmask[IREG] |= ((unsigned)1)<<31;
        usedmask[IREG] &= 0x1fff;
        usedmask[FREG] &= 0xfff00000;
        if (pic && ncalls)
                usedmask[IREG] |= 1<<25;
        maxargoffset = roundup(maxargoffset, usedmask[FREG] ? 8 : 4);
        if (ncalls && maxargoffset < 16)
                maxargoffset = 16;
        sizefsave = 0; //bitcount(usedmask[FREG]);
        sizeisave = 2*bitcount(usedmask[IREG]);
        framesize = roundup(maxargoffset + sizefsave
                + sizeisave + maxoffset, 16);
        segment(CODE);
        //print(".align 2\n");
        //print(".ent %s\n", f->x.name);
        print("%s:\n", f->x.name);
        i = maxargoffset + sizefsave - framesize;
        //print(".frame $sp,%d,$31\n", framesize);
        //if (pic)
        //        print(".set noreorder\n.cpload $25\n.set reorder\n");
        if (framesize > 0)
                print("\tsub r13,%d\n", framesize);
        //if (usedmask[FREG])
        //        print(".fmask 0x%x,%d\n", usedmask[FREG], i - 8);
        //if (usedmask[IREG])
        //        print(".mask 0x%x,%d\n",  usedmask[IREG],
        //                i + sizeisave - 4);
        saved = maxargoffset;
        /*  No floating point regs
 			for (i = 20; i <= 30; i += 2)
                if (usedmask[FREG]&(3<<i)) {
                        print("s.d $f%d,%d($sp)\n", i, saved);
                        saved += 8;
                }
		*/

		// Save LR
		print("\tst [r13, %d], r15\n", saved);
		saved += 2;

        for (i = 4; i <= 12; i++)
                if (usedmask[IREG]&(1<<i)) {
                        print("\tst [r13, %d], r%d\n", saved, i);
                        saved += 2;
                }
        for (i = 0; i < 4 && callee[i]; i++) {
                r = argregs[i];
                if (r && r->x.regnode != callee[i]->x.regnode) {
                        Symbol out = callee[i];
                        Symbol in  = caller[i];
                        int rn = r->x.regnode->number;
                        int rs = r->x.regnode->set;
                        int tyin = ttob(in->type);

                        assert(out && in && r && r->x.regnode);
                        assert(out->sclass != REGISTER || out->x.regnode);
                        if (out->sclass == REGISTER
                        && (isint(out->type) || out->type == in->type)) {
                                int outn = out->x.regnode->number;
                                /*if (rs == FREG && tyin == F+sizeop(8))
                                        print("mov.d $f%d,$f%d\n", outn, rn);
                                else if (rs == FREG && tyin == F+sizeop(4))
                                        print("mov.s $f%d,$f%d\n", outn, rn);
                                else if (rs == IREG && tyin == F+sizeop(8))
                                        print("mtc1.d $%d,$f%d\n", rn,   outn);
                                else if (rs == IREG && tyin == F+sizeop(4))
                                        print("mtc1 $%d,$f%d\n",   rn,   outn);
                                else*/
                                        print("\tmov r%d,r%d\n",    outn, rn);
                        } else {
                                int off = in->x.offset + framesize;
                               /* if (rs == FREG && tyin == F+sizeop(8))
                                        print("s.d $f%d,%d($sp)\n", rn, off);
                                else if (rs == FREG && tyin == F+sizeop(4))
                                        print("s.s $f%d,%d($sp)\n", rn, off);
                                else*/ {
                                        int i, n = (in->type->size + 1)/2;
                                        for (i = rn; i < rn+n && i <= 7; i++)
                                                print("\tst [r13, %d], r%d\n", off + (i-rn)*2, i);
                                }
                        }
                }
        }
        if (varargs && callee[i-1]) {
                i = callee[i-1]->x.offset + callee[i-1]->type->size;
                for (i = roundup(i, 2)/2; i <= 3; i++)
                        print("\tst [r13, %d], r%d\n", framesize + 2*i, i+4);
                }
        emitcode();
        saved = maxargoffset;
     	/*   for (i = 20; i <= 30; i += 2)
                if (usedmask[FREG]&(3<<i)) {
                        print("l.d $f%d,%d($sp)\n", i, saved);
                        saved += 8;
                }
		*/
       	// restore LR
		print("\tld r15, [r13, %d]\n", saved);
		saved += 2;		

		for (i = 4; i <= 12; i++)
                if (usedmask[IREG]&(1<<i)) {
                        print("\tld r%d, [r13, %d]\n", i, saved);
                        saved += 2;
                }
        if (framesize > 0)
                print("\tadd r13,%d\n", framesize);
        print("\tret\n");
       // print(".end %s\n", f->x.name);
}
static void defconst(int suffix, int size, Value v) {
        if (suffix == F && size == 4) {
                float f = v.d;
                print("dw 0x%x\n", *(unsigned *)&f);
        }
        else if (suffix == F && size == 8) {
                double d = v.d;
                unsigned *p = (unsigned *)&d;
                print("dw 0x%x\ndw 0x%x\n", p[swap], p[!swap]);
        }
        else if (suffix == P)
                print("dw 0x%x\n", (unsigned)v.p);
        else if (size == 1)
                print("db 0x%x\n", (unsigned)((unsigned char)(suffix == I ? v.i : v.u)));
        else if (size == 2)
                print("dw 0x%x\n", (unsigned)((unsigned short)(suffix == I ? v.i : v.u)));
        else if (size == 4)
                print("dw 0x%x\n", (unsigned)(suffix == I ? v.i : v.u));
}
static void defaddress(Symbol p) {
        //if (pic && p->scope == LABELS)
        //        print(".gpword %s\n", p->x.name);
        //else
                print("\tdw %s\n", p->x.name);
}
static void defstring(int n, char *str) {
        char *s;

        for (s = str; s < str + n; s++)
                print("\tdb 0x%x\n", (*s)&0377);
		print(".align 2\n");
}
static void export(Symbol p) {
        print(".global %s\n", p->x.name);
}
static void import(Symbol p) {
        if (!isfunc(p->type))
                print(".extern %s %d\n", p->name, p->type->size);
}
static void defsymbol(Symbol p) {
        if (p->scope >= LOCAL && p->sclass == STATIC)
                p->x.name = stringf("L.%d", genlabel(1));
        else if (p->generated)
                p->x.name = stringf("L.%s", p->name);
        else
                assert(p->scope != CONSTANTS || isint(p->type) || isptr(p->type)),
                p->x.name = p->name;
}
static void address(Symbol q, Symbol p, long n) {
        if (p->scope == GLOBAL
        || p->sclass == STATIC || p->sclass == EXTERN)
                q->x.name = stringf("%s%s%D", p->x.name,
                        n >= 0 ? "+" : "", n);
        else {
                assert(n <= INT_MAX && n >= INT_MIN);
                q->x.offset = p->x.offset + n;
                q->x.name = stringd(q->x.offset);
        }
}
static void global(Symbol p) {
        if (p->u.seg == BSS) {
				print("%s:\n", p->x.name);
				for (int i = 0; i < p->type->size; i+= 2)
					print("\tdw 0\n");
					
                //if (p->sclass == STATIC || Aflag >= 2)
                //        print(".lcomm %s,%d\n", p->x.name, p->type->size);
                //else
                //        print( ".comm %s,%d\n", p->x.name, p->type->size);
        } else {
                if (p->u.seg == DATA
                && (p->type->size == 0 || p->type->size > gnum))
                        print(".data\n");
                else if (p->u.seg == DATA)
                        print(".data\n");
                //print(".align %c\n", ".01.2...3"[p->type->align]);
                print("%s:\n", p->x.name);
        }
}
static void segment(int n) {
        cseg = n;
        switch (n) {
        case CODE: print(".text\n");  break;
        case LIT:  print(".data\n"); break;
        }
}
static void space(int n) {
        if (cseg != BSS)
                print(".space %d\n", n);
}
static void blkloop(int dreg, int doff, int sreg, int soff, int size, int tmps[]) {
        int lab = genlabel(1);

        print("addu $%d,$%d,%d\n", sreg, sreg, size&~7);
        print("addu $%d,$%d,%d\n", tmps[2], dreg, size&~7);
        blkcopy(tmps[2], doff, sreg, soff, size&7, tmps);
        print("L.%d:\n", lab);
        print("addu $%d,$%d,%d\n", sreg, sreg, -8);
        print("addu $%d,$%d,%d\n", tmps[2], tmps[2], -8);
        blkcopy(tmps[2], doff, sreg, soff, 8, tmps);
        print("bltu $%d,$%d,L.%d\n", dreg, tmps[2], lab);
}
static void blkfetch(int size, int off, int reg, int tmp) {
        assert(size == 1 || size == 2 || size == 4);
        if (size == 1)
                print("lbu $%d,%d($%d)\n",  tmp, off, reg);
        else if (salign >= size && size == 2)
                print("lhu $%d,%d($%d)\n",  tmp, off, reg);
        else if (salign >= size)
                print("lw $%d,%d($%d)\n",   tmp, off, reg);
        else if (size == 2)
                print("ulhu $%d,%d($%d)\n", tmp, off, reg);
        else
                print("ulw $%d,%d($%d)\n",  tmp, off, reg);
}
static void blkstore(int size, int off, int reg, int tmp) {
        if (size == 1)
                print("sb $%d,%d($%d)\n",  tmp, off, reg);
        else if (dalign >= size && size == 2)
                print("sh $%d,%d($%d)\n",  tmp, off, reg);
        else if (dalign >= size)
                print("sw $%d,%d($%d)\n",  tmp, off, reg);
        else if (size == 2)
                print("ush $%d,%d($%d)\n", tmp, off, reg);
        else
                print("usw $%d,%d($%d)\n", tmp, off, reg);
}
static void stabinit(char *, int, char *[]);
static void stabline(Coordinate *);
static void stabsym(Symbol);

static char *currentfile;

static int bitcount(unsigned mask) {
        unsigned i, n = 0;

        for (i = 1; i; i <<= 1)
                if (mask&i)
                        n++;
        return n;
}

/* stabinit - initialize stab output */
static void stabinit(char *file, int argc, char *argv[]) {
        if (file) {
                print(".file 2,\"%s\"\n", file);
                currentfile = file;
        }
}

/* stabline - emit stab entry for source coordinate *cp */
static void stabline(Coordinate *cp) {
        if (cp->file && cp->file != currentfile) {
                print(".file 2,\"%s\"\n", cp->file);
                currentfile = cp->file;
        }
        print(".loc 2,%d\n", cp->y);
}

/* stabsym - output a stab entry for symbol p */
static void stabsym(Symbol p) {
        if (p == cfunc && IR->stabline)
                (*IR->stabline)(&p->src);
}
Interface slurm16IR = {
        1, 1, 0,  /* char */
        2, 2, 0,  /* short */
        2, 2, 0,  /* int */
        4, 4, 0,  /* long */
        4, 4, 0,  /* long long */
        4, 4, 1,  /* float */
        8, 8, 1,  /* double */
        8, 8, 1,  /* long double */
        2, 2, 0,  /* T * */
        0, 1, 0,  /* struct */
        1,      /* little_endian */
        1,  /* mulops_calls */
        0,  /* wants_callb */
        1,  /* wants_argb */
        1,  /* left_to_right */
        0,  /* wants_dag */
        0,  /* unsigned_char */
        address,
        blockbeg,
        blockend,
        defaddress,
        defconst,
        defstring,
        defsymbol,
        emit,
        export,
        function,
        gen,
        global,
        import,
        local,
        progbeg,
        progend,
        segment,
        space,
        0, 0, 0, stabinit, stabline, stabsym, 0,
        {
                4,      /* max_unaligned_load */
                rmap,
                blkfetch, blkstore, blkloop,
                _label,
                _rule,
                _nts,
                _kids,
                _string,
                _templates,
                _isinstruction,
                _ntname,
                emit2,
                doarg,
                target,
                clobber,

        }
};
static char rcsid[] = "$Id$";
