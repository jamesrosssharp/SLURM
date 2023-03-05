	
	.function global_interrupt_enable
	.global global_interrupt_enable
global_interrupt_enable:
	sti
	ret
	.endfunc

	.function global_interrupt_enable
	.global global_interrupt_enable
global_interrupt_disable:
	cli
	ret
	.endfunc

	.end
