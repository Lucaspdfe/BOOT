ENTRY(entry)

SECTIONS {
    . = 0x500;

    .entry : {
        *(.entry)
    }

    .text : {
        *(.text)
    }

    .data : {
        *(.data)
    }

    .rodata : {
        *(.rodata)
    }

    _bss_start = .;
    .bss : {
        *(.bss)
    }
    _bss_end = .;

    _stack_start = .;
    .stack : {
        *(.stack)
        /* Reserve 4KB for the stack */
        . = . + 0x1000;
    }
    _stack_end = .;
}