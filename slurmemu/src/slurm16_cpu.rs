use bitmatch::bitmatch;

pub struct Slurm16CPU {
    pub z: bool,
    pub c: bool,
    pub s: bool,

    pub imm_hi: u16,

    pub pc: u16,
    pub registers: Vec<u16>,

    pub int_flag : bool,
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
            int_flag: false
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
 

    pub fn alu_op_reg_imm(&mut self, instruction : u16) {
        let imm         = self.imm_hi | (instruction & 0xf);
        //let reg_src = (instruction & 0xf) as usize;
        //let src_val = self.registers[reg_src];
        
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
        // 10 - 15 - reserved
            _ => self.nop()
        }


        // Clear immediate
        self.imm_hi = 0;
    }

    pub fn alu_op_reg_reg(&mut self, instruction : u16) {
        let reg_src = (instruction & 0xf) as usize;
        let src_val = self.registers[reg_src];
        
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
        // 10 - 15 - reserved
            _ => self.nop()
        }

        // Clear immediate
        self.imm_hi = 0;
    }

    pub fn alu_op_single_reg(&mut self, instruction : u16) {
        let reg_src = (instruction & 0xf) as usize;
        let src_val = self.registers[reg_src];
        
        match ((instruction & 0x0f00) >> 8) | 0x10 {
            //  16 - asr : arithmetic shift right REG
            //  17 - lsr : logical shift right REG
            //  18 - lsl : logical shift left REG
            //  19 - rolc
            //  20 - rorc
            //  21 - rol
            //  22 - ror
            //  23 - cc : clear carry
            //  24 - sc : set carry
            //  25 - cz : clear zero
            //  26 - sz : set zero
            //  27 - cs : clear sign
            //  28 - ss : set sign
            //  29 - stf : store flags
            //  30 - rsf: restore flags
            // 31 - reserved
            _ => self.nop()
        }

        // Clear immediate
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
            "0001_????_????_????" => self.imm(instruction),
            "0010_????_????_????" => self.alu_op_reg_reg(instruction),
            "0011_????_????_????" => self.alu_op_reg_imm(instruction),
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


}

