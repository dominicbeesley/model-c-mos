
# `default_handlers` Segment — Mode-Switching Shims

## Introduction

On the C20K / Blitter the 65816 sees two memory maps: In **emulation mode** the C20K/Blitter hardware's SWMOS logic causes the mirrors the FF bank into bank 00. In **native mode** (16-bit) the banks are separate. 

Also, the native mode code in general requires quite large stacks - when switching from emulation to native mode the stack needs to be moved from $100-$200 to a new location with more room. This requires some shims that copy the stack from on area to another _and_ that appear to be located at the same area during a mode-switch. The area FB00-FC00 in emulation mode (which is mapped to FF FB00 - in the kernel of the ROM) is copied to 00 FB00-FC00 at boot time and all the mode-switch shims execute from this mirrored page. 

At boot the MOS copies the segment from ROM to bank-0 RAM (`kernel.asm:459-462`):

```asm
ldx  #.loword(__default_handlers_LOAD__)   ; FF FB00
ldy  #.loword(__default_handlers_RUN__)    ; 00 FB00
lda  #.loword(__default_handlers_SIZE__)   ; $E0
mvn  #^__default_handlers_LOAD__, #^__default_handlers_RUN__
```

After boot mode is switched off, code in both worlds sees the same RAM copy:
- Emulation mode: `FB00` (logical, page 1 stack + SHEILA visible above)
- Native mode: `00 FB00` (physical bank 0)

The linker (`boot.cfg:23/57`) defines two memory regions for this:

| Region | Address | Purpose |
|--------|---------|---------|
| `BMOS_DEFHWND` | `$FF FB00` | ROM load location |
| `RAM_BMOS_DEFHWND` | `$00 FB00` | RAM run location, size `$E0` |

See `memorymap.md` line 59-60 (the `>>>>` arrow).

---

## Memory layout around `FB00`

From `nat-layout.inc` and `memorymap.md`:

| Address | Symbol | Contents |
|---------|--------|----------|
| `00 F700` | `STACKNAT` | Native mode OS stack (grows up toward FB00) |
| `00 FB00` | `HANDLER_TRAMPOLINES` / `STACKNAT_TOP` | This segment (224 bytes, copied from ROM at boot) |
| `00 FC00` | `DEICEBSS` | DeICE stack/workspace |
| `00 FD00` | `NAT_OS_VECS` | Native OS vector table |
| `00 FE10` | `B0_IRQ_STACK` | IRQ handler private stack pointer |
| `00 FE12` | `B0_EMU_STACK` | Scratch: saved emulation stack pointer (during transitions) |
| `00 FE14` | `B0_NAT_STACK` | Scratch: saved native stack pointer (during transitions) |

`B0_EMU_STACK` and `B0_NAT_STACK` are only valid between the `sei` and `rti` of the transition shims. Not for general use.

---

## The shims

### `emu2nat_rti` — emulation mode → native mode

Switches the CPU to native mode and RTIs to a 24-bit continuation address, carrying a portion of the emulation stack across.

**Caller constructs on the emulation stack before jumping:**

```
[S+6]  bank byte of continuation addr
[S+5]  hi byte of continuation addr
[S+4]  lo byte of continuation addr
[S+3]  P — flags for destination
[S+2]  0 — reserved
[S+1]  # — number of extra bytes to copy (beyond the N_STACKED = 10 frame)
```

Constructed with three `pea` instructions, then `jmp emu2nat_rti` (or `jml` from outside the segment).

**Shim steps:**

1. `sei` — interrupts off for the duration.
2. `clc / xce` — switch to native mode.
3. `rep #$21` (16-bit A/X/Y, clear carry), push A, X, Y. Record `tsc → B0_EMU_STACK`.
4. Read `#extra` from `[S+5]`, add `N_STACKED (10)` = total bytes to move.
5. Subtract total from `B0_NAT_STACK`; transfer SP there (`tcs`) — make room on native stack.
6. `mvp #0,#0` — block-copy the entire frame (including original IRQ/COP stacked state) from emulation stack to native stack.
7. `sep #$10` (8-bit index), pop Y/X/A, pop two B bytes, `rti` — lands at the 24-bit continuation in native mode.

---

### `nat2emu_rti` — native mode → emulation mode

Inverse of `emu2nat_rti`. Copies a frame from the native stack back to the emulation stack and RTIs into emulation mode.

**Caller constructs on the native stack before jumping:**

```
[S+4]  hi byte of continuation addr (bank 0 implied)
[S+3]  lo byte of continuation addr
[S+2]  P — flags for destination
[S+1]  # — extra bytes to copy back
```

Constructed with two `pea` instructions, then `jmp nat2emu_rti`.

**Shim steps:**

1. `sei`, `rep #$31` (16-bit, clear carry), `sep #$10` (8-bit index). Push Y, X, A (N_STACKED = 8 bytes total including RTI frame).
2. Force `DP=0, B=0` — `pea 0 / pld / phd / plb / plb`. **Mandatory** before entering emulation mode, which assumes both are zero.
3. `tsc → B0_NAT_STACK`; compute emulation stack destination (`B0_EMU_STACK - count`); set SP there (`tcs`).
4. `mvp #0,#0` — copy frame to emulation stack.
5. Patch the `#extra` slot on stack to 0 (`inc A / sta 5,S`); restore Y/X/A (via `pla/xba` pairs because A is 16-bit but being stored 8-bit), pop B.
6. `sec / xce` — switch to emulation mode, `rti` at the 16-bit continuation.

---

### `emu_handle_irq` — IRQ arriving in emulation mode

Most complex entry. Hardware has already pushed `PCH, PCL, P` (the interrupted return address and flags) onto the emulation stack.

```
[S+3]  PC hi of interrupted code
[S+2]  PC lo of interrupted code
[S+1]  P  of interrupted code
```

Flow:

1. `sta dp_mos_INT_A` — stash A (no stack push, keeps the original frame intact).
2. `lda 1,S / and #$10` — test B flag in stacked P. If set it is a BRK, not IRQ: `jmp emu_handle_brk`.
3. Push frame for `emu2nat_rti` targeting label `@c` (bank 0, `#extra = 0`, `P = $04`), then `jmp emu2nat_rti`.
4. CPU switches to native mode. The original interrupted PC/P are carried across to the native stack.
5. At `@c` (native mode): push a fake RTI frame targeting `@ret`, then `jml default_IVIRQ`.
6. `default_IVIRQ` runs the native IRQ dispatcher and exits via RTI, landing at `@ret`.
7. At `@ret` (native mode): push frame for `nat2emu_rti` targeting `@c2`, then `jmp nat2emu_rti`.
8. CPU switches back to emulation mode.
9. At `@c2`: `lda dp_mos_INT_A` restores A, `rti` — returns to the original interrupted emulation code.

---

### `emu_handle_cop` — COP in emulation mode

Short front-end that falls straight through into `emu2nat_rti`.

```asm
emu_handle_cop: php                    ; save caller's flags (+1 extra byte)
                pea cop_handle_emu>>8
                pea $04+((>cop_handle_emu)<<8)
                pea 1                  ; #extra = 1 (the flags byte)
                ; fall through to emu2nat_rti
```

Switches to native mode and RTIs into `cop_handle_emu` (`cop.asm`). That handler exits via `jml nat2emu_rti` (`cop.asm:117`) to return to the calling 8-bit program.

---

### Abort handlers

- **`emu_handle_abort`** — `pha / lda #DEICE_STATE_ABORT / clc / xce / jml deice_enter_emu`. Bare mode switch; no stack transfer. DeICE takes full control.
- **`nat_handle_abort`** — `rep #$30 / pha / lda #DEICE_STATE_ABORT / jml deice_enter_nat` (via `enter_deice`). Same intent in native mode.
- **`deice_nat2emu_rti`** — three instructions: `sec / xce / rti`. Used by DeICE (`deice.asm:203`) to return from a debugging session to the original emulation-mode code.

---

### Native stubs

Short `jml` trampolines so the hardware vector table can reach the real handlers:

| Label | Target |
|-------|--------|
| `nat_handle_cop` | `jml cop_handle_nat` (`cop.asm`) |
| `nat_handle_brk` | `jml brk_handle_nat` (`brk.asm`) |
| `nat_handle_nmi` | `rti` (ignored) |
| `nat_handle_irq` | `jml default_IVIRQ` (`irqs.asm`) |

These must live in this segment because the hardware vector table is also near `$FF FF00` and `$00 FFE0`, and a `jml` to the copied RAM is shorter/safer than reaching deep into ROM.

---

## Callers outside `default_handlers`

| File | Line | Direction | Why |
|------|------|-----------|-----|
| `cop.asm` | 117 | nat → emu | COP call returns to 8-bit caller |
| `brk.asm` | 154 | nat → emu | BRK handler returns to emulation |
| `osbyte_word.asm` | 750 | nat → emu | OSBYTE/OSWORD returns to emu caller |
| `roms.asm` | 171 | nat → emu | Return from ROM service call |
| `roms.asm` | 199 | emu → nat | Enter native to service a ROM call |
| `vectors.asm` | 41 | emu → nat | BBC vector entry: cross to native handler |
| `vectors.asm` | 114 | nat → emu | BBC vector exit: return result to emu |
| `vectors.asm` | 284 | nat → emu | Exit native vector back to emulation |
| `vectors.asm` | 308 | emu → nat | Enter native for vector dispatch |
| `deice.asm` | 203 | nat → emu | DeICE exit via `deice_nat2emu_rti` |

---

## Stack-pointer variables across nested mode switches

`B0_EMU_STACK` (`$00FE12`) and `B0_NAT_STACK` (`$00FE14`) are initialized at boot (`kernel.asm:376-379`) to `STACKBBC_TOP` and `STACKNAT_TOP` and remain live for the entire duration of any active call chain — not just within a single shim.

Each shim updates the variable for the mode being *left* and reads the variable for the mode being *entered*:

| Shim | Writes | Reads |
|------|--------|-------|
| `emu2nat_rti` | `B0_EMU_STACK` := current emu SP | `B0_NAT_STACK` to place native frame |
| `nat2emu_rti` | `B0_NAT_STACK` := current nat SP | `B0_EMU_STACK` to place emulation frame |

After any switch completes, the updated variable reflects the live top of that mode's stack, ready to be used by the next switch in the same direction.

**These variables are not stacked.** Each switch overwrites unconditionally. Only the most recent switch in each direction is recorded. Nested call chains work correctly because the stack frames themselves are copied between the two stack regions by `mvp`; the variables just track where each boundary currently sits.

Example — emulation caller dispatches through a vector, which makes a COP call that re-enters an emulation-mode filing system:

```
emu caller
  -> vector dispatch  (emu2nat_rti)        B0_EMU_STACK := emu SP here
      -> native vector / COP handler
          -> call emu FS  (nat2emu_rti)    B0_NAT_STACK := nat SP here
              -> emu FS executes
              <- emu FS returns (emu2nat_rti)  B0_EMU_STACK := emu SP here (updated)
          <- COP handler continues (nat)
      <- return to emu caller (nat2emu_rti)    B0_NAT_STACK := nat SP here (updated)
  <- emu caller resumes
```

At each leg the shim reads the "destination" variable to locate the target stack, moves the frame, then the CPU RTIs into the continuation. The variable is already correct for the next switch by the time any code runs in the new mode.

---

## Invariants

- DP and B must be 0 on entry to emulation mode. `nat2emu_rti` enforces this unconditionally before `xce`.
- `B0_EMU_STACK` / `B0_NAT_STACK` track the live boundary of each mode's stack for the duration of any active call chain. They are updated (not stacked) by every mode-switch shim and must not be written by any other code.
- Both `emu2nat_rti` and `nat2emu_rti` open with `sei`. NMIs can still arrive; NMI handlers must not disturb memory below the current SP.
- Emulation stack is page `$01` (`STACKBBC`, 8-bit S). Native stack is `$00 F700`–`$00 FAFF` (`STACKNAT`, 16-bit S). The `mvp` moves data between these two physically separate regions.
