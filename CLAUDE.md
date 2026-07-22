# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

model-c-mos is a proof-of-concept operating system for the "Model C Micro" / "C20K" 65816-based
machines. It presents a new native 65816 API (via the `COP` instruction for system calls) while
allowing existing 8-bit BBC Micro / Master programs, ROMs and filing systems to coexist and run in a
pseudo-virtual environment. The whole codebase is **65816 assembly** built with the cc65 toolchain.

Read `README.md` for the design rationale, `doc/internals/memorymap.md` for the emulation/native address map,
and `doc/internals/modules.md` for the module binary format spec.

## Build

The build uses recursive Makefiles rooted at `src/`. Run make from `src/` (or any subdir with a
Makefile). Common targets: `all`, `clean`, `ssd`, `deploy`.

```sh
cd src && make            # build boot.mos + all modules
cd src && make ssd        # build and assemble the model-c-mos.ssd disk image
cd src && make clean
cd src/mos && make        # build just the core MOS + modules
cd src/mos/modules/keyboard && make   # build a single module
```

Build artifacts go to `build/` (gitignored), mirroring the source tree under `BUILD_TOP`
(default `src/../build`). SSDs are written to `build/ssds/`. `make deploy` extracts the SSD to
`~/hostfs` (override with `DEPLOY_TOP`).

There is no test suite; validation is done by building and running the resulting `.ssd`/`.mos`
image in an emulator or on hardware.

### Toolchain dependencies

- **cc65**: `ca65` (assembler, invoked with `--cpu 65816`), `ld65` (linker), `ar65`.
- **`dfs`**: an Acorn DFS disk-image tool used to form/title/add files to `.ssd` images.
- **Perl scripts** in `scripts/` post-process linker output — `ca65lstupdate.pl`,
  `getsymbols.pl`, `ld65debugsymbols.pl` (debug symbols / `.noi` files for DeICE),
  `makemod.pl` (wraps a linked `.bin` into a `.mod` with header + checksum).
- `unix2mac` for line-ending conversion of the boot script.

## Architecture

### Core MOS (`src/mos/`)

`boot.mos` is the linked core OS. Its object list is defined by `OBJS_boot.mos` in
`src/mos/Makefile` and linked per `boot.cfg`. Each `.asm` compilation unit has a matching
`_i.inc` internal-interface include (e.g. `cop.asm` ↔ `cop_i.inc`) exposing that module's public
symbols to the rest of the core. Shared/global includes live in `src/includes/*.inc`
(`cop.inc`, `oslib.inc`, `vectors.inc`, `modules.inc`, `hardware.inc`, `sysvars.inc`, etc.) and
are on the assembler include path (`-I $(TOP)/includes`).

Key subsystems (each `*.asm` in `src/mos/`):
- `kernel.asm` — core startup / dispatch.
- `cop.asm` — the native `COP` system-call dispatcher. `cop.inc` defines the DP frame layout
  (`DPCOP_*` offsets) used to pass registers across a COP call.
- `irqs.asm`, `brk.asm` — interrupt/exception handling that must work seamlessly across
  8-bit (emulation) and 16-bit (native) CPU modes and route through both 16-bit modules and
  8-bit ROMs. This is the trickiest part of the system (see README "Interrupts and Exceptions").
- `vectors.asm`, `bbc-ext-vectors.asm`, `bbc-nat-vectors.asm`, `boot-vecs.asm` — vector tables
  bridging 8-bit BBC MOS vectors and native handlers.
- `osbyte_word.asm`, `bbcmosapi.asm`, `gsread.asm`, `cli.asm`, `fscv.asm` — 8-bit BBC MOS API
  emulation (OSBYTE/OSWORD/OSCLI/FSCV) that passes calls up to 16-bit APIs.
- `roms.asm`, `modules.asm` — sideways-ROM handling and the 16-bit module manager.
- `buffers.asm`, `window.asm`, `b0blocks.asm`, `hardware.asm` — buffers, the `WINDOW`
  mechanism for mapping 8-bit accesses into the 16MB space, bank-0 handle blocks, hardware layer.
- `deice.asm`, `debug.asm` — DeICE remote debugger support.

### Emulation vs Native duality

The central design tension: 8-bit apps call the 8-bit API (which may be serviced by a 16-bit
module), and 16-bit apps use `COP` (which may be transformed into 8-bit vector calls into a
legacy ROM). Much of the code exists to translate calls and copy stack/register state when
switching between the CPU's emulation and native modes. When touching call-dispatch, vectors, or
interrupt paths, keep both directions in mind.

### Modules (`src/mos/modules/`)

Modules are relocatable binaries acting like sideways ROMs in the 24-bit address space (rather
than paged banks). Format is specified in `doc/modules.md`; the header struct is `modhdr` in
`src/includes/modules.inc` (four `BRL` entry points: service / start / init / finalise, plus
length, flags, title/help offsets, version BCD, command table, COP index range, trailing 16-bit
checksum). Modules may be bank-agnostic and/or fully relocatable within a bank.

Each module lives in its own subdir (`keyboard/`, `vdu/`, `testmodule/`) with a self-contained
Makefile that: assembles `modhead.asm` + sources, links with a fixed `--start-addr` (the
`LOAD_ADDR`), runs `makemod.pl` to produce the `.mod`, and emits a `load.txt` line. The parent
`modules/Makefile` concatenates all `load.txt` into `loadscript.txt`, which is appended to the
`_21BOOT.txt` boot script so modules are `*XMLOAD`ed at boot.

To add a module: copy an existing module dir (`testmodule` is the minimal template), give it a
unique `LOAD_ADDR` and `BEEBN` DFS name, and it will be picked up automatically by the parent
Makefile's directory scan.
