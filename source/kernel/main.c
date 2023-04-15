#include <chenix/chenix.h>
#include <chenix/types.h>
#include <chenix/io.h>
#include <chenix/console.h>

char message[] = "Hello chenix!\n";

void kernel_init()
{
    console_init();

    while (true)
    {
        console_write(message, sizeof(message) - 1);
    }
    return;
}