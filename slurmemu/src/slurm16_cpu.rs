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
			v: false,
			imm_hi: 0,
			pc: 0,
			registers: vec![0; 16],
			int_flag: false,
			halt : false
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

	pub fn alu_mov(&mut self, instruction : u16, src: u16) {
		let reg_dest	= ((instruction & 0xf0) >> 4) as usize;
		self.registers[reg_dest] = src;
	}

	pub fn alu_add(&mut self, instruction : u16, src : u16) {
		let reg_dest	= ((instruction & 0xf0) >> 4) as usize;
		
		let a = src as u32;
		let b = self.get_register(reg_dest) as u32;

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

	pub fn alu_adc(&mut self, instruction : u16, src : u16) {
		let reg_dest	= ((instruction & 0xf0) >> 4) as usize;
		
		let a = src as u32;
		let b = self.get_register(reg_dest) as u32;
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

	pub fn alu_sub(&mut self, instruction : u16, src : u16) {
		let reg_dest	= ((instruction & 0xf0) >> 4) as usize;
		
		let a = src as u32;
		let b = self.get_register(reg_dest) as u32;
		let sum = b.wrapping_sub(a);

		//println!("Subtract: {} {} {}", a, b, sum);

		self.registers[reg_dest] = sum as u16;
		self.z = sum & 65535 == 0;
		match sum & 0x8000 {
			0x8000 => self.s = true,
			_ => self.s = false
		}
		self.c = sum > 65535;

		self.v = (((a ^ b) & 0x8000) == 0x8000) && !(((a ^ sum) & 0x8000) == 0x8000);
	}

	pub fn alu_sbb(&mut self, instruction : u16, src : u16) {
		let reg_dest	= ((instruction & 0xf0) >> 4) as usize;
		
		let a = src as u32;
		let b = self.get_register(reg_dest) as u32;
		let c = if self.c { 1 } else { 0 };
		let sum = b.wrapping_sub(a).wrapping_sub(c);

		//println!("Subtract: {} {} {}", a, b, sum);

		self.registers[reg_dest] = sum as u16;
		self.z = sum & 65535 == 0;
		match sum & 0x8000 {
			0x8000 => self.s = true,
			_ => self.s = false
		}
		self.c = sum > 65535;
	
		self.v = (((a ^ b) & 0x8000) == 0x8000) && !(((a ^ sum) & 0x8000) == 0x8000);
	}

	pub fn alu_cmp(&mut self, instruction : u16, src : u16) {
		let reg_dest	= ((instruction & 0xf0) >> 4) as usize;
		
		let a = src as u32;
		let b = self.get_register(reg_dest) as u32;
		let sum = b.wrapping_sub(a);

		self.z = sum & 65535 == 0;
		match sum & 0x8000 {
			0x8000 => self.s = true,
			_ => self.s = false
		}
		self.c = sum > 65535;
		self.v = (((a ^ b) & 0x8000) == 0x8000) && !(((a ^ sum) & 0x8000) == 0x8000);
	}

	pub fn alu_and(&mut self, instruction : u16, src : u16) {
		let reg_dest	= ((instruction & 0xf0) >> 4) as usize;
		
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
		let reg_dest	= ((instruction & 0xf0) >> 4) as usize;
		
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
		let reg_dest	= ((instruction & 0xf0) >> 4) as usize;
		
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
		let reg_dest	= ((instruction & 0xf0) >> 4) as usize;
		
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
		let reg_dest	= ((instruction & 0xf0) >> 4) as usize;
		
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
		let reg_dest	= ((instruction & 0xf0) >> 4) as usize;
		
		let a = (src as i16) as i32;
		let b = (self.get_register(reg_dest) as i16) as i32;
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
		let reg_dest	= (instruction & 0xf) as usize;
		
		let a = src as i16;
		let shift = a >> 1;

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
		let reg_dest	= (instruction & 0xf) as usize;
		
		let a = src as u16;
		let carry = if self.c { 0x8000 } else { 0 } as u16;
		let rorc = a >> 1 | carry;

		self.registers[reg_dest] = rorc as u16;
		self.z = rorc == 0;
		match rorc & 0x8000 {
			0x8000	=> self.s = true,
			_		=> self.s = false
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
			0x8000 => self.s = true,
			_ => self.s = false
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
			_		=> self.s = false
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
		
		match (instruction & 0x0f00) >> 8 {
		//0 - mov : DEST <- IMM
			0 => self.alu_mov(instruction, imm), 
		//1 - add : DEST <- DEST + IMM
			1 => self.alu_add(instruction, imm),
		//2 - adc : DEST <- DEST + IMM + Carry
			2 => self.alu_adc(instruction, imm), 
		//3 - sub : DEST <- DEST - IMM 
			3 => self.alu_sub(instruction, imm),
		//4 - sbb : DEST <- DEST - IMM - Carry
			4 => self.alu_sbb(instruction, imm), 
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
			2 => self.alu_adc(instruction, src_val), 
		//3 - sub : DEST <- DEST - IMM 
			3 => self.alu_sub(instruction, src_val),
		//4 - sbb : DEST <- DEST - IMM - Carry
			4 => self.alu_sbb(instruction, src_val), 
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
		self.c && self.z
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

	pub fn condmov_op(&mut self, instruction : u16) {

		let condtrue : bool = match (instruction & 0x0f00) >> 8 {
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
		};

		if condtrue {
			let reg_src = (instruction & 0xf) as usize;
			let src_val = self.get_register(reg_src);
			let reg_dest	= ((instruction & 0xf0) >> 4) as usize;
			self.registers[reg_dest] = src_val;
		}

		self.imm_hi = 0;
	}

	pub fn ret_op(&mut self, instruction : u16) {
		if (instruction & 1) == 1 {
			//println!("IRET: flags {} {} {} pc {:#01x} instruction {:#01x} ilr {:#01x}", self.c, self.z, self.s, self.pc, instruction, self.get_register(14));
			self.int_flag = true;
			let addr = self.get_register(14);
			self.pc = addr - 2; // This will get incremented


		} else {

			let addr = self.get_register(15);
			self.pc = addr - 2; // This will get incremented

		}
		self.imm_hi = 0;
	}

	pub fn port_op(&mut self, instruction : u16, portcon:  & mut PortController) {

		let reg_p = ((instruction & 0xf00) >> 8) as usize;
		let reg_addr : u16 = self.get_register(reg_p);

		let imm : u16 = self.imm_hi | (instruction & 0xf);

		let port : u16 = imm + reg_addr;

		let reg_src = ((instruction & 0xf0) >> 4) as usize;
		let val : u16 = self.get_register(reg_src);

		let write = (instruction & 0x1000) == 0x1000;

		//println!("Port op: {:#01x} {:#01x} {}", port, val, write );

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

		//if addr >= (0x7f00 as usize) {
		//	  println!("Mem op: {:#01x} {:#01x} {} {:#01x} {:#01x}", addr, val, write, mem[addr], self.pc);
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




	#[bitmatch]
	pub fn execute_one_instruction(&mut self, mem: &mut Vec<u16>, portcon: &mut PortController, irq : u8) {

		// Interrupt?
		if (irq != 0) && self.int_flag {
	   
			// If the previous instruction is an imm, we need to make this two instruction
			// unit atomic on interrupts, so we set return address back an instruction.
			let ins_minus_1 = mem[((self.pc - 2)>>1) as usize];
			if (ins_minus_1 & 0xf000) == 0x1000
			{
				self.registers[14] = self.pc - 2;
			}
			else
			{
				self.registers[14] = self.pc;
			}

			//println!("Int: flags: {} {} {}", self.c, self.z, self.s);


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
			"0000_0001_0000_000?" => self.ret_op(instruction),
			"0000_0100_????_????" => self.alu_op_single_reg(instruction),
			"0000_0101_????_????" => self.int(instruction),
			"0000_0110_????_????" => self.setif(instruction),
			"0000_0111_????_????" => self.sleep(),
			"0001_????_????_????" => self.imm(instruction),
			"0010_????_????_????" => self.alu_op_reg_reg(instruction),
			"0011_????_????_????" => self.alu_op_reg_imm(instruction),
			"0100_????_????_????" => self.branch_op(instruction),
			"0101_????_????_????" => self.condmov_op(instruction),
			"1000_????_????_????" => self.byte_mem_op_sx(instruction, mem),
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

