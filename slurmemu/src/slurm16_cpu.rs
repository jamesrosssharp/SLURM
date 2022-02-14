use bitmatch::bitmatch;

pub struct Slurm16CPU {
    pub z: bool,
    pub c: bool,
    pub s: bool,

    pub imm_hi: u16,

    pub pc: u16,
    pub registers: Vec<u16>,

    pub int_flag : bool,

    pub halt : bool,
}

impl Slurm16CPU {
    pub fn new() -> Self 
    {
        Slurm16CPU {
            z: false,
            c: false, 
            s: false,
            imm_hi: 0,
            pc: 0,
            registers: vec![0; 16],
            int_flag: false,
            halt : false
        }
    }

    pub fn nop(& self) {
        // Do nothing
    }

    pub fn imm(&mut self, instruction : u16) {
        self.imm_hi = (instruction & 0xfff) << 4;
    }

    pub fn alu_mov(&mut self, instruction : u16, src: u16) {
        let reg_dest    = ((instruction & 0xf0) >> 4) as usize;
        self.registers[reg_dest] = src;
    }

    pub fn alu_add(&mut self, instruction : u16, src : u16) {
        let reg_dest    = ((instruction & 0xf0) >> 4) as usize;
        
        let a = src as u32;
        let b = self.get_register(reg_dest) as u32;

        let sum = a + b;

        self.registers[reg_dest] = sum as u16;
        self.z = sum & 65535 == 0;
        match sum & 0x8000 {
            0x8000 => self.s = true,
            _ => self.s = false
        }
        self.c = sum > 65535;

    }

    pub fn alu_sub(&mut self, instruction : u16, src : u16) {
        let reg_dest    = ((instruction & 0xf0) >> 4) as usize;
        
        let a = src as u32;
        let b = self.get_register(reg_dest) as u32;
        let sum = b - a;

        self.registers[reg_dest] = sum as u16;
        self.z = sum & 65535 == 0;
        match sum & 0x8000 {
            0x8000 => self.s = true,
            _ => self.s = false
        }
        self.c = sum > 65535;
    }

    pub fn alu_cmp(&mut self, instruction : u16, src : u16) {
        let reg_dest    = ((instruction & 0xf0) >> 4) as usize;
        
        let a = src as u32;
        let b = self.get_register(reg_dest) as u32;
        let sum = b - a;

        self.z = sum & 65535 == 0;
        match sum & 0x8000 {
            0x8000 => self.s = true,
            _ => self.s = false
        }
        self.c = sum > 65535;
    }

    pub fn alu_and(&mut self, instruction : u16, src : u16) {
        let reg_dest    = ((instruction & 0xf0) >> 4) as usize;
        
        let a = src;
        let b = self.get_register(reg_dest);
        let andop = b & a;

        self.registers[reg_dest] = andop;
        self.z = andop == 0;
        match andop & 0x8000 {
            0x8000 => self.s = true,
            _ => self.s = false
        }
        self.c = false;

    }

    pub fn alu_test(&mut self, instruction : u16, src : u16) {
        let reg_dest    = ((instruction & 0xf0) >> 4) as usize;
        
        let a = src;
        let b = self.get_register(reg_dest);
        let andop = b & a;

        self.z = andop == 0;
        match andop & 0x8000 {
            0x8000 => self.s = true,
            _ => self.s = false
        }
        self.c = false;

    }



   pub fn alu_or(&mut self, instruction : u16, src : u16) {
        let reg_dest    = ((instruction & 0xf0) >> 4) as usize;
        
        let a = src;
        let b = self.get_register(reg_dest);
        let orop = b | a;

        self.registers[reg_dest] = orop;
        self.z = orop == 0;
        match orop & 0x8000 {
            0x8000 => self.s = true,
            _ => self.s = false
        }
        self.c = false;

    }

    pub fn alu_xor(&mut self, instruction : u16, src : u16) {
        let reg_dest    = ((instruction & 0xf0) >> 4) as usize;
        
        let a = src;
        let b = self.get_register(reg_dest);
        let xorop = b ^ a;

        self.registers[reg_dest] = xorop;
        self.z = xorop == 0;
        match xorop & 0x8000 {
            0x8000 => self.s = true,
            _ => self.s = false
        }
        self.c = false;

    }

     pub fn alu_mul(&mut self, instruction : u16, src : u16) {
        let reg_dest    = ((instruction & 0xf0) >> 4) as usize;
        
        let a = src as i32;
        let b = self.get_register(reg_dest) as i32;
        let mul = b * a;

        self.registers[reg_dest] = mul as u16;
        self.z = mul & 65535 == 0;
        match mul & 0x8000 {
            0x8000 => self.s = true,
            _ => self.s = false
        }
        self.c = false;
    }

    pub fn alu_mulu(&mut self, instruction : u16, src : u16) {
        let reg_dest    = ((instruction & 0xf0) >> 4) as usize;
        
        let a = src as i32;
        let b = self.get_register(reg_dest) as i32;
        let mul = ((b * a) >> 16) & 0xffff;

        self.registers[reg_dest] = mul as u16;
        self.z = mul & 65535 == 0;
        match mul & 0x8000 {
            0x8000 => self.s = true,
            _ => self.s = false
        }
        self.c = false;
    }
 
    pub fn alu_asr(&mut self, instruction : u16, src : u16) {
        let reg_dest    = (instruction & 0xf) as usize;
        
        let a = src as i16;
        let shift = a >> 1;

        self.registers[reg_dest] = shift as u16;
        self.z = shift == 0;
        self.s = shift > 0;
        self.c = false;
    }

    pub fn alu_lsr(&mut self, instruction : u16, src : u16) {
        let reg_dest    = (instruction & 0xf) as usize;
        
        let a = src as u16;
        let shift = a >> 1;

        self.registers[reg_dest] = shift as u16;
        self.z = shift == 0;
        match shift & 0x8000 {
            0x8000 => self.s = true,
            _ => self.s = false
        }
        self.c = false;
    }

    pub fn alu_lsl(&mut self, instruction : u16, src : u16) {
        let reg_dest    = (instruction & 0xf) as usize;
        
        let a = src as u16;
        let shift = a << 1;

        self.registers[reg_dest] = shift as u16;
        self.z = shift == 0;
        match shift & 0x8000 {
            0x8000 => self.s = true,
            _ => self.s = false
        }
        self.c = false;
    }

    pub fn alu_rolc(&mut self, instruction : u16, src : u16) {
        let reg_dest    = (instruction & 0xf) as usize;
        
        let a = src as u16;
        let carry = if self.c { 1 } else { 0 } as u16;
        let rolc = a << 1 | carry;

        self.registers[reg_dest] = rolc as u16;
        self.z = rolc == 0;
        match rolc & 0x8000 {
            0x8000 => self.s = true,
            _ => self.s = false
        }
        self.c = if src & 0x8000 == 0x8000 { true } else { false };
    }

   pub fn alu_rorc(&mut self, instruction : u16, src : u16) {
        let reg_dest    = (instruction & 0xf) as usize;
        
        let a = src as u16;
        let carry = if self.c { 0x8000 } else { 0 } as u16;
        let rorc = a >> 1 | carry;

        self.registers[reg_dest] = rorc as u16;
        self.z = rorc == 0;
        match rorc & 0x8000 {
            0x8000  => self.s = true,
            _       => self.s = false
        }
        self.c = if src & 0x0001 == 0x0001 { true } else { false };
    }

    pub fn alu_rol(&mut self, instruction : u16, src : u16) {
        let reg_dest    = (instruction & 0xf) as usize;
        
        let a = src as u16;
        let carry = if src & 0x8000 == 0x8000 { 1 } else { 0 } as u16;
        let rol = a << 1 | carry;

        self.registers[reg_dest] = rol as u16;
        self.z = rol == 0;
        match rol & 0x8000 {
            0x8000 => self.s = true,
            _ => self.s = false
        }
        self.c = false;
    }

   pub fn alu_ror(&mut self, instruction : u16, src : u16) {
        let reg_dest    = (instruction & 0xf) as usize;
        
        let a = src as u16;
        let carry = if src & 1 == 1 { 0x8000 } else { 0 } as u16;
        let ror = a >> 1 | carry;

        self.registers[reg_dest] = ror as u16;
        self.z = ror == 0;
        match ror & 0x8000 {
            0x8000  => self.s = true,
            _       => self.s = false
        }
        self.c = false;
    }

    pub fn alu_cc(&mut self) {
        self.c = false;
    }
    
    pub fn alu_sc(&mut self) {
        self.c = true;
    }

    pub fn alu_cz(&mut self) {
        self.z = false;
    }

    pub fn alu_sz(&mut self) {
        self.z = true;
    }

    pub fn alu_cs(&mut self) {
        self.s = false;
    }

    pub fn alu_ss(&mut self) {
        self.s = true;
    }

    pub fn alu_stf(&mut self, instruction : u16) {
    
        let reg_dest    = (instruction & 0xf) as usize;
        let c_int = if self.c { 2 } else { 0 } as u16;
        let z_int = if self.z { 1 } else { 0 } as u16;
        let s_int = if self.s { 4 } else { 0 } as u16;

        self.registers[reg_dest] = c_int | z_int | s_int;
    }       

    pub fn alu_rsf(&mut self, src_val : u16) {

        self.c = if src_val & 2 == 2 { true } else { false };
        self.z = if src_val & 1 == 1 { true } else { false };
        self.s = if src_val & 4 == 4 { true } else { false };

    }

    pub fn int(&mut self, _instruction : u16 ) {
        // TODO: Interrupt

        self.imm_hi = 0;
    }

    pub fn setif(&mut self, instruction : u16) {
        self.int_flag = instruction & 1 == 1;
        self.imm_hi = 0;
    }

    pub fn sleep(&mut self) {
        self.halt = true;
        self.imm_hi = 0;
    }

    pub fn alu_op_reg_imm(&mut self, instruction : u16) {
        let imm         = self.imm_hi | (instruction & 0xf);
        
        match (instruction & 0x0f00) >> 8 {
        //0 - mov : DEST <- IMM
            0 => self.alu_mov(instruction, imm), 
        //1 - add : DEST <- DEST + IMM
            1 => self.alu_add(instruction, imm),
        //2 - adc : DEST <- DEST + IMM + Carry
            2 => self.alu_add(instruction, imm), // Hardware doesn't implement adc properly yet
        //3 - sub : DEST <- DEST - IMM 
            3 => self.alu_sub(instruction, imm),
        //4 - sbb : DEST <- DEST - IMM - Carry
            4 => self.alu_sub(instruction, imm), // Hardware doesn't properly implement sbb yet
        //5 - and : DEST <- DEST & IMM
            5 => self.alu_and(instruction, imm),
        //6 - or  : DEST <- DEST | IMM
            6 => self.alu_or(instruction, imm), 
        //7 - xor : DEST <- DEST ^ IMM
            7 => self.alu_xor(instruction, imm), 
        //8 - mul : DEST <- DEST * IMM (LO)
            8 => self.alu_mul(instruction, imm), 
        //9 - mulu : DEST <- DEST * IMM (HI)
            9 => self.alu_mulu(instruction, imm),
        // 10 - 11 reserved for barrel shifter 
            12 => self.alu_cmp(instruction, imm),
            13 => self.alu_test(instruction, imm),
        // 14 - 15 - reserved
            _ => self.nop()
        }


        // Clear immediate
        self.imm_hi = 0;
    }

    pub fn alu_op_reg_reg(&mut self, instruction : u16) {
        let reg_src = (instruction & 0xf) as usize;
        let src_val = self.get_register(reg_src);
        
        match (instruction & 0x0f00) >> 8 {
        //0 - mov : DEST <- IMM
            0 => self.alu_mov(instruction, src_val), 
        //1 - add : DEST <- DEST + IMM
            1 => self.alu_add(instruction, src_val),
        //2 - adc : DEST <- DEST + IMM + Carry
            2 => self.alu_add(instruction, src_val), // Hardware doesn't implement adc properly yet
        //3 - sub : DEST <- DEST - IMM 
            3 => self.alu_sub(instruction, src_val),
        //4 - sbb : DEST <- DEST - IMM - Carry
            4 => self.alu_sub(instruction, src_val), // Hardware doesn't properly implement sbb yet
        //5 - and : DEST <- DEST & IMM
            5 => self.alu_and(instruction, src_val),
        //6 - or  : DEST <- DEST | IMM
            6 => self.alu_or(instruction, src_val), 
        //7 - xor : DEST <- DEST ^ IMM
            7 => self.alu_xor(instruction, src_val), 
        //8 - mul : DEST <- DEST * IMM (LO)
            8 => self.alu_mul(instruction, src_val), 
        //9 - mulu : DEST <- DEST * IMM (HI)
            9 => self.alu_mulu(instruction, src_val),
        // 10 - 11 reserved for barrel shifter 
            12 => self.alu_cmp(instruction, src_val),
            13 => self.alu_test(instruction, src_val),
        // 14 - 15 - reserved
            _ => self.nop()
        }

        // Clear immediate
        self.imm_hi = 0;
    }

    pub fn alu_op_single_reg(&mut self, instruction : u16) {
        let reg_src = (instruction & 0xf) as usize;
        let src_val = self.get_register(reg_src);
        
        match ((instruction & 0x00f0) >> 4) | 0x10 {
            //  16 - asr : arithmetic shift right REG
            16 => self.alu_asr(instruction, src_val), 
            //  17 - lsr : logical shift right REG
            17 => self.alu_lsr(instruction, src_val),
            //  18 - lsl : logical shift left REG
            18 => self.alu_lsl(instruction, src_val),
            //  19 - rolc
            19 => self.alu_rolc(instruction, src_val),
            //  20 - rorc
            20 => self.alu_rorc(instruction, src_val),
            //  21 - rol
            21 => self.alu_rol(instruction, src_val),
            //  22 - ror
            22 => self.alu_ror(instruction, src_val),
            //  23 - cc : clear carry
            23 => self.alu_cc(),
            //  24 - sc : set carry
            24 => self.alu_sc(),
            //  25 - cz : clear zero
            25 => self.alu_cz(),
            //  26 - sz : set zero
            26 => self.alu_sz(),
            //  27 - cs : clear sign
            27 => self.alu_cs(),
            //  28 - ss : set sign
            28 => self.alu_ss(),
            //  29 - stf : store flags
            29 => self.alu_stf(instruction),
            //  30 - rsf: restore flags
            30 => self.alu_rsf(src_val),
            // 31 - reserved
            _ => self.nop()
        }

        // Clear immediate
        self.imm_hi = 0;
    }

    pub fn bz_op(&mut self, instruction : u16) {

        let reg_src = ((instruction & 0xf0) >> 8) as usize;
        let reg_addr = self.get_register(reg_src);

        let target : u16 = reg_addr + self.imm_hi + instruction & 0xf - 1; // PC will be incremented after we return 

        if ! self.z
        {
            self.pc = target;
        }
    }

   pub fn bnz_op(&mut self, instruction : u16) {

        let reg_src = ((instruction & 0xf0) >> 8) as usize;
        let reg_addr = self.get_register(reg_src);

        let target : u16 = reg_addr + self.imm_hi + instruction & 0xf - 1; // PC will be incremented after we return 

        if  self.z
        {
            self.pc = target;
        }
    }

    pub fn bs_op(&mut self, instruction : u16) {

        let reg_src = ((instruction & 0xf0) >> 8) as usize;
        let reg_addr = self.get_register(reg_src);

        let target : u16 = reg_addr + self.imm_hi + instruction & 0xf - 1; // PC will be incremented after we return 

        if ! self.s
        {
            self.pc = target;
        }
    }

   pub fn bns_op(&mut self, instruction : u16) {

        let reg_src = ((instruction & 0xf0) >> 8) as usize;
        let reg_addr = self.get_register(reg_src);

        let target : u16 = reg_addr + self.imm_hi + instruction & 0xf - 1; // PC will be incremented after we return 

        if  self.s
        {
            self.pc = target;
        }
    }

    pub fn bc_op(&mut self, instruction : u16) {

        let reg_src = ((instruction & 0xf0) >> 8) as usize;
        let reg_addr = self.get_register(reg_src);

        let target : u16 = reg_addr + self.imm_hi + instruction & 0xf - 1; // PC will be incremented after we return 

        if ! self.c
        {
            self.pc = target;
        }
    }

   pub fn bnc_op(&mut self, instruction : u16) {

        let reg_src = ((instruction & 0xf0) >> 8) as usize;
        let reg_addr = self.get_register(reg_src);

        let target : u16 = reg_addr + self.imm_hi + instruction & 0xf - 1; // PC will be incremented after we return 

        if  self.c
        {
            self.pc = target;
        }
    }

    pub fn ba_op(&mut self, instruction : u16) {

        let reg_src = ((instruction & 0xf0) >> 8) as usize;
        let reg_addr = self.get_register(reg_src);

        let target : u16 = reg_addr + self.imm_hi + instruction & 0xf - 1; // PC will be incremented after we return 

        self.pc = target;
    }

    pub fn bl_op(&mut self, instruction : u16) {

        let reg_src = ((instruction & 0xf0) >> 8) as usize;
        let reg_addr = self.get_register(reg_src);

        let target : u16 = reg_addr + self.imm_hi + instruction & 0xf - 1; // PC will be incremented after we return 

        self.registers[15] = self.pc;
        self.pc = target;
    }

    pub fn beq_op(&mut self, instruction : u16) {

        let reg_src = ((instruction & 0xf0) >> 8) as usize;
        let reg_addr = self.get_register(reg_src);

        let target : u16 = reg_addr + self.imm_hi + instruction & 0xf - 1; // PC will be incremented after we return 

        if  self.z
        {
            self.pc = target;
        }
    }

    pub fn bne_op(&mut self, instruction : u16) {

        let reg_src = ((instruction & 0xf0) >> 8) as usize;
        let reg_addr = self.get_register(reg_src);

        let target : u16 = reg_addr + self.imm_hi + instruction & 0xf - 1; // PC will be incremented after we return 

        if  ! self.z
        {
            self.pc = target;
        }
    }

    pub fn bgt_op(&mut self, instruction : u16) {

        let reg_src = ((instruction & 0xf0) >> 8) as usize;
        let reg_addr = self.get_register(reg_src);

        let target : u16 = reg_addr + self.imm_hi + instruction & 0xf - 1; // PC will be incremented after we return 

        if  ! self.z && !self.s
        {
            self.pc = target;
        }
    }

    pub fn bge_op(&mut self, instruction : u16) {

        let reg_src = ((instruction & 0xf0) >> 8) as usize;
        let reg_addr = self.get_register(reg_src);

        let target : u16 = reg_addr + self.imm_hi + instruction & 0xf - 1; // PC will be incremented after we return 

        if  self.z || !self.s
        {
            self.pc = target;
        }
    }

    pub fn blt_op(&mut self, instruction : u16) {

        let reg_src = ((instruction & 0xf0) >> 8) as usize;
        let reg_addr = self.get_register(reg_src);

        let target : u16 = reg_addr + self.imm_hi + instruction & 0xf - 1; // PC will be incremented after we return 

        if  ! self.z && self.s
        {
            self.pc = target;
        }
    }

    pub fn ble_op(&mut self, instruction : u16) {

        let reg_src = ((instruction & 0xf0) >> 8) as usize;
        let reg_addr = self.get_register(reg_src);

        let target : u16 = reg_addr + self.imm_hi + instruction & 0xf - 1; // PC will be incremented after we return 

        if  self.z || self.s
        {
            self.pc = target;
        }
    }

    pub fn branch_op(&mut self, instruction : u16) {

        match (instruction & 0x0f00) >> 12 {
            //0  - BZ, branch if zero
            0 => self.bz_op(instruction),
            //1  - BNZ, branch if not zero
            1 => self.bnz_op(instruction),
            //2  - BS, branch if sign
            2 => self.bs_op(instruction),
            //3  - BNS, branch if not sign
            3 => self.bns_op(instruction),
            //4  - BC, branch if carry
            4 => self.bc_op(instruction),
            //5  - BNC, branch if not carry
            5 => self.bnc_op(instruction),
            //6  - BA, branch always
            6 => self.ba_op(instruction),
            //7  - BL, branch and link
            7 => self.bl_op(instruction),
		    //8  - BEQ, branch if equal
		    8 => self.beq_op(instruction),
            //9  - BNE, branch if not equal
            9 => self.bne_op(instruction),
		    //10 - BGT, branch if greater than
            10 => self.bgt_op(instruction),
		    //11 - BGE, branch if greater than or equal
            11 => self.bge_op(instruction),
		    //12 - BLT, branch if less than
            12 => self.blt_op(instruction),
		    //13 - BLE, branch if less than or equal
            13 => self.ble_op(instruction),
            _ => self.nop()
        }

        self.imm_hi = 0;
    }

    #[bitmatch]
    pub fn execute_one_instruction(&mut self, /*mut*/ memory: &Vec<u16>) {
        let instruction = memory[self.pc as usize];

        // Decode instruction
        #[bitmatch]
        match instruction {
            "0000_0000_0000_0000" => self.nop(),
            "0000_0100_????_????" => self.alu_op_single_reg(instruction),
            "0000_0101_????_????" => self.int(instruction),
            "0000_0110_????_????" => self.setif(instruction),
            "0000_0111_????_????" => self.sleep(),
            "0001_????_????_????" => self.imm(instruction),
            "0010_????_????_????" => self.alu_op_reg_reg(instruction),
            "0011_????_????_????" => self.alu_op_reg_imm(instruction),
            "0100_????_????_????" => self.branch_op(instruction),
            _ => self.nop()
        }

        self.pc += 1;
    }

    pub fn execute_n_instructions(&mut self, /*mut*/ memory: &Vec<u16>, n : usize) {
        for _i in 0..n {
            self.execute_one_instruction(memory);
        }
    }

    pub fn get_register(& self, reg : usize) -> u16 {
        if reg == 0 {
            return 0;
        }
        self.registers[reg]
    }
}

#[cfg(test)]
mod tests {
    use crate::Slurm16CPU;

    #[test]
    fn test_imm() {
        let mut cpu = Slurm16CPU::new();
        let mem : Vec<u16> = vec![0x1123];
        cpu.execute_one_instruction(&mem);
        assert_eq!(cpu.imm_hi, 0x123 << 4);
    }

    #[test]
    fn test_mov_imm_reg() {
        let mut cpu = Slurm16CPU::new();
        let mem : Vec<u16> = vec![0x1123, 0x3014];
        cpu.execute_n_instructions(&mem, mem.len());
        assert_eq!(cpu.get_register(1) , 0x1234);
    }

    #[test]
    fn test_add_imm_reg() {
        let mut cpu = Slurm16CPU::new();
        let mem : Vec<u16> = vec![0x1001, 0x3010, 0x3115];
        cpu.execute_n_instructions(&mem, mem.len());
        assert_eq!(cpu.get_register(1) , 0x15);
    }

    #[test]
    fn test_sub_imm_reg() {
        let mut cpu = Slurm16CPU::new();
        let mem : Vec<u16> = vec![0x1001, 0x3010, 0x3317];
        cpu.execute_n_instructions(&mem, mem.len());
        assert_eq!(cpu.get_register(1) , 0x9);
    }

    #[test]
    fn test_and_imm_reg() {
        let mut cpu = Slurm16CPU::new();
        let mem : Vec<u16> = vec![0x1a5a, 0x3015, 0x10f0, 0x351f];
        cpu.execute_n_instructions(&mem, mem.len());
        assert_eq!(cpu.get_register(1) , 0x505);
    }

    #[test]
    fn test_or_imm_reg() {
        let mut cpu = Slurm16CPU::new();
        let mem : Vec<u16> = vec![0x1a0a, 0x3010, 0x1050, 0x3615];
        cpu.execute_n_instructions(&mem, mem.len());
        assert_eq!(cpu.get_register(1) , 0xa5a5);
    }

    #[test]
    fn test_xor_imm_reg() {
        let mut cpu = Slurm16CPU::new();
        let mem : Vec<u16> = vec![0x1a5a, 0x3015, 0x1fff, 0x371f];
        cpu.execute_n_instructions(&mem, mem.len());
        assert_eq!(cpu.get_register(1) , 0x5a5a);
    }

    #[test]
    fn test_mul_imm_reg() {
        let mut cpu = Slurm16CPU::new();
        let mem : Vec<u16> = vec![0x1a5a, 0x3015, 0x1001, 0x3810];
        cpu.execute_n_instructions(&mem, mem.len());
        assert_eq!(cpu.get_register(1) , 0x5a50);
    }

    #[test]
    fn test_mulu_imm_reg() {
        let mut cpu = Slurm16CPU::new();
        let mem : Vec<u16> = vec![0x1a5a, 0x3015, 0x1001, 0x3910];
        cpu.execute_n_instructions(&mem, mem.len());
        assert_eq!(cpu.get_register(1) , 0x000a);
    }

    #[test]
    fn test_add_reg_reg() {
        let mut cpu = Slurm16CPU::new();
        let mem : Vec<u16> = vec![0x1001, 0x3010, 0x3025, 0x2112];
        cpu.execute_n_instructions(&mem, mem.len());
        assert_eq!(cpu.get_register(1) , 0x15);
    }

    #[test]
    fn test_asr_reg() {
        let mut cpu = Slurm16CPU::new();
        let mem : Vec<u16> = vec![0x1fff, 0x3018, 0x0401];
        cpu.execute_n_instructions(&mem, mem.len());
        assert_eq!(cpu.get_register(1) , 0xfffc);
    }

    #[test]
    fn test_lsr_reg() {
        let mut cpu = Slurm16CPU::new();
        let mem : Vec<u16> = vec![0x1fff, 0x3018, 0x0411];
        cpu.execute_n_instructions(&mem, mem.len());
        assert_eq!(cpu.get_register(1) , 0x7ffc);
    }

    #[test]
    fn test_lsl_reg() {
        let mut cpu = Slurm16CPU::new();
        let mem : Vec<u16> = vec![0x1fff, 0x3018, 0x0421];
        cpu.execute_n_instructions(&mem, mem.len());
        assert_eq!(cpu.get_register(1) , 0xfff0);
    }

    #[test]
    fn test_rolc_reg() {
        let mut cpu = Slurm16CPU::new();
        let mem : Vec<u16> = vec![0x1fff, 0x3018, 0x0431];
        cpu.execute_n_instructions(&mem, mem.len());
        assert_eq!(cpu.get_register(1), 0xfff0);
        assert_eq!(cpu.c, true);
    }

    #[test]
    fn test_rorc_reg() {
        let mut cpu = Slurm16CPU::new();
        let mem : Vec<u16> = vec![0x1fff, 0x3019, 0x0441];
        cpu.execute_n_instructions(&mem, mem.len());
        assert_eq!(cpu.get_register(1), 0x7ffc);
        assert_eq!(cpu.c, true);
    }

    #[test]
    fn test_rol_reg() {
        let mut cpu = Slurm16CPU::new();
        let mem : Vec<u16> = vec![0x1fff, 0x3018, 0x0451];
        cpu.execute_n_instructions(&mem, mem.len());
        assert_eq!(cpu.get_register(1), 0xfff1);
        assert_eq!(cpu.c, false);
    }

    #[test]
    fn test_ror_reg() {
        let mut cpu = Slurm16CPU::new();
        let mem : Vec<u16> = vec![0x1fff, 0x3019, 0x0461];
        cpu.execute_n_instructions(&mem, mem.len());
        assert_eq!(cpu.get_register(1), 0xfffc);
        assert_eq!(cpu.c, false);
    }

    #[test]
    fn test_stf() {
        let mut cpu = Slurm16CPU::new();
        let mem : Vec<u16> = vec![0x0480, 0x04a0, 0x04b0, 0x04d1];
        cpu.execute_n_instructions(&mem, mem.len());
        assert_eq!(cpu.get_register(1), 0x0003);
    }

    #[test]
    fn test_branch() {
        let mut cpu = Slurm16CPU::new();
        let mem : Vec<u16> = vec![0x3013, 0x2020, 0x3311, 0x3121, 0x4102];
        cpu.execute_n_instructions(&mem, 11);
        assert_eq!(cpu.get_register(2), 4);
    }
}

