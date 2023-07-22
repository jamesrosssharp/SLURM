/*
 *
 *  Flash controller
 *
 */

enum FlashDMAState {
    Idle,
    WakeFlash,
    PerformDMA,
}

pub struct FlashDMA {

    flash_address_lo : u16,
    flash_address_hi : u16,
    flash_address2 : u32,
    go : bool,
    wake : bool,
    state : FlashDMAState,
    dma_address : u16,
    dma_count : u16,
    dma_address2: u16,
    dma_count2 : u16,
    done : bool,
    data: u16,  /* data reg; not really used since DMA was implemented */
    flash_data : Vec<u16>,
    dummy_cycles : u32,
}

impl FlashDMA {

    pub fn new() -> Self {
        FlashDMA {
            flash_address_lo : 0,
            flash_address_hi : 0,
            flash_address2   : 0,
            go : false,
            wake : false,
            state : FlashDMAState::Idle,
            dma_address : 0,
            dma_count : 0,
            dma_address2 : 0,
            dma_count2 : 0,
            done : false,
            data : 0,
            flash_data : vec![],
            dummy_cycles : 0,
        }
    }

    pub fn port_op(& mut self, port : u16, val: u16, write : bool) -> u16
    {
        if write {
            match port & 0xf {
                0 => { self.flash_address_lo = val; }, /* Flash Address lo reg */
                1 => { self.flash_address_hi = val; }, /* Flash Address hi reg */
		        2 => { self.go = val & 1 == 1; self.wake = val & 2 == 2; }, /* CMD reg */
		        5 => { self.dma_address = val; }, /* DMA memory address */
		        6 => { self.dma_count = val; }, /* DMA transfer count (16-bit words) */
                _ => {},
            }
        }
        else {
            match port & 0xf {
                3 => /* Data reg */ { return self.data },
                4 => /* Status reg */{ if self.done { return 1; } },
                _ => {},
            }

        }
        return 0;
    }

    pub fn set_flash(& mut self, flash : &Vec<u16>)
    {
        for i in 0..flash.len() {
            self.flash_data.push(flash[i]);
        }
    }

    pub fn step(& mut self, mem : & mut Vec<u16>) -> bool /* interrupt */
    {

        let mut int = false;

        match self.state {
            FlashDMAState::Idle => {
                if self.go {
                    self.state = FlashDMAState::PerformDMA;
                    self.go = false;
                    self.dummy_cycles = 25 / 3 * 24;
                    self.flash_address2 = (((self.flash_address_hi as u32) << 16)  | (self.flash_address_lo as u32)) - 1024*1024/2; // Flash data starts at 1M
                    self.dma_address2 = self.dma_address;
                    self.dma_count2 = self.dma_count + 1;
                } 
                else if self.wake {
                    self.state = FlashDMAState::WakeFlash;
                    self.wake = false;
                    self.dummy_cycles = 25 / 3 * 24;
                    self.done = false;
                }
            }
            FlashDMAState::WakeFlash => {
                self.dummy_cycles -= 1;

                if self.dummy_cycles == 0
                {
                    self.done = true;
                    self.state = FlashDMAState::Idle;
                    int = true;
                }
            }
            FlashDMAState::PerformDMA => {

                self.dummy_cycles -= 1;

                if self.dummy_cycles == 0
                {
                    self.dummy_cycles = 1; //16; //25 / 3 * 16;

                    let data : u16 = if (self.flash_address2 as usize) < self.flash_data.len() { self.flash_data[self.flash_address2 as usize] } else { 0xffff}; 
                    mem[self.dma_address2 as usize] = data;
                    self.flash_address2 += 1;
                    self.dma_address2 += 1;
                    self.dma_count2 -= 1;
                    if self.dma_count2 == 0
                    {
                        self.done = true;
                        self.state = FlashDMAState::Idle;
                        int = true; 
                    }
                }

            }
        }
 
        /* return */ int
    }

}

