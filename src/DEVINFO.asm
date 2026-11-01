; DEVINFO.BIN - external x16-PRos system diagnostics.

[BITS 16]
[ORG 0x8000]

%include "pros_api.inc"

TASK_S_FREE equ 0
TASK_COUNT  equ 4
TASK_NAME_LEN equ 16

start:
    pushf
    pusha
    push ds
    push es
    cld
    PROS_SYS PROS_SYS_MOUSE_STATE
    mov [mouse_visible], ch
    PROS_SYS PROS_SYS_MOUSE_HIDE

refresh:
    PROS_OUT PROS_OUT_CLEAR_THEME

    mov si, title
    PROS_PRINT_GREEN
    PROS_NEWLINE

    mov si, api_label
    PROS_PRINT
    PROS_SYS PROS_SYS_VERSION
    call print_hex4
    PROS_NEWLINE

    mov si, current_drive_label
    PROS_PRINT
    PROS_FS PROS_FS_DRIVE
    call print_drive
    PROS_NEWLINE

    mov si, system_drive_label
    PROS_PRINT
    PROS_FS PROS_FS_SYSTEM_DRIVE
    call print_drive
    PROS_NEWLINE

    mov si, free_memory_label
    PROS_PRINT
    PROS_SYS PROS_SYS_FREE_BYTES
    call print_u32
    mov si, bytes_label
    PROS_PRINT
    PROS_NEWLINE

    mov si, date_label
    PROS_PRINT
    PROS_OUT PROS_OUT_DATE
    call print_date
    PROS_NEWLINE

    mov si, time_label
    PROS_PRINT
    PROS_OUT PROS_OUT_TIME
    call print_time
    PROS_NEWLINE
    PROS_NEWLINE

    call print_hardware

    mov si, tasks_header
    PROS_PRINT
    PROS_NEWLINE

    xor bx, bx
.task_loop:
    mov [task_id], bl
    mov ah, PROS_SYS_TASK_INFO
    int PROS_INT_SYS
    jc .next_task

    mov [task_state], al
    mov [task_flags], ah
    mov [task_segment], cx
    mov [task_parent], dl

    mov bl, [task_id]
    mov di, task_name
    mov ah, PROS_SYS_TASK_NAME
    int PROS_INT_SYS
    jc .next_task

    mov al, [task_id]
    add al, '0'
    call print_char
    mov al, ' '
    call print_char

    mov si, task_name
    call print_name
    mov al, ' '
    call print_char

    mov al, [task_state]
    call print_state
    mov al, ' '
    call print_char

    mov ax, [task_segment]
    call print_hex4
    mov al, ':'
    call print_char
    xor ax, ax
    call print_hex4
    mov si, parent_label
    PROS_PRINT
    mov al, [task_parent]
    cmp al, 0xFF
    je .no_parent
    xor ah, ah
    xor dx, dx
    call print_u32
    jmp .mode
.no_parent:
    mov al, '-'
    call print_char
.mode:
    mov si, mode_foreground
    test byte [task_flags], 0x01
    jz .not_background
    mov si, mode_background
.not_background:
    test byte [task_flags], 0x80
    jz .print_mode
    mov si, mode_kernel
.print_mode:
    cmp byte [task_state], TASK_S_FREE
    jne .write_mode
    mov si, empty_mode
.write_mode:
    PROS_PRINT
    PROS_NEWLINE

.next_task:
    xor ax, ax
    mov al, [task_id]
    inc al
    cmp al, TASK_COUNT
    jae .done
    mov bl, al
    jmp .task_loop

.done:
    PROS_NEWLINE
    mov si, footer
    PROS_PRINT_CYAN
    PROS_NEWLINE
wait_key:
    PROS_SYS PROS_SYS_GETKEY
    cmp al, 27
    je exit
    cmp al, 'r'
    je refresh
    cmp al, 'R'
    je refresh
    cmp al, 'd'
    je drives_page
    cmp al, 'D'
    je drives_page
    jmp wait_key

drives_page:
    PROS_OUT PROS_OUT_CLEAR_THEME
    mov si, drives_title
    PROS_PRINT_GREEN
    PROS_NEWLINE
    PROS_FS PROS_FS_LIST_DRIVES
    PROS_NEWLINE
    mov si, drives_footer
    PROS_PRINT_CYAN
    PROS_SYS PROS_SYS_GETKEY
    cmp al, 27
    je exit
    jmp refresh

exit:
    cmp byte [mouse_visible], 0
    je .restore
    PROS_SYS PROS_SYS_MOUSE_SHOW
.restore:
    pop es
    pop ds
    popa
    popf
    ret

; Print AL as a drive letter.
print_drive:
    call print_char
    ret

; Print CH:CL:DH as HH:MM:SS.
print_time:
    mov al, ch
    call print_2digit
    mov al, ':'
    call print_char
    mov al, cl
    call print_2digit
    mov al, ':'
    call print_char
    mov al, dh
    call print_2digit
    ret

; Print CH:CL/DH/DL as YYYY-MM-DD.
print_date:
    mov al, ch
    call print_2digit
    mov al, cl
    call print_2digit
    mov al, '-'
    call print_char
    mov al, dh
    call print_2digit
    mov al, '-'
    call print_char
    mov al, dl
    call print_2digit
    ret

print_state:
    cmp al, TASK_S_FREE
    je .free
    cmp al, 1
    je .ready
    cmp al, 2
    je .running
    cmp al, 3
    je .sleeping
    mov si, state_unknown
    jmp .write
.ready:
    mov si, state_ready
    jmp .write
.running:
    mov si, state_running
    jmp .write
.sleeping:
    mov si, state_sleeping
    jmp .write
.free:
    mov si, state_free
.write:
    PROS_PRINT
    ret

; Pad the API's bounded task name to a fixed 16-column field.
print_name:
    pusha
    mov cx, TASK_NAME_LEN
.character:
    lodsb
    test al, al
    jz .padding
    call print_char
    loop .character
    jmp .done
.padding:
    mov al, ' '
.space:
    call print_char
    loop .space
.done:
    popa
    ret

print_hardware:
    mov si, conventional_label
    PROS_PRINT
    int 0x12
    xor dx, dx
    call print_u32
    mov si, kib_label
    PROS_PRINT
    PROS_NEWLINE

    mov si, video_label
    PROS_PRINT
    mov ah, 0x0F
    int 0x10
    mov [video_columns], ah
    mov [video_page], bh
    xor ah, ah
    call print_hex4
    mov si, columns_label
    PROS_PRINT
    xor ax, ax
    mov al, [video_columns]
    xor dx, dx
    call print_u32
    mov si, page_label
    PROS_PRINT
    xor ax, ax
    mov al, [video_page]
    call print_u32
    PROS_NEWLINE

    mov si, equipment_label
    PROS_PRINT
    int 0x11
    call print_hex4
    PROS_NEWLINE

    mov si, ticks_label
    PROS_PRINT
    xor ah, ah
    int 0x1A
    mov ax, dx
    mov dx, cx
    call print_u32
    PROS_NEWLINE
    PROS_NEWLINE
    ret

; Print unsigned DX:AX in decimal.
print_u32:
    pusha
    mov [number_hi], dx
    mov [number_lo], ax
    cmp dx, 0
    jne .digits
    cmp ax, 0
    jne .digits
    mov al, '0'
    call print_char
    jmp .done
.digits:
    xor cx, cx
.divide:
    mov ax, [number_hi]
    xor dx, dx
    mov bx, 10
    div bx
    mov [number_hi], ax
    mov ax, [number_lo]
    div bx
    mov [number_lo], ax
    push dx
    inc cx
    cmp word [number_hi], 0
    jne .divide
    cmp word [number_lo], 0
    jne .divide
.emit:
    pop ax
    add al, '0'
    call print_char
    loop .emit
.done:
    popa
    ret

print_2digit:
    pusha
    xor ah, ah
    mov dl, 10
    div dl
    mov dh, ah
    add al, '0'
    call print_char
    mov al, dh
    add al, '0'
    call print_char
    popa
    ret

print_hex4:
    pusha
    mov cx, 4
.hex_loop:
    rol ax, 4
    mov dl, al
    and dl, 0x0F
    cmp dl, 10
    jb .hex_digit
    add dl, 7
.hex_digit:
    add dl, '0'
    push ax
    mov al, dl
    call print_char
    pop ax
    loop .hex_loop
    popa
    ret

print_char:
    pusha
    mov ah, 0x0E
    xor bh, bh
    mov bl, 0x0F
    int 0x10
    popa
    ret

title              db 'DEVINFO 0.2 - x16-PRos diagnostics', 0
api_label          db 'API version: 0x', 0
current_drive_label db 'Current drive: ', 0
system_drive_label db 'System drive: ', 0
free_memory_label  db 'Free heap: ', 0
bytes_label        db ' bytes', 0
date_label         db 'Date: ', 0
time_label         db 'Time: ', 0
tasks_header       db 'ID NAME             STATE    ARENA      PARENT MODE', 0
footer             db '[R] Refresh   [D] Disks   [Esc] Exit', 0
parent_label       db '  ', 0
mode_foreground    db '  FG', 0
mode_background    db '  BG', 0
mode_kernel        db '  KERNEL', 0
empty_mode         db '', 0
drives_title       db 'DEVINFO - available disks', 0
drives_footer      db 'Any key: overview   Esc: exit', 0
conventional_label db 'BIOS conventional memory: ', 0
kib_label          db ' KiB (not free heap)', 0
video_label        db 'Video mode: 0x', 0
columns_label      db '  Columns: ', 0
page_label         db '  Page: ', 0
equipment_label    db 'BIOS equipment flags: 0x', 0
ticks_label        db 'BIOS ticks since midnight: ', 0

state_ready        db 'READY   ', 0
state_running      db 'RUNNING ', 0
state_sleeping     db 'SLEEPING', 0
state_unknown      db 'UNKNOWN ', 0
state_free         db 'FREE    ', 0

task_id            db 0
task_state         db 0
task_flags         db 0
task_parent        db 0
task_segment       dw 0
task_name          times TASK_NAME_LEN + 1 db 0
number_hi          dw 0
number_lo          dw 0
mouse_visible      db 0
video_columns      db 0
video_page         db 0
