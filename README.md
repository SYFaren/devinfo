# DEVINFO.BIN

Small external diagnostic utility for x16-PRos.

Version 0.2 shows:

- native API version;
- current and system drive;
- free heap memory;
- system date and time;
- all four scheduler slots, names, states, parents, arena addresses and modes;
- BIOS conventional memory, video mode, columns and page;
- BIOS equipment flags and ticks since midnight;
- a separate available-disks page using the native filesystem API.

Controls: `R` refreshes the overview, `D` opens the disk list, `Esc` exits.
The overview is a snapshot, not a continuously refreshing monitor. Waiting
for input yields to background tasks. The program hides the mouse cursor
before clearing the screen and restores its original visibility on exit.
Memory figures are explicitly distinguished: BIOS conventional memory is
not the same as free heap memory. BIOS ticks are not system uptime.

This project is intentionally outside the `x16-PRos/` reference checkout.

## Build

Requirements: NASM, Bash, and the external SDK at `../sdk/include/`.
This repository does not bundle the SDK or operating system.

```sh
./build.sh
```

The result is written to `build/DEVINFO.BIN`. The source can also be assembled
with the SDK include directory directly:

```sh
nasm -f bin -I ../sdk/include/ src/DEVINFO.asm -o build/DEVINFO.BIN
```

Install the resulting file into `BIN.DIR` on an x16-PRos disk image and run:

```text
DEVINFO
```

## Scope

This is an application project, not a modification of the operating system.
The API contract is documented in `../x16-PRos/docs/API.md`.

## Tests

```sh
python3 tests/test_formatting.py
```

Requires QEMU (`qemu-system-i386`). Runs the actual assembly formatting
routines in a small real-mode guest, covering hexadecimal values, date
register preservation and unsigned 32-bit decimal boundaries.
