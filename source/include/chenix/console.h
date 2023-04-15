#ifndef CHENIX_CONSOLE_H
#define CHENIX_CONSOLE_H

#include <chenix/types.h>

void console_init();
void console_clear();
void console_write(char *buf, u32 count);

#endif
