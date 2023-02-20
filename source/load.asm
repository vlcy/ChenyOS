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

; ARDS 地址范围描述符结构
ards_count:
    dw 0
ards_buffer:
