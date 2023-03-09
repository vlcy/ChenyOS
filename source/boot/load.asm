[org 0x1000]

dw 0x55aa ; 魔数，用于判断内核加载器是否有效

mov si, loading
call print

xchg bx, bx

detect_memory:
    xor ebx, ebx

    ; es:di 结构体的缓存位置
    mov ax, 0
    mov es, ax
    mov edi, ards_buffer

    mov edx, 0x534d4150 ; 固定签名

.next:
    ; 子功能号
    mov eax, 0xe820
    ; ards结构体大小
    mov ecx, 20
    ; 调用系统调用
    int 0x15

    ; CF置位，调用出错
    jc error
    
    ; 将缓存指针指向下一个结构体
    add di, cx

    ; 将结构体数量加1
    inc word [ards_count]

    ; 最后一个结构体
    cmp ebx, 0
    jnz .next

    mov si, detecting
    call print

    jmp prepare_protected_mode

prepare_protected_mode:
    xchg bx, bx

    cli ; 关闭中断

    ; 打开A20线
    in al, 0x92
    or al, 0b10
    out 0x92, al

    lgdt [gdt_ptr] ; 加载gdt

    ; 启动保护模式
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; 用跳转刷新缓存，启用保护模式，cs:ip禁止使用mov刷新
    jmp dword code_selector:protect_mode

;     xchg bx, bx

;     ; 结构体数量
;     mov cx, [ards_count]
;     ; 结构体指针
;     mov si, 0
; .show:
;     mov eax, [ards_buffer + si]
;     mov ebx, [ards_buffer + si + 8]
;     mov edx, [ards_buffer + si + 16]
;     add si, 20
;     xchg bx, bx
;     loop .show

; jmp $

; 保护模式无法继续使用实模式下的print
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

loading:
    db "Loading ChenyOS...", 10, 13, 0 ; \n\t

detecting:
    db "Detecting Memory Success...", 10, 13, 0

error:
    mov si, .msg
    call print
    hlt ; 让CPU停止运行
    jmp $
    .msg db "Loading Error!!!", 10, 13, 0

[bits 32]
protect_mode:
    xchg bx, bx
    mov ax, data_selector
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov esp, 0x10000 ; 修改栈顶

    ; mov byte [0xb8000], 'P'
    ; mov byte [0x200000], 'P'

    mov edi, 0x10000 ; 读取到的目标内存地址
    mov ecx, 10 ; 起始扇区
    mov bl, 200 ; 读取扇区数量

    call read_disk

    jmp dword code_selector:0x10000

    ud2 ; 表示出错

jmp $

read_disk:
    ; 设置读写扇区的数量
    mov dx, 0x1f2
    mov al, bl
    out dx, al

    inc dx ; 0x1f3
    mov al, cl ; 起始扇区的低八位
    out dx, al

    inc dx ; 0x1f4
    shr ecx, 8
    mov al, cl ; 起始扇区的中八位
    out dx, al

    inc dx ; 0x1f5
    shr ecx, 8
    mov al, cl ; 起始扇区的高八位
    out dx, al

    inc dx ; 0x1f6
    shr ecx, 8 ; ECX 32bit
    and cl, 0b1111 ; 清空高四位

    mov al, 0b1110_0000
    or al, cl
    out dx, al ; 主盘 LBA模式

    inc dx ; 0x1f7
    mov ax, 0x20 ; 读硬盘
    out dx, al

    xor ecx, ecx ; 清空ECX
    mov cl, bl ; 得到读写扇区的数量

    .read:
        push cx
        call .waits ; 等待数据准备完毕
        call .reads ; 读写一个扇区
        pop cx
        loop .read

    ret

    .waits:
        mov dx, 0x1f7
        .check:
            in al, dx
            jmp $+2 ; 直接跳转到下一行，原因是一条指令占用两个字节
            jmp $+2 ; 相比与nop，延迟更长一些
            jmp $+2
            and al, 0b1000_1000
            cmp al, 0b0000_1000
            jnz .check
        ret

    .reads:
        mov dx, 0x1f0
        mov cx, 256
        .readw:
            in ax, dx
            jmp $+2
            jmp $+2
            jmp $+2
            mov [edi], ax
            add edi, 2
            loop .readw
        ret
    

code_selector equ (1 << 3)
data_selector equ (2 << 3)

; 内存开始位置，基地址
memory_base equ 0
; 内存界限 4G / 4k - 1
memory_limit equ ((1024 * 1024 * 1024 * 4) / (1024 * 4)) - 1

gdt_ptr:
    dw (gdt_end - gdt_base) - 1
    dd gdt_base
gdt_base:
    dd 0, 0 ; NULL描述符
gdt_code:
    dw memory_limit & 0xffff ; 段界限0-15位
    dw memory_base & 0xffff ; 基地址0-15位
    db (memory_base) >> 16 & 0xff ; 基地址16-23位 
    ; 存在、DLP0、S、代码段、非依从、可读、没有访问过
    db 0b_1_00_1_1_0_1_0
    ; 4k、32位、不是64位、段界限16-19位
    db 0b_1_1_0_0_0000 | (memory_limit >> 16) & 0xf
    db (memory_base >> 24) & 0xff ; 基地址24-31位
gdt_data:
    dw memory_limit & 0xffff ; 段界限0-15位
    dw memory_base & 0xffff ; 基地址0-15位
    db (memory_base) >> 16 & 0xff ; 基地址16-23位 
    ; 存在、DLP0、S、数据段、向上、可写、没有访问过
    db 0b_1_00_1_0_0_1_0
    ; 4k、32位、不是64位、段界限16-19位
    db 0b_1_1_0_0_0000 | (memory_limit >> 16) & 0xf
    db (memory_base >> 24) & 0xff ; 基地址24-31位
gdt_end:

; ARDS 地址范围描述符结构
ards_count:
    dw 0
ards_buffer:
