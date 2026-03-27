#pragma once
#include <stdint.h>

#define _cdecl __attribute__((cdecl))

// WARNING: Functions declared here are implemented in assembly
void _cdecl outb(uint16_t port, uint8_t value);
uint8_t _cdecl inb(uint16_t port);
void _cdecl outw(uint16_t port, uint16_t value);
uint16_t _cdecl inw(uint16_t port);
void _cdecl outl(uint16_t port, uint32_t value);
uint32_t _cdecl inl(uint16_t port);
