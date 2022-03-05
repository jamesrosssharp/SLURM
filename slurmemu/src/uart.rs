use std::io::stdout;
use std::io::Write;

pub struct Uart {


}

impl Uart {

    pub fn new() -> Self {
        Uart { }

    }

    #[allow(unused_must_use)]
    pub fn port_op(& self, _port : u16, val: u16, write : bool) -> u16
    {
        if write {
                print!("{}", (val & 0xff) as u8 as char);    
                stdout().flush();
        }

        return 1;
    }

}

