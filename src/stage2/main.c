#include <stdint.h>
#include "io.h"
#include "stdio.h"

uint16_t* vgaBuffer = (uint16_t*)0xB8000;

void __attribute__((cdecl)) start(uint16_t bootDrive)
{
    clearScreen();

    puts("Hello, World!\n");
end:
    for (;;);
}
