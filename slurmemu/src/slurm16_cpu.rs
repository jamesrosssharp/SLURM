use bitmatch::bitmatch;

use super::port_controller::PortController;


/// The Slurm16CPU structure encapsulates the SlURM16 CPU.
/// The implementation is not cycle accurate, and does not
/// model the interaction with the memory controller.
/// (Perhaps this should be added in future)
pub struct Slurm16CPU {
	pub z: bool,
	pub c: bool,
	pub s: bool,
	pub v: bool,

	pub z_int: bool,
	pub c_int: bool,
	pub s_int: bool,
	pub v_int: bool,

	pub imm_hi  : u16,
	pub imm_int : u16,

	pub pc: u16,
	pub registers: Vec<u16>,

	pub int_flag : bool,

	pub halt : bool,

	pub debug: bool,

	pub debug_reg: u16,
}

impl Slurm16CPU {
	pub fn new() -> Self 
	{
		Slurm16CPU {
			z: false,
			c: false, 
			s: false,
			v: false,
			z_int : false,
			c_int : false,
			s_int : false,
			v_int : false,
			imm_hi: 0,
			imm_int: 0,
			pc: 0,
			registers: vec![0; 128],
			int_flag: false,
			halt : false,
			debug : false,
			debug_reg : 0
		}
	}
	
	pub fn print_pc(& self) {
		println!("\n\nPC = {:#01x}", self.pc);
	}
	
	pub fn print_regs(& self) {
		
		for i in 0..16 {
			println!("r{} = {:#01x}", i, self.registers[i]);
		}
	}

	pub fn nop(& self) {
		// Do nothing
	}

	pub fn imm(&mut self, instruction : u16) {
		self.imm_hi = (instruction & 0xfff) << 4;
	}

	/* ------------- ALU Operations 0 - 15 ----------------- */

	pub fn alu_mov(&mut self, reg_dest: usize, _src1: u16, src2: u16) {
		self.registers[reg_dest] = src2;
	}

	pub fn alu_add(&mut self, reg_dest: usize, src1_a : u16, src2_b : u16) {
		
		let a = src1_a as u32;
		let b = src2_b as u32;

		let sum = a.wrapping_add(b);

		self.registers[reg_dest] = sum as u16;
		self.z = sum & 65535 == 0;
		match sum & 0x8000 {
			0x8000 => self.s = true,
			_ => self.s = false
		}
		self.c = sum > 65535;
		self.v = !(((a ^ b) & 0x8000) == 0x8000) && (((b ^ sum) & 0x8000) == 0x8000);
	}

	pub fn alu_adc(&mut self, reg_dest: usize, src1_a : u16, src2_b : u16) {
		
		let a = src1_a as u32;
		let b = src2_b as u32;
		let c : u32 = if self.c { 1 } else { 0 };

		let sum = a.wrapping_add(b).wrapping_add(c);

		self.registers[reg_dest] = sum as u16;
		self.z = sum & 65535 == 0;
		match sum & 0x8000 {
			0x8000 => self.s = true,
			_ => self.s = false
		}
		self.c = sum > 65535;
		self.v = !(((a ^ b) & 0x8000) == 0x8000) && (((b ^ sum) & 0x8000) == 0x8000);
	}

	pub fn alu_sub(&mut self, reg_dest: usize, src1_a : u16, src2_b: u16) {
		
		let a = src1_a as u32;
		let b = src2_b as u32;
		let sum = a.wrapping_sub(b);

		self.registers[reg_dest] = sum as u16;
		self.z = sum & 65535 == 0;
		match sum & 0x8000 {
			0x8000 => self.s = true,
			_ => self.s = false
		}
		self.c = sum > 65535;

		self.v = (((a ^ b) & 0x8000) == 0x8000) && !(((b ^ sum) & 0x8000) == 0x8000);
	}

	pub fn alu_sbb(&mut self, reg_dest: usize, src1_a : u16, src2_b : u16) {
		
		let a = src1_a as u32;
		let b = src2_b as u32;
		let c = if self.c { 1 } else { 0 };
		let sum = a.wrapping_sub(b).wrapping_sub(c);

		self.registers[reg_dest] = sum as u16;
		self.z = sum & 65535 == 0;
		match sum & 0x8000 {
			0x8000 => self.s = true,
			_ => self.s = false
		}
		self.c = sum > 65535;
	
		self.v = (((a ^ b) & 0x8000) == 0x8000) && !(((b ^ sum) & 0x8000) == 0x8000);
	}

	pub fn alu_cmp(&mut self, _reg_dest: usize, src1_a : u16, src2_b : u16) {
		
		let a = src1_a as u32;
		let b = src2_b as u32;
		let sum = a.wrapping_sub(b);

		self.z = sum & 65535 == 0;
		match sum & 0x8000 {
			0x8000 => self.s = true,
			_ => self.s = false
		}
		self.c = sum > 65535;
		self.v = (((a ^ b) & 0x8000) == 0x8000) && !(((b ^ sum) & 0x8000) == 0x8000);
	}

	pub fn alu_and(&mut self, reg_dest: usize, src1_a : u16, src2_b : u16) {
		
		let a = src1_a;
		let b = src2_b;
		let andop = b & a;

		self.registers[reg_dest] = andop;
		self.z = andop == 0;
		match andop & 0x8000 {
			0x8000 => self.s = true,
			_ => self.s = false
		}
		self.c = false;

	}

	pub fn alu_test(&mut self, _reg_dest: usize, src1_a : u16, src2_b : u16) {
		
		let a = src1_a;
		let b = src2_b;
		let andop = a & b;

		self.z = andop == 0;
		match andop & 0x8000 {
			0x8000 => self.s = true,
			_ => self.s = false
		}
		self.c = false;
	}

	pub fn alu_or(&mut self, reg_dest: usize, src1_a : u16, src2_b : u16) {
		
		let a = src1_a;
		let b = src2_b;
		let orop = b | a;

		self.registers[reg_dest] = orop;
		self.z = orop == 0;
		match orop & 0x8000 {
			0x8000 => self.s = true,
			_ => self.s = false
		}
		self.c = false;
	}

	pub fn alu_xor(&mut self, reg_dest: usize, src1_a : u16, src2_b : u16) {
		
		let a = src1_a;
		let b = src2_b;
		let xorop = b ^ a;

		self.registers[reg_dest] = xorop;
		self.z = xorop == 0;
		match xorop & 0x8000 {
			0x8000 => self.s = true,
			_ => self.s = false
		}
		self.c = false;
	}

	 pub fn alu_mul(&mut self, reg_dest: usize, src1_a : u16, src2_b : u16) {
		
		let a = src1_a as i32;
		let b = src2_b as i32;
		let mul = b * a;

		self.registers[reg_dest] = mul as u16;
		self.z = mul & 65535 == 0;
		match mul & 0x8000 {
			0x8000 => self.s = true,
			_ => self.s = false
		}
		self.c = false;
	}

	pub fn alu_mulu(&mut self, reg_dest: usize, src1_a : u16, src2_b : u16) {
		
		let a = ((src1_a as i16)) as i32;
		let b = ((src2_b as i16)) as i32;
		let mul = ((b * a) >> 16) & 0xffff;

		//println!("{:#01x} x {:#01x} = {:#01x} : {:#01x}", a, b, mul, a*b);

		self.registers[reg_dest] = mul as u16;
		self.z = mul & 0xffff == 0;
		match mul & 0x8000 {
			0x8000 => self.s = true,
			_ => self.s = false
		}
		self.c = false;
	}

 	pub fn alu_rrn(&mut self, reg_dest: usize, _src1_a : u16, src2_b : u16) {
		
		let b = src2_b as u16;
		let shift = (b >> 4) | ((b & 0xf) << 12);

		self.registers[reg_dest] = shift as u16;
	}

	pub fn alu_rln(&mut self, reg_dest: usize, _src1_a : u16, src2_b : u16) {
		
		let b = src2_b as u16;
		let shift = (b << 4) | ((b & 0xf000) >> 12);

		self.registers[reg_dest] = shift as u16;
	}


	pub fn alu_umulu(&mut self, reg_dest: usize, src1_a : u16, src2_b : u16) {
		
		let a = (src1_a as u16) as u32;
		let b = (src2_b as u16) as u32;
		let mul = ((b * a) >> 16) & 0xffff;

		self.registers[reg_dest] = mul as u16;
		self.z = mul & 0xffff == 0;
		match mul & 0x8000 {
			0x8000 => self.s = true,
			_ => self.s = false
		}
		self.c = false;
	}

	pub fn alu_bswap(&mut self, reg_dest: usize, _src1_a : u16, src2_b : u16) {
		
		let b = src2_b as u16;
		let shift = (b >> 8) | ((b & 0xff) << 8);

		self.registers[reg_dest] = shift as u16;
	}


	/* ------------- ALU Operations 16 - 31 ----------------- */
 
	pub fn alu_asr(&mut self, instruction : u16, src : u16) {
		let reg_dest	= (instruction & 0xf) as usize;
		
		let a = src as i16;
		let shift = a >> 1;

		/*if ((src & 0x8000) == 0x8000)
		{
			println!("\n\nASR = {:#01x} {:#01x}", src, shift);
		}*/

		self.registers[reg_dest] = shift as u16;
		self.z = shift == 0;
		self.s = shift > 0;
		self.c = false;
	}

	pub fn alu_lsr(&mut self, instruction : u16, src : u16) {
		let reg_dest	= (instruction & 0xf) as usize;
		
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
		let reg_dest	= (instruction & 0xf) as usize;
		
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
		let reg_dest	= (instruction & 0xf) as usize;
		
		let a = src as u16;
		let carry = if self.c { 1 } else { 0 } as u16;
		let rolc = (a << 1) | carry;

		self.registers[reg_dest] = rolc as u16;
		self.z = rolc == 0;
		match rolc & 0x8000 {
			0x8000 	=> self.s = true,
			_ 	=> self.s = false
		}
		self.c = if src & 0x8000 == 0x8000 { true } else { false };
	}

	pub fn alu_rorc(&mut self, instruction : u16, src : u16) {
		let reg_dest	= (instruction & 0xf) as usize;
		
		let a = src as u16;
		let carry = if self.c { 0x8000 } else { 0 } as u16;
		let rorc = (a >> 1) | carry;

		self.registers[reg_dest] = rorc as u16;
		self.z = rorc == 0;
		match rorc & 0x8000 {
			0x8000	=> self.s = true,
			_	=> self.s = false
		}
		self.c = if src & 0x0001 == 0x0001 { true } else { false };
	}

	pub fn alu_rol(&mut self, instruction : u16, src : u16) {
		let reg_dest	= (instruction & 0xf) as usize;
		
		let a = src as u16;
		let carry = if src & 0x8000 == 0x8000 { 1 } else { 0 } as u16;
		let rol = a << 1 | carry;

		self.registers[reg_dest] = rol as u16;
		self.z = rol == 0;
		match rol & 0x8000 {
			0x8000 	=> self.s = true,
			_ 	=> self.s = false
		}
		self.c = false;
	}

   	pub fn alu_ror(&mut self, instruction : u16, src : u16) {
		let reg_dest	= (instruction & 0xf) as usize;
		
		let a = src as u16;
		let carry = if src & 1 == 1 { 0x8000 } else { 0 } as u16;
		let ror = a >> 1 | carry;

		self.registers[reg_dest] = ror as u16;
		self.z = ror == 0;
		match ror & 0x8000 {
			0x8000	=> self.s = true,
			_	=> self.s = false
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
	
		let reg_dest	= (instruction & 0xf) as usize;
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

	/* end alu operations */

	pub fn int(&mut self, _instruction : u16 ) {
		// TODO: Interrupt

		self.imm_hi = 0;
	}

	pub fn setif(&mut self, instruction : u16) {
		//println!("Setif: {}", instruction & 1);
		self.int_flag = instruction & 1 == 1;
		self.imm_hi = 0;
	}

	pub fn sleep(&mut self) {
		self.halt = true;
		self.imm_hi = 0;
		self.int_flag = true;
	}

	pub fn alu_op_reg_imm(&mut self, instruction : u16) {
		let imm			= self.imm_hi | (instruction & 0xf);
		let reg_dest : usize	= ((instruction & 0xf0) >> 4) as usize;
		let src1_a : u16 = self.registers[reg_dest];
	
		match (instruction & 0x0f00) >> 8 {
		//0 - mov : DEST <- IMM
			0 => self.alu_mov(reg_dest, src1_a, imm), 
		//1 - add : DEST <- DEST + IMM
			1 => self.alu_add(reg_dest, src1_a,  imm),
		//2 - adc : DEST <- DEST + IMM + Carry
			2 => self.alu_adc(reg_dest, src1_a,  imm), 
		//3 - sub : DEST <- DEST - IMM 
			3 => self.alu_sub(reg_dest, src1_a,  imm),
		//4 - sbb : DEST <- DEST - IMM - Carry
			4 => self.alu_sbb(reg_dest, src1_a,  imm), 
		//5 - and : DEST <- DEST & IMM
			5 => self.alu_and(reg_dest, src1_a,  imm),
		//6 - or  : DEST <- DEST | IMM
			6 => self.alu_or(reg_dest, src1_a,  imm), 
		//7 - xor : DEST <- DEST ^ IMM
			7 => self.alu_xor(reg_dest, src1_a,  imm), 
		//8 - mul : DEST <- DEST * IMM (LO)
			8 => self.alu_mul(reg_dest, src1_a,  imm), 
		//9 - mulu : DEST <- DEST * IMM (HI)
			9 => self.alu_mulu(reg_dest, src1_a,  imm),
		//10 - rrn (rotate right nibble)
			10 => self.alu_rrn(reg_dest, src1_a,  imm),
 		//11 - rln (rotate left nibble)
			11 => self.alu_rln(reg_dest, src1_a,  imm),	
		//12 - cmp
			12 => self.alu_cmp(reg_dest, src1_a,  imm),
		//13 - test
			13 => self.alu_test(reg_dest, src1_a,  imm),
		// 14 - umulu
			14 => self.alu_umulu(reg_dest, src1_a,  imm),
		// 15 - bswap
			15 => self.alu_bswap(reg_dest, src1_a,  imm),
			_ => self.nop()
		}


		// Clear immediate
		self.imm_hi = 0;
	}

	pub fn alu_op_reg_reg(&mut self, instruction : u16) {
		let reg_src = (instruction & 0xf) as usize;
		let reg_dest : usize	= ((instruction & 0xf0) >> 4) as usize;
		let src1_a : u16 = self.registers[reg_dest];
		let src2_b = self.get_register(reg_src);
		
		match (instruction & 0x0f00) >> 8 {
		//0 - mov : DEST <- IMM
			0 => self.alu_mov(reg_dest, src1_a, src2_b), 
		//1 - add : DEST <- DEST + IMM
			1 => self.alu_add(reg_dest, src1_a, src2_b),
		//2 - adc : DEST <- DEST + IMM + Carry
			2 => self.alu_adc(reg_dest, src1_a, src2_b), 
		//3 - sub : DEST <- DEST - IMM 
			3 => self.alu_sub(reg_dest, src1_a, src2_b),
		//4 - sbb : DEST <- DEST - IMM - Carry
			4 => self.alu_sbb(reg_dest, src1_a, src2_b), 
		//5 - and : DEST <- DEST & IMM
			5 => self.alu_and(reg_dest, src1_a, src2_b),
		//6 - or  : DEST <- DEST | IMM
			6 => self.alu_or(reg_dest, src1_a, src2_b), 
		//7 - xor : DEST <- DEST ^ IMM
			7 => self.alu_xor(reg_dest, src1_a, src2_b), 
		//8 - mul : DEST <- DEST * IMM (LO)
			8 => self.alu_mul(reg_dest, src1_a, src2_b), 
		//9 - mulu : DEST <- DEST * IMM (HI)
			9 => self.alu_mulu(reg_dest, src1_a, src2_b),
		//10 - rrn (rotate right nibble)
			10 => self.alu_rrn(reg_dest, src1_a, src2_b),
 		//11 - rln (rotate left nibble)
			11 => self.alu_rln(reg_dest, src1_a, src2_b),	
			12 => self.alu_cmp(reg_dest, src1_a, src2_b),
			13 => self.alu_test(reg_dest, src1_a, src2_b),
		// 14 - umulu
			14 => self.alu_umulu(reg_dest, src1_a, src2_b),
		// 15 - bswap
			15 => self.alu_bswap(reg_dest, src1_a, src2_b),
			_ => self.nop()
		}

		// Clear immediate
		self.imm_hi = 0;
	}

	pub fn alu_op_single_reg(&mut self, instruction : u16) {
		let reg_src = (instruction & 0xf) as usize;
		let src_val = self.get_register(reg_src);
		
		match ((instruction & 0x00f0) >> 4) | 0x10 {
			//	16 - asr : arithmetic shift right REG
			16 => self.alu_asr(instruction, src_val), 
			//	17 - lsr : logical shift right REG
			17 => self.alu_lsr(instruction, src_val),
			//	18 - lsl : logical shift left REG
			18 => self.alu_lsl(instruction, src_val),
			//	19 - rolc
			19 => self.alu_rolc(instruction, src_val),
			//	20 - rorc
			20 => self.alu_rorc(instruction, src_val),
			//	21 - rol
			21 => self.alu_rol(instruction, src_val),
			//	22 - ror
			22 => self.alu_ror(instruction, src_val),
			//	23 - cc : clear carry
			23 => self.alu_cc(),
			//	24 - sc : set carry
			24 => self.alu_sc(),
			//	25 - cz : clear zero
			25 => self.alu_cz(),
			//	26 - sz : set zero
			26 => self.alu_sz(),
			//	27 - cs : clear sign
			27 => self.alu_cs(),
			//	28 - ss : set sign
			28 => self.alu_ss(),
			//	29 - stf : store flags
			29 => self.alu_stf(instruction),
			//	30 - rsf: restore flags
			30 => self.alu_rsf(src_val),
			// 31 - reserved
			_ => self.nop()
		}

		// Clear immediate
		self.imm_hi = 0;
	}

	pub fn cond_z_op(&mut self) -> bool
	{
		self.z
	}

	pub fn cond_nz_op(&mut self) -> bool
	{
		!self.z
	}

	pub fn cond_s_op(&mut self) -> bool
	{
		self.s
	}


	pub fn cond_ns_op(&mut self) -> bool
	{
		!self.s
	}

	pub fn cond_c_op(&mut self) -> bool
	{
		self.c
	}

	pub fn cond_nc_op(&mut self) -> bool
	{
		!self.c
	}

	pub fn cond_v_op(&mut self) -> bool
	{
		self.v
	}

	pub fn cond_nv_op(&mut self) -> bool
	{
		!self.v
	}


	pub fn ba_op(&mut self, instruction : u16) {

		let reg_src = ((instruction & 0xf0) >> 4) as usize;
		let reg_addr = self.get_register(reg_src);

		let target : u16 = (reg_addr + self.imm_hi + (instruction & 0xf)) - 2; // PC will be incremented after we return 

		self.pc = target;
	}

	pub fn bl_op(&mut self, instruction : u16) {

		let reg_src = ((instruction & 0xf0) >> 4) as usize;
		let reg_addr = self.get_register(reg_src);

		let target : u16 = reg_addr + self.imm_hi + (instruction & 0xf) - 2; // PC will be incremented after we return 

		self.registers[15] = self.pc + 2;
		self.pc = target;
	}

	pub fn cond_gt_op(&mut self) -> bool
	{
		(self.v == self.s) && !self.z
	}

	pub fn cond_ge_op(&mut self) -> bool
	{
		self.v == self.s
	}

	pub fn cond_lt_op(&mut self) -> bool {
		self.v != self.s
	}

	pub fn cond_le_op(&mut self) -> bool {
		self.z || (self.s != self.v)
	}

	pub fn cond_leu_op(&mut self) -> bool {
		self.c || self.z
	}

	pub fn cond_gtu_op(&mut self) -> bool {
		!self.c && !self.z
	}

	pub fn branch_op(&mut self, instruction : u16) {

		match (instruction & 0x0f00) >> 8 {
			//0  - BZ, branch if zero
			0 => if self.cond_z_op() { self.ba_op(instruction) },
			//1  - BNZ, branch if not zero
			1 => if self.cond_nz_op() { self.ba_op(instruction)},
			//2  - BS, branch if sign
			2 => if self.cond_s_op() { self.ba_op(instruction)},
			//3  - BNS, branch if not sign
			3 => if self.cond_ns_op() { self.ba_op(instruction)},
			//4  - BC, branch if carry
			4 => if self.cond_c_op() { self.ba_op(instruction)},
			//5  - BNC, branch if not carry
			5 => if self.cond_nc_op() { self.ba_op(instruction)},
			//6  - BV, branch if signed overflow
			6 => if self.cond_v_op() { self.ba_op(instruction)},
			//7  - BNV, branch if not signed overflow
			7 => if self.cond_nv_op() { self.ba_op(instruction)},
		
			//8  - BLT, branch if (signed) less than
			8 => if self.cond_lt_op() { self.ba_op(instruction)},
		
			//9  - BLE, branch if (signed) less than or equal
			9 => if self.cond_le_op() { self.ba_op(instruction)},
		
			//10 - BGT, branch if (signed) greater than
			10 => if self.cond_gt_op() { self.ba_op(instruction)},

			//11 - BGE, branch if (signed) greater than or equal
			11 => if self.cond_ge_op() { self.ba_op(instruction)},

			//12 - BLEU, branch if (unsigned) less than or equal
			12 => if self.cond_leu_op() { self.ba_op(instruction)},
			//13 - BGTU, branch if (unsigned) greater than
			13 => if self.cond_gtu_op() { self.ba_op(instruction)},

			//14 - BA, branch always
			14 => self.ba_op(instruction),
			//15 - BL, branch and link
			15 => self.bl_op(instruction),

			_ => self.nop()
		}

		self.imm_hi = 0;
	}

	pub fn cond_is_true(&mut self, cond : u16) -> bool
	{
		 match cond {
			//0  - BZ, branch if zero
			0 => self.cond_z_op(),
			//1  - BNZ, branch if not zero
			1 => self.cond_nz_op(),
			//2  - BS, branch if sign
			2 => self.cond_s_op(),
			//3  - BNS, branch if not sign
			3 => self.cond_ns_op(),
			//4  - BC, branch if carry
			4 => self.cond_c_op(),
			//5  - BNC, branch if not carry
			5 => self.cond_nc_op(),
			//6  - BV, branch if signed overflow
			6 => self.cond_v_op(),
			//7  - BNV, branch if not signed overflow
			7 => self.cond_nv_op(),
		
			//8  - BLT, branch if (signed) less than
			8 => self.cond_lt_op(),
		
			//9  - BLE, branch if (signed) less than or equal
			9 => self.cond_le_op(),
		
			//10 - BGT, branch if (signed) greater than
			10 => self.cond_gt_op(),

			//11 - BGE, branch if (signed) greater than or equal
			11 => self.cond_ge_op(),

			//12 - BLEU, branch if (unsigned) less than or equal
			12 => self.cond_leu_op(),
			//13 - BGTU, branch if (unsigned) greater than
			13 => self.cond_gtu_op(),

			_ => true,
		}
	}

	pub fn condmov_op(&mut self, instruction : u16) {

		let condtrue : bool = self.cond_is_true((instruction & 0x0f00) >> 8);

		if condtrue {
			let reg_src = (instruction & 0xf) as usize;
			let src_val = self.get_register(reg_src);
			let reg_dest	= ((instruction & 0xf0) >> 4) as usize;
			self.registers[reg_dest] = src_val;
		}

		self.imm_hi = 0;
	}

	pub fn ret_op(&mut self, instruction : u16, mem:  & mut Vec<u16>) {
		if (instruction & 1) == 1 {
			// IRET
			self.int_flag = true;
			let addr = self.get_register(14);
			let old_pc = self.pc;
			self.pc = addr - 2; // This will get incremented
			self.c = self.c_int;
			self.v = self.v_int;
			self.s = self.s_int;
			self.z = self.z_int;
			self.imm_hi = self.imm_int;

			/*if self.get_register(14) == 0x1e0e
			{
				self.debug = true;
	
				println!("This is the start of your doom. r13 = {:#01x}", self.get_register(13));
	
				let mut addr2 = self.get_register(13); 
				for i in 0..10
				{
					println!("{:#01x} = {:#01x}", addr2, mem[addr2 as usize >> 1]);
					addr2 += 2;
				}
			}*/

			//println!("IRET: flags {} {} {} pc {:#01x} instruction {:#01x} ilr {:#01x} r15 {:#01x} {:#01x}", self.c, self.z, self.s, old_pc, mem[addr as usize>>1], self.get_register(14), 
			//	self.get_register(15),
			//	self.imm_hi);
		} else {
			// RET
			let addr = self.get_register(15);
			self.pc = addr - 2; // This will get incremented
			self.imm_hi = 0;
			/*if self.debug {
				println!("RET: {:#01x}", addr);
				
				std::process::exit(1); 
			}*/
		}
	}

	pub fn port_op(&mut self, instruction : u16, portcon:  & mut PortController) {

		let reg_p = ((instruction & 0xf00) >> 8) as usize;
		let reg_addr : u16 = self.get_register(reg_p);

		let imm : u16 = self.imm_hi | (instruction & 0xf);

		let port : u16 = imm + reg_addr;

		let reg_src = ((instruction & 0xf0) >> 4) as usize;
		let val : u16 = self.get_register(reg_src);

		let write = (instruction & 0x1000) == 0x1000;

		//if write && (port & 0xff00 >= 0x5000) && (port & 0xff00 < 0x5400)
		//{
		//	println!("Port op: {:#01x} {:#01x} {} {:#01x}", port, val, write, self.pc );
		//}	

		let val : u16 = portcon.port_op(port, val, write);

		if !write {
			self.registers[reg_src] = val;
		}

		self.imm_hi = 0;
	}
	
	pub fn mem_op(&mut self, instruction : u16, mem:  & mut Vec<u16>) {

		let reg_p = ((instruction & 0x0f00) >> 8) as usize;
		let reg_addr : u16 = self.get_register(reg_p);

		let imm : u16 = self.imm_hi | (instruction & 0xf);

		let addr : usize = imm.wrapping_add(reg_addr) as usize;

		let reg_src = ((instruction & 0xf0) >> 4) as usize;
		let val : u16 = self.get_register(reg_src);

		let write = (instruction & 0x1000) == 0x1000;

		//if addr >= (0xb782 as usize) && addr <= (0xb7c2 as usize) && write {
		//	  println!("Mem op: {:#01x} {:#01x} {} {:#01x} {:#01x}", addr, val, write, mem[addr>>1], self.pc);
		//}

		if !write {
			self.registers[reg_src] = mem[addr>>1];
		}
		else {
			mem[addr>>1] = val;
		}

		self.imm_hi = 0;
	}

	pub fn byte_mem_op(&mut self, instruction : u16, mem:  & mut Vec<u16>) {

		let reg_p = ((instruction & 0xf00) >> 8) as usize;
		let reg_addr : u16 = self.get_register(reg_p);

		let imm : u16 = self.imm_hi | (instruction & 0xf);

		let addr : usize = (imm + reg_addr) as usize;

		let reg_src = ((instruction & 0xf0) >> 4) as usize;
		let val : u16 = self.get_register(reg_src);

		let write = (instruction & 0x1000) == 0x1000;

		//println!("Mem op: {:#01x} {:#01x} {} {:#01x}", addr, val, write, mem[addr]);
	   
		//if addr >= (0x7f00 as usize) {
		//	  println!("Byte Mem op: {:#01x} {:#01x} {} {:#01x} {:#01x}", addr, val, write, mem[addr], self.pc);
		//}

		if !write {
			if addr & 1 == 0
			{
				self.registers[reg_src] = mem[addr>>1] & 0xff;
			}
			else
			{
				self.registers[reg_src] = (mem[addr>>1] >> 8) & 0xff;
			}
		}
		else {
			let v = mem[addr >> 1];

			if addr & 1 == 0
			{
				mem[addr>>1] = (v & 0xff00) | (val & 0xff);
			}
			else
			{
				mem[addr >> 1] = (v & 0x00ff) | ((val & 0xff) << 8)
			}

		}

		self.imm_hi = 0;
	}

	pub fn byte_mem_op_sx(&mut self, instruction : u16, mem:  & mut Vec<u16>) {

		let reg_p = ((instruction & 0xf00) >> 8) as usize;
		let reg_addr : u16 = self.get_register(reg_p);

		let imm : u16 = self.imm_hi | (instruction & 0xf);

		let addr : usize = (imm + reg_addr) as usize;

		let reg_src = ((instruction & 0xf0) >> 4) as usize;

		if addr & 1 == 0
		{
			let mut val : u16 = mem[addr>>1] & 0xff; 
			if (val & 0x80) == 0x80 {
				val |= 0xff00;
			}
			self.registers[reg_src] = val;
		}
		else
		{
			let mut val : u16 = (mem[addr>>1] >> 8) & 0xff; 
			if (val & 0x80) == 0x80 {
				val |= 0xff00;
			}
			self.registers[reg_src] = val;
		}

		self.imm_hi = 0;
	}

	pub fn three_reg_alu_op(&mut self, instruction : u16, _mem:  & mut Vec<u16>) {
		let reg_src 		= (instruction & 0xf) as usize;
		let reg_dest : usize	= ((instruction & 0xf00) >> 8) as usize;
		let src1_a 		= self.get_register(((instruction & 0xf0) >> 4) as usize);
		let src2_b 		= self.get_register(reg_src);
		
		let condtrue : bool = self.cond_is_true((instruction & 0x0f00) >> 8);
		
		if condtrue {
			match (self.imm_hi & 0x00f0) >> 4 {
			//0 - mov : DEST <- IMM
				0 => self.alu_mov(reg_dest, src1_a, src2_b), 
			//1 - add : DEST <- DEST + IMM
				1 => self.alu_add(reg_dest, src1_a, src2_b),
			//2 - adc : DEST <- DEST + IMM + Carry
				2 => self.alu_adc(reg_dest, src1_a, src2_b), 
			//3 - sub : DEST <- DEST - IMM 
				3 => self.alu_sub(reg_dest, src1_a, src2_b),
			//4 - sbb : DEST <- DEST - IMM - Carry
				4 => self.alu_sbb(reg_dest, src1_a, src2_b), 
			//5 - and : DEST <- DEST & IMM
				5 => self.alu_and(reg_dest, src1_a, src2_b),
			//6 - or  : DEST <- DEST | IMM
				6 => self.alu_or(reg_dest, src1_a, src2_b), 
			//7 - xor : DEST <- DEST ^ IMM
				7 => self.alu_xor(reg_dest, src1_a, src2_b), 
			//8 - mul : DEST <- DEST * IMM (LO)
				8 => self.alu_mul(reg_dest, src1_a, src2_b), 
			//9 - mulu : DEST <- DEST * IMM (HI)
				9 => self.alu_mulu(reg_dest, src1_a, src2_b),
			//10 - rrn (rotate right nibble)
				10 => self.alu_rrn(reg_dest, src1_a, src2_b),
			//11 - rln (rotate left nibble)
				11 => self.alu_rln(reg_dest, src1_a, src2_b),	
				12 => self.alu_cmp(reg_dest, src1_a, src2_b),
				13 => self.alu_test(reg_dest, src1_a, src2_b),
			// 14 - umulu
				14 => self.alu_umulu(reg_dest, src1_a, src2_b),
			// 15 - bswap
				15 => self.alu_bswap(reg_dest, src1_a, src2_b),
				_ => self.nop()
			}
		}

		// Clear immediate
		self.imm_hi = 0;
	}

	pub fn alu_op_extreg(&mut self, instruction : u16) {

		// TODO: Get src and dest etc. 

		let reg_reg 		= (instruction & 0xf) as usize;
		let reg_ext : usize	= ((instruction & 0x7f0) >> 4) as usize;
		
		let mut src = reg_reg;
		let mut reg_dest = reg_ext;
	
		if instruction & 0x800 == 0x800
		{
			src = reg_ext;
			reg_dest = reg_reg;
		}

		let src1_a 		= self.get_register(reg_dest);
		let src2_b 		= self.get_register(src);
	
		//println!("extreg {} {} {}", src, reg_dest, (self.imm_hi & 0x00f0) >> 4); 
	
		match (self.imm_hi & 0x00f0) >> 4 {
		//0 - mov : DEST <- IMM
			0 => self.alu_mov(reg_dest, src1_a, src2_b), 
		//1 - add : DEST <- DEST + IMM
			1 => self.alu_add(reg_dest, src1_a, src2_b),
		//2 - adc : DEST <- DEST + IMM + Carry
			2 => self.alu_adc(reg_dest, src1_a, src2_b), 
		//3 - sub : DEST <- DEST - IMM 
			3 => self.alu_sub(reg_dest, src1_a, src2_b),
		//4 - sbb : DEST <- DEST - IMM - Carry
			4 => self.alu_sbb(reg_dest, src1_a, src2_b), 
		//5 - and : DEST <- DEST & IMM
			5 => self.alu_and(reg_dest, src1_a, src2_b),
		//6 - or  : DEST <- DEST | IMM
			6 => self.alu_or(reg_dest, src1_a, src2_b), 
		//7 - xor : DEST <- DEST ^ IMM
			7 => self.alu_xor(reg_dest, src1_a, src2_b), 
		//8 - mul : DEST <- DEST * IMM (LO)
			8 => self.alu_mul(reg_dest, src1_a, src2_b), 
		//9 - mulu : DEST <- DEST * IMM (HI)
			9 => self.alu_mulu(reg_dest, src1_a, src2_b),
		//10 - rrn (rotate right nibble)
			10 => self.alu_rrn(reg_dest, src1_a, src2_b),
		//11 - rln (rotate left nibble)
			11 => self.alu_rln(reg_dest, src1_a, src2_b),	
			12 => self.alu_cmp(reg_dest, src1_a, src2_b),
			13 => self.alu_test(reg_dest, src1_a, src2_b),
		// 14 - umulu
			14 => self.alu_umulu(reg_dest, src1_a, src2_b),
		// 15 - bswap
			15 => self.alu_bswap(reg_dest, src1_a, src2_b),
			_ => self.nop()
		}

		// Clear immediate
		self.imm_hi = 0;
	}


	pub fn stix(&mut self, instruction : u16) {

		// TODO: Get src and dest etc. 

		let reg_reg 		= (instruction & 0xf) as usize;
	

		let x : u16 = (self.imm_int & 0xfff0) | (if self.v_int {0x0008} else {0}) | 
					    (if self.s_int {0x0004} else {0}) |
					    (if self.c_int {0x0002} else {0}) | 
				 	    (if self.z_int {0x0001} else {0});

		//println!("stix: {x}");
	
		self.registers[reg_reg] = x;

	}

	pub fn rsix(&mut self, instruction : u16) {

		// TODO: Get src and dest etc. 

		let reg_reg 		= (instruction & 0xf) as usize;
	
		let x = self.registers[reg_reg];

		//println!("rsix: {x}");

		self.imm_int = x & 0xfff0;
		self.v_int = x & 0x0008 == 0x0008;
		self.s_int = x & 0x0004 == 0x0004;
		self.c_int = x & 0x0002 == 0x0002;
		self.z_int = x & 0x0001 == 0x0001;
	}

	pub fn ex_ld_op(&mut self, instruction : u16, mem:  & mut Vec<u16>) {

		let reg_p = ((instruction & 0x0f00) >> 8) as usize;
		let reg_addr : u16 = self.get_register(reg_p);

		let addr : usize = (reg_addr as u32 | 0x10000)  as usize;

		let reg_src = ((instruction & 0xf0) >> 4) as usize;

		self.registers[reg_src] = mem[addr>>1];

		self.imm_hi = 0;
	}

	pub fn ex_ldb_op(&mut self, instruction : u16, mem:  & mut Vec<u16>) {

		let reg_p = ((instruction & 0xf00) >> 8) as usize;
		let reg_addr : u16 = self.get_register(reg_p);

		let addr : usize = (0x10000 | reg_addr as u32) as usize;
		
		let reg_src = ((instruction & 0xf0) >> 4) as usize;

		if addr & 1 == 0
		{
			self.registers[reg_src] = mem[addr>>1] & 0xff;
		}
		else
		{
			self.registers[reg_src] = (mem[addr>>1] >> 8) & 0xff;
		}

		self.imm_hi = 0;
	}

	pub fn ex_ldbsx_op(&mut self, instruction : u16, mem:  & mut Vec<u16>) {

		let reg_p = ((instruction & 0xf00) >> 8) as usize;
		let reg_addr : u16 = self.get_register(reg_p);

		let addr : usize = (0x10000 | reg_addr as u32) as usize;

		let reg_src = ((instruction & 0xf0) >> 4) as usize;

		if addr & 1 == 0
		{
			let mut val : u16 = mem[addr>>1] & 0xff; 
			if (val & 0x80) == 0x80 {
				val |= 0xff00;
			}
			self.registers[reg_src] = val;
		}
		else
		{
			let mut val : u16 = (mem[addr>>1] >> 8) & 0xff; 
			if (val & 0x80) == 0x80 {
				val |= 0xff00;
			}
			self.registers[reg_src] = val;
		}

		self.imm_hi = 0;
	}

	pub fn ex_st_op(&mut self, instruction : u16, mem:  & mut Vec<u16>) {

		let reg_p = ((instruction & 0x0f00) >> 8) as usize;
		let reg_addr : u16 = self.get_register(reg_p);

		let addr : usize = (0x10000 | reg_addr as u32) as usize;

		let reg_src = ((instruction & 0xf0) >> 4) as usize;
		let val : u16 = self.get_register(reg_src);

		mem[addr>>1] = val;

		self.imm_hi = 0;
	}

	pub fn ex_stb_op(&mut self, instruction : u16, mem:  & mut Vec<u16>) {

		let reg_p = ((instruction & 0xf00) >> 8) as usize;
		let reg_addr : u16 = self.get_register(reg_p);

		let addr : usize = (0x10000 | reg_addr as u32) as usize;

		let reg_src = ((instruction & 0xf0) >> 4) as usize;
		let val : u16 = self.get_register(reg_src);

		let v = mem[addr >> 1];

		if addr & 1 == 0
		{
			mem[addr>>1] = (v & 0xff00) | (val & 0xff);
		}
		else
		{
			mem[addr >> 1] = (v & 0x00ff) | ((val & 0xff) << 8)
		}

		self.imm_hi = 0;
	}



	#[bitmatch]
	pub fn execute_one_instruction(&mut self, mem: &mut Vec<u16>, portcon: &mut PortController, irq : u8) {

		/*if self.pc >= 0x5e8 && self.pc <= 0x9e8
		{
			self.debug = true;
			println!("PC={:#01x} SP={:#01x} R12={:#01x}", self.pc, self.registers[13], self.registers[12]);
		}
		
		if self.pc == 0x9e8
		{
			self.debug = false;
		}*/

		/*if self.debug && self.registers[12] != self.debug_reg
		{
			println!("PC={:#01x} SP={:#01x} R12={:#01x}", self.pc, self.registers[13], self.registers[12]);
			self.debug_reg = self.registers[12];
		}*/


		// Interrupt?
		if (irq != 0) && self.int_flag {
	   
			self.imm_int = self.imm_hi;

			self.registers[14] = self.pc;

			//println!("Int: flags: {} {} {} {} {} {} {:#01x}", self.c, self.z, self.s, self.v, self.imm_int, irq, self.pc);

			self.c_int = self.c;
			self.z_int = self.z;
			self.s_int = self.s;
			self.v_int = self.v;


			self.int_flag = false;
			self.pc = (irq as u16) * 4;
			self.halt = false;
		}


		if self.halt { return; }

		let instruction = mem[(self.pc>>1) as usize];

		//println!("PC: {}", self.pc);

		// Decode instruction
		#[bitmatch]
		match instruction {
			"0000_0000_0000_0000" => self.nop(),
			"0000_0001_0000_000?" => self.ret_op(instruction, mem),
			"0000_0010_????_????" => self.stix(instruction),
			"0000_0011_????_????" => self.rsix(instruction),
			"0000_0100_????_????" => self.alu_op_single_reg(instruction),
			"0000_0101_????_????" => self.int(instruction),
			"0000_0110_????_????" => self.setif(instruction),
			"0000_0111_????_????" => self.sleep(),
			"0001_????_????_????" => self.imm(instruction),
			"0010_????_????_????" => self.alu_op_reg_reg(instruction),
			"0011_????_????_????" => self.alu_op_reg_imm(instruction),
			"0100_????_????_????" => self.branch_op(instruction),
			"0101_????_????_????" => self.condmov_op(instruction),
			"0110_????_????_????" => self.alu_op_extreg(instruction),
			"0111_????_????_?000" => self.ex_ld_op(instruction, mem),
			"0111_????_????_?001" => self.ex_ldb_op(instruction, mem),
			"0111_????_????_?01?" => self.ex_ldbsx_op(instruction, mem),
			"0111_????_????_?10?" => self.ex_st_op(instruction, mem),
			"0111_????_????_?11?" => self.ex_stb_op(instruction, mem),
			"1000_????_????_????" => self.byte_mem_op_sx(instruction, mem),
			"1001_????_????_????" => self.three_reg_alu_op(instruction, mem),
			"101?_????_????_????" => self.byte_mem_op(instruction, mem),
			"110?_????_????_????" => self.mem_op(instruction, mem),
			"111?_????_????_????" => self.port_op(instruction, portcon),
			_ => self.nop()
		}

		self.pc += 2;
	}

	pub fn get_register(& self, reg : usize) -> u16 {
		if reg == 0 {
			return 0;
		}
		self.registers[reg]
	}

	pub fn get_pc(& self) -> u16 {
		self.pc
	}
}

