# DEVINFO.BIN

System diagnostics utility for
**[x16-PRos](https://github.com/PRoX2011/x16-PRos)** by PRoX2011.

## Features

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

## Tests

```sh
python3 tests/test_formatting.py
```

Requires QEMU (`qemu-system-i386`). Runs the actual assembly formatting
routines in a small real-mode guest, covering hexadecimal values, date
register preservation and unsigned 32-bit decimal boundaries.
