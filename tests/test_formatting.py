"""Run the actual formatting routines in a tiny real-mode QEMU guest."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / "src/DEVINFO.asm").read_text()
routines = source.split("print_u32:\n", 1)[1].split("title ", 1)[0]
boot = """
bits 16
org 0x7c00
xor ax, ax
mov ds, ax
mov es, ax
cli
mov ss, ax
mov sp, 0x7c00
sti
mov word [0x40], output
mov word [0x42], 0
mov ax, 0x0001
call print_hex4
mov al, ' '
call print_char
mov ax, 0xabcd
call print_hex4
mov al, ' '
call print_char
mov cx, 0x140b
mov dx, 0x0101
mov al, ch
call print_2digit
mov al, cl
call print_2digit
mov al, dh
call print_2digit
mov al, dl
call print_2digit
mov al, ' '
call print_char
mov dx, 0x0006
mov ax, 0xfc00
call print_u32
mov al, ' '
call print_char
xor dx, dx
xor ax, ax
call print_u32
mov al, ' '
call print_char
mov dx, 0xffff
mov ax, 0xffff
call print_u32
mov dx, 0xf4
mov ax, 0x10
out dx, ax
hlt
output:
out 0xe9, al
iret
print_u32:
""" + routines + """
number_hi dw 0
number_lo dw 0
times 510-($-$$) db 0
dw 0xaa55
"""

with tempfile.TemporaryDirectory(prefix="devinfo-", dir="/tmp/opencode") as tmp:
    tmp = Path(tmp)
    (tmp / "boot.asm").write_text(boot)
    subprocess.run(["nasm", "-f", "bin", str(tmp / "boot.asm"),
                    "-o", str(tmp / "boot.img")], check=True)
    result = subprocess.run([
        "qemu-system-i386", "-display", "none", "-serial", "none",
        "-monitor", "none", "-debugcon", "stdio",
        "-device", "isa-debug-exit,iobase=0xf4,iosize=0x04",
        "-drive", f"format=raw,file={tmp / 'boot.img'},if=floppy",
        "-boot", "a", "-no-reboot",
    ], capture_output=True, timeout=20)
    expected = b"0001 ABCD 20110101 457728 0 4294967295"
    assert result.returncode == 33, (result.returncode, result.stderr)
    assert result.stdout == expected, (result.stdout, expected)
    print("PASS: hex, preserved date registers, and unsigned 32-bit decimal")
