
# `default_handlers` Segment — Mode-Switching Shims

## Introduction

On the C20K / Blitter the 65816 sees two memory maps: 

  * In **emulation mode** the C20K/Blitter hardware's SWMOS logic mirrors bank FF into the CPU's logical bank 00. When the CPU accesses FExx (with PBR=0 or PBR=FF) the hardware registers are accessed.
  * In **native mode** (16-bit) the banks are separate, hardware is accessed at FF FExx and 00 FExx is used to access system variables

Also, the native mode code in general requires quite large stacks - when switching from emulation to native mode the stack needs to be moved from $100-$200 to a new location with more room. This requires some shims that copy the stack from one area to another. That code must survive the mode switch so if running. The area FAE0-FBE0 in emulation mode (which is mapped to FF FAE0 - in the kernel of the ROM) is copied to 00 FAE0-FBDF at boot time and all the mode-switch shims execute from this mirrored partial page, this means code can continue to run during a mode switch despite being in bank FF or 00.

At boot the MOS copies the segment from ROM to bank-0 RAM (`kernel.asm:549-552`):

```asm
ldx  #.loword(__default_handlers_LOAD__)   ; FF FAE0
ldy  #.loword(__default_handlers_RUN__)    ; 00 FAE0
lda  #.loword(__default_handlers_SIZE__)   ; $100
mvn  #^__default_handlers_LOAD__, #^__default_handlers_RUN__
```

After boot mode is switched off, code in both worlds sees the same RAM copy:
- Emulation mode: `FAE0` (logical, page 1 stack + SHEILA visible above)
- Native mode: `00 FAE0` (physical bank 0) or `FF FAE0` (physical bank FF)

The linker (`boot.cfg:23/57`) defines two memory regions for this:

| Region             | Address    | Purpose                       |
|--------------------|------------|-------------------------------|
| `BMOS_DEFHWND`     | `$FF FAE0` | ROM load location             |
| `RAM_BMOS_DEFHWND` | `$00 FAE0` | RAM run location, size `$100` |

`default_handlers` grew from `$E0` (224) to `$100` (256) bytes to fit the new
`emu2nat_0_rti` / `nat2emu_0_rti` shortcut shims; `BMOS_NAT_CODE` shrank by the
same `$20` bytes to keep the ROM budget balanced (`boot.cfg`).

See `memorymap.md` line 59-60 (the `>>>>` arrow).

---

## Memory layout around `FAE0`

From `nat-layout.inc` and `memorymap.md`:

| Address   | Symbol                                 | Contents                                                                 |
|-----------|----------------------------------------|--------------------------------------------------------------------------|
| `00 F700` | `STACKNAT`                             | Native mode OS stack (grows up toward FAE0)                              |
| `00 FAE0` | `HANDLER_TRAMPOLINES` / `STACKNAT_TOP` | This segment (256 bytes, copied from ROM at boot)                        |
| `00 FC00` | `DEICEBSS`                             | DeICE stack/workspace                                                    |
| `00 FD00` | `NAT_OS_VECS`                          | Native OS vector table                                                   |
| `00 FE00` | `B0_BASE`                              | Page-aligned DP base; `nat2emu_0_rti` points DP here for fast access     |
| `00 FE10` | `B0_IRQ_STACK`                         | IRQ handler private stack pointer                                        |
| `00 FE12` | `B0_EMU_STACK`                         | Scratch: saved emulation stack pointer (during transitions)              |
| `00 FE14` | `B0_NAT_STACK`                         | Scratch: saved native stack pointer (during transitions)                 |
| `00 FE18` | `B0_SHIM_TMP`                          | Scratch: A/X/Y save area for `emu2nat_0_rti` / `nat2emu_0_rti` (6 bytes) |

`B0_EMU_STACK` and `B0_NAT_STACK` are only valid when the other mode is in operation - it is assumed that one mode
will always switch to the other and back, whereupon the relevant stack pointer will be restored from these locations.

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

### `emu2nat_0_rti` — emulation mode → native mode (shortcut, no extras)

Cut-down sibling of `emu2nat_rti` for callers with a fixed, known continuation and no extra
caller-stack context to carry across — no `mvp` block copy, so it's much cheaper. It swaps the
CPU straight onto `B0_NAT_STACK` and carries only A/X/Y (16-bit) through a scratch variable
instead of copying stack bytes.

**Caller constructs on the emulation stack before jumping:**

```
[S+4]  bank byte of continuation addr
[S+3]  hi byte of continuation addr
[S+2]  lo byte of continuation addr
[S+1]  P — flags for destination
```

Constructed with two `pea` instructions, then `jmp emu2nat_0_rti` (or `jml` from outside the segment).

**Shim steps:**

1. `sei`, `clc / xce` — switch to native mode, `rep #$31` (16-bit A/X/Y, clear carry).
2. Save caller's A/X/Y to `B0_SHIM_TMP` (scratch, not the block-copy path used by `emu2nat_rti`).
3. Pop the 4-byte caller frame (`pla / ply`) off the emulation stack; record `tsx → B0_EMU_STACK`.
4. Switch S onto `B0_NAT_STACK` (`ldx a:B0_NAT_STACK / txs`) and push the frame straight back (`phy / pha`) — this is a register move, not a `mvp` copy.
5. Restore A/X/Y from `B0_SHIM_TMP`, `rti` — lands at the 24-bit continuation in native mode.

**Does not** force B=0 on entry (assumes DBR is already 0, which always holds while running in
emulation mode) and leaves DP untouched.

---

### `nat2emu_0_rti` — native mode → emulation mode (shortcut, no extras)

Cut-down sibling of `nat2emu_rti`, same trade-off as `emu2nat_0_rti`: fixed continuation, no
extra bytes, no `mvp`. Also borrows DP briefly to speed up access to its scratch variable.

**Caller constructs on the native stack before jumping:**

```
[S+4]  hi byte of continuation addr (bank 0 implied)
[S+3]  lo byte of continuation addr
[S+2]  P — flags for destination
[S+1]  — don't care
```

Constructed with two `pea` instructions, then `jmp nat2emu_0_rti`.

**Shim steps:**

1. `sei`, `rep #$31` (16-bit, clear carry).
2. `pea B0_BASE / pld` — point DP at `B0_BASE` (`$00FE00`) so `B0_SHIM_TMP` can be addressed
   directly-page (`z:<`) instead of absolute (`a:`), for speed.
3. Save caller's A/X/Y to `B0_SHIM_TMP`.
4. Pop the 4-byte caller frame (`pla / ply`) off the native stack; record `tsx → B0_NAT_STACK`.
5. Switch S onto `B0_EMU_STACK` (`ldx z:<B0_EMU_STACK / txs`) and push the frame straight back (`phy / pha`).
6. `plb` (discard) / `phk / plb` — force `B=0`.
7. Restore X, Y (16-bit) from `B0_SHIM_TMP`; `lda #0 / tcd` — force `DP=0` (undoes the step-2 borrow). **Mandatory** before entering emulation mode, same as `nat2emu_rti`.
8. Restore AH from `B0_SHIM_TMP`; `sec / xce` — switch to emulation mode, `rti` at the continuation. Only `AH`, `XL` and `YL` survive the round trip (matching the 8-bit view emulation mode exposes).

---

### `emu_handle_irq` — IRQ arriving in emulation mode

Lives in the `boot_CODE` segment (ROM only, not the `default_handlers` RAM mirror) — see
[Why `emu_handle_irq`/`emu_handle_cop` don't need mirroring](#why-emu_handle_irqemu_handle_cop-dont-need-mirroring)
below. Hardware has already pushed `PCH, PCL, P` (the interrupted return address and flags) onto
the emulation stack.

```
[S+3]  PC hi of interrupted code
[S+2]  PC lo of interrupted code
[S+1]  P  of interrupted code
```

Flow:

1. `sta dp_mos_INT_A` — stash A (no stack push, keeps the original frame intact).
2. `lda 1,S / and #$10` — test B flag in stacked P. If set it is a BRK, not IRQ: `jmp emu_handle_brk`.
3. Push frame for `emu2nat_0_rti` targeting label `@c` (bank `FF`, `P = $04`), then `jmp emu2nat_0_rti`.
4. CPU switches to native mode; A/X/Y are carried across via `B0_SHIM_TMP`, not the original interrupted PC/P (those were consumed building the `@c` frame).
5. At `@c` (native mode): push a fake RTI frame targeting `@ret`, then `jml default_IVIRQ`.
6. `default_IVIRQ` runs the native IRQ dispatcher and exits via RTI, landing at `@ret`.
7. At `@ret` (native mode): push frame for `nat2emu_0_rti` targeting `@c2` (bank 0 implied), then `jml nat2emu_0_rti`.
8. CPU switches back to emulation mode.
9. At `@c2`: `lda dp_mos_INT_A` restores A, `rti` — returns to the original interrupted emulation code.

---

### `emu_handle_cop` — COP in emulation mode

Also lives in `boot_CODE` now. Short front-end that falls straight through into the full
`emu2nat_rti` (not the `_0` shortcut — it needs to carry the caller's flags byte as an extra).

```asm
emu_handle_cop: php                    ; save caller's flags (+1 extra byte)
                pea cop_handle_emu>>8
                pea $04+((>cop_handle_emu)<<8)
                pea 1                  ; #extra = 1 (the flags byte)
                jmp emu2nat_rti
```

Switches to native mode and RTIs into `cop_handle_emu` (`cop.asm`), which now forces `DP=0` on
both the way in (`pea 0` in place of the old `phd`) and the way out (`pld / phd` before its
`jml nat2emu_rti` return, `cop.asm:122`) — `cop_handle_emu` runs in native mode and is no longer
willing to assume the caller's DP was already 0.

#### Why `emu_handle_irq`/`emu_handle_cop` don't need mirroring

Only the code that actually executes the `xce` mode switch (i.e. the four `default_handlers`
shims) needs to be identical at the same address in both bank `00` and bank `FF` — that's the
instant PBR is ambiguous. `emu_handle_irq`, `emu_handle_nmi` and `emu_handle_cop` never execute
`xce` themselves; they just build a frame and jump into a shim that does. By the time the mode
actually switches, PC is already inside the mirrored `default_handlers` page, so these entry
points are free to live in ordinary ROM (`boot_CODE`) instead of being copied to RAM at boot.

---

### Abort handlers

- **`emu_handle_abort`** — `pha / lda #DEICE_STATE_ABORT / clc / xce / jml deice_enter_emu`. Bare mode switch; no stack transfer. DeICE takes full control.
- **`nat_handle_abort`** — `rep #$30 / pha / lda #DEICE_STATE_ABORT / jml deice_enter_nat` (via `enter_deice`). Same intent in native mode.
- **`deice_nat2emu_rti`** — three instructions: `sec / xce / rti`. Used by DeICE (`deice.asm:203`) to return from a debugging session to the original emulation-mode code.

---

### Native stubs

Short `jml` trampolines so the hardware vector table can reach the real handlers:

| Label            | Target                           |
|------------------|----------------------------------|
| `nat_handle_cop` | `jml cop_handle_nat` (`cop.asm`) |
| `nat_handle_brk` | `jml brk_handle_nat` (`brk.asm`) |
| `nat_handle_nmi` | `rti` (ignored)                  |
| `nat_handle_irq` | `jml default_IVIRQ` (`irqs.asm`) |

These must live in this segment because the hardware vector table is also near `$FF FF00` and `$00 FFE0`, and a `jml` to the copied RAM is shorter/safer than reaching deep into ROM.

---

## Callers outside `default_handlers`

`kernel.asm` rows are `emu_handle_irq`/`emu_handle_cop` in `boot_CODE` — see
[Why they don't need mirroring](#why-emu_handle_irqemu_handle_cop-dont-need-mirroring).

| File              | Line | Direction | Shim                | Why                                                 |
|-------------------|------|-----------|---------------------|-----------------------------------------------------|
| `kernel.asm`      | 392  | emu → nat | `emu2nat_0_rti`     | `emu_handle_irq`: enter native for `default_IVIRQ`  |
| `kernel.asm`      | 398  | nat → emu | `nat2emu_0_rti`     | `emu_handle_irq`: return to interrupted emu code    |
| `kernel.asm`      | 411  | emu → nat | `emu2nat_rti`       | `emu_handle_cop`: enter native for `cop_handle_emu` |
| `cop.asm`         | 122  | nat → emu | `nat2emu_rti`       | COP call returns to 8-bit caller                    |
| `brk.asm`         | 158  | nat → emu | `nat2emu_rti`       | BRK handler returns to emulation                    |
| `osbyte_word.asm` | 750  | nat → emu | `nat2emu_rti`       | OSBYTE/OSWORD returns to emu caller                 |
| `roms.asm`        | 171  | nat → emu | `nat2emu_rti`       | Return from ROM service call                        |
| `roms.asm`        | 199  | emu → nat | `emu2nat_rti`       | Enter native to service a ROM call                  |
| `vectors.asm`     | 41   | emu → nat | `emu2nat_rti`       | BBC vector entry: cross to native handler           |
| `vectors.asm`     | 118  | nat → emu | `nat2emu_0_rti`     | BBC vector exit: return result to emu (no extras)   |
| `vectors.asm`     | 288  | nat → emu | `nat2emu_rti`       | Exit native vector back to emulation                |
| `vectors.asm`     | 312  | emu → nat | `emu2nat_rti`       | Enter native for vector dispatch                    |
| `deice.asm`       | 203  | nat → emu | `deice_nat2emu_rti` | DeICE exit                                          |

---

## Stack-pointer variables across nested mode switches

`B0_EMU_STACK` (`$00FE12`) and `B0_NAT_STACK` (`$00FE14`) are initialized at boot (`kernel.asm:466-469`) to `STACKBBC_TOP` and `STACKNAT_TOP` and remain live for the entire duration of any active call chain — not just within a single shim.

Each shim updates the variable for the mode being *left* and reads the variable for the mode being *entered*. The `_0` shims follow the same rule even though they move a register instead of copying a block:

| Shim            | Writes                           | Reads                                   |
|-----------------|----------------------------------|-----------------------------------------|
| `emu2nat_rti`   | `B0_EMU_STACK` := current emu SP | `B0_NAT_STACK` to place native frame    |
| `nat2emu_rti`   | `B0_NAT_STACK` := current nat SP | `B0_EMU_STACK` to place emulation frame |
| `emu2nat_0_rti` | `B0_EMU_STACK` := current emu SP | `B0_NAT_STACK` to place native frame    |
| `nat2emu_0_rti` | `B0_NAT_STACK` := current nat SP | `B0_EMU_STACK` to place emulation frame |

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

- DP and B must be 0 on entry to emulation mode. Both `nat2emu_rti` and `nat2emu_0_rti` enforce this unconditionally before `xce` — `nat2emu_0_rti` does it via `phk/plb` and `lda #0 / tcd` rather than `pld/phd/plb/plb`, but the effect (and the requirement) is identical.
- `emu2nat_rti` and `emu2nat_0_rti` do **not** force `B=0` on entry to native mode; they assume DBR is already 0, which always holds while code is running in emulation mode. Neither touches DP.
- `nat2emu_0_rti` only preserves `AH`, `XL` and `YL` across the round trip (matching the 8-bit view emulation mode exposes) — it is not a drop-in replacement for `nat2emu_rti` wherever the caller's full `AL` needs to survive.
- `emu2nat_0_rti` / `nat2emu_0_rti` carry no extra caller-stack bytes and do no `mvp` copy — they only suit callers with a fixed, statically-known continuation (currently just `emu_handle_irq`'s two legs). Anything that needs to carry variable extra context across still needs the full `emu2nat_rti` / `nat2emu_rti`.
- `B0_EMU_STACK` / `B0_NAT_STACK` track the live boundary of each mode's stack for the duration of any active call chain. They are updated (not stacked) by every mode-switch shim (including the `_0` variants) and must not be written by any other code.
- `B0_SHIM_TMP` (`$00FE18`, 6 bytes) is scratch, valid only for the duration of a single `_0` shim call — unlike `B0_EMU_STACK`/`B0_NAT_STACK` it is not expected to survive across nested mode switches.
- All four mode-switch shims (`emu2nat_rti`, `nat2emu_rti`, `emu2nat_0_rti`, `nat2emu_0_rti`) open with `sei`. NMIs can still arrive; NMI handlers must not disturb memory below the current SP.
- Emulation stack is page `$01` (`STACKBBC`, 8-bit S). Native stack is `$00 F700`–`$00 FADF` (`STACKNAT`, 16-bit S, up to `STACKNAT_TOP` at `$00FAE0`). The `mvp` moves data between these two physically separate regions (the `_0` shims move data with plain pushes/pops instead).
