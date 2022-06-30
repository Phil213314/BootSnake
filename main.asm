[org 0x7c00]
[bits 16]
xor ecx, ecx

mov ds, cx
mov ss, cx
mov esp, 0x7c00

mov al, 0xFF
out 0x60, al

in al, 0x61
and al, 0xFC
out 0x61, al

mov ax, 0x13
int 0x10

;mov al, 0x36
;out 0x43, al
;mov ax, (1193180 / 20)
;out 0x40, al
;shr ax, 8
;out 0x40, al

xor ax, ax
xor bl, bl
int 0x1A
mov WORD [seed], dx

mov WORD es:[0x20], tick
mov WORD es:[0x22], cs
mov WORD es:[0x24], keyboard
mov WORD es:[0x26], cs

mov ax, 0xA000
mov es, ax

;mov bx, 100
;mov dx, bx
;
;mov al, applecol
;call pixel

call reset

loop:
    hlt
    jmp loop

reset:
    mov al, bgcol
    call fillscr

    mov bx, 10
    mov dx, bx
    mov BYTE [direction], 0
    mov WORD [snakelen], 4

    call apple

    ret

update:
    pusha

    mov cx, WORD [snakelen]

    call getpixel
    cmp al, applecol
    jne .notapple

    add cx, 3
    mov WORD [snakelen], cx

    call apple

    jmp .notsnake

.notapple:
    cmp al, bgcol
    je .notsnake

    popa
    jmp reset

.notsnake:
    ;mov al, bgcol
    ;call fillscr

    mov bx, cx
    shl bx, 2
    mov dx, WORD [bx + snakebuf]
    mov bx, WORD [bx + snakebuf + 2]

    mov al, bgcol
    call pixel
.loop:
    mov bx, cx
    dec bx
    shl bx, 2

    mov dx, WORD [bx + snakebuf]
    mov bx, WORD [bx + snakebuf + 2]

    mov al, snakecol
    call pixel

    loop .loop

    popa
    ret

eoi:
    mov al, 0x20
    out 0x20, al

    iret

tick:
    mov al, BYTE [direction]

    cmp al, up
    je .up

    cmp al, left
    je .left

    cmp al, down
    je .down

    cmp al, right
    je .right

    jmp eoi

.up:
    dec bx
    jmp .continue
.down:
    inc bx
    jmp .continue
.left:
    dec dx
    jmp .continue
.right:
    inc dx
    jmp .continue

.continue:
    cmp bx, 0
    jle .out
    cmp dx, 0
    jle .out

    cmp dx, width
    jge .out
    cmp bx, height
    jge .out

    pusha
    mov cx, WORD [snakelen]
.shift:
    mov bx, cx
    dec bx
    shl bx, 2

    mov dx, WORD [bx + snakebuf]
    mov WORD [bx + snakebuf + 4], dx

    mov dx, WORD [bx + snakebuf + 2]
    mov WORD [bx + snakebuf + 6], dx
    
    loop .shift
    popa

    mov WORD [snakebuf], dx
    mov WORD [snakebuf + 2], bx

    call update
    jmp eoi
.out:
    call reset
    jmp eoi

keyboard:
    in al, 0x60

    cmp al, up
    je .c

    cmp al, down
    je .c

    cmp al, left
    je .c

    cmp al, right
    je .c

    jmp eoi
.c:

    mov BYTE [direction], al
    jmp eoi

fillscr:
    xor di, di
    mov cx, width * height
    rep stosb
    ret

; al - col ; bx = y; dx = x ;
pixel:
    mov di, width
    imul di, bx
    add di, dx
    mov es:[di], al
    ret

; al - col (output) ; bx = y; dx = x ;
getpixel:
    mov di, width
    imul di, bx
    add di, dx
    mov al, es:[di]
    ret

apple:
    pusha

    ; TODO: generate random numbers in bx
    call random

    movzx dx, bh
    mov bh, 0

    mov al, applecol
    call pixel

    popa
    ret

random:
    push ax
    push dx

    mov dx, WORD [seed]

    mov ax, dx
    mov cx, 75
    mul cx
    movzx edx, dx
    mov ecx, 65537
    div ecx
    mov ax, dx
    shr edx, 16
    mov ecx, (height * width)
    div cx

    mov WORD [seed], dx

    mov bx, dx

    pop ax
    pop dx
    ret

times 510-($-$$) db 0
db 0x55, 0xAA

; defines ;
width equ 320
height equ 200
up equ 0x11
down equ 0x1F
left equ 0x1E
right equ 0x20
applecol equ 00001100b
bgcol equ 0
snakecol equ 0xF

; variables ;
snakelen equ 0x2000 ; word
direction equ 0x2002 ; byte (word for alignment)
seed equ 0x2004 ; word
snakebuf equ 0x2006 ; (word, word)[]