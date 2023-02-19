[org 0x1000]

dw 0x55aa ; 魔数，用于判断内核加载器是否有效

xchg bx, bx

mov si, Loading
call print

jmp $

print:
    mov ah, 0x0e
.next:
    mov al, [si]
    cmp al, 0
    jz .done
    int 0x10
    inc si
    jmp .next
.done:
    ret

Loading:
    db "Loading ChenyOS...", 10, 13, 0 ; \n\t