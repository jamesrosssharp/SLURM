	.section text

global_interrupt_enable:
	sti
	ret

global_interrupt_disable:
	cli
	ret

	.global global_interrupt_enable
	.global global_interrupt_disable
	.end
