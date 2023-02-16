[org 0x7c00]

; 设置屏幕为文本模式，清除屏幕
mov ax, 3
int 0x10

; 初始化段寄存器
mov ax, 0
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x7c00

; bochs 魔术断点
xchg bx, bx

mov si, booting
call print

; 阻塞
jmp $

print:
    mov ah, 0x0e
.next:
    mov al, [si]
    cmp al, 0
    ; zf = 1
    jz .done
    int 0x10
    inc si
    jmp .next
.done:
    ret

booting:
    db "Booting ChenyOS...", 10, 13, 0 ; \n\t

; 其余位置填充为 0
times 510 - ($ - $$) db 0

; 主引导扇区的最后两个字节必须为 0x55 0xaa
db 0x55, 0xaa

; 编译命令 nasm -f bin boot.asm -o boot.bin