# Model-C-MOS modules v0.00

This is the specification for Model C MOS modules

Modules are intended to be like sideways ROMS in a 24bit address space (as 
opposed to in sideways banks). 

Modules are binary format with fields as specified below
Modules are a 256 byte aligned
Modules _may_ be relocatable within a bank (fully relocatable)
Modules _may_ be bank agnostic (bank relocatable)

The modules presented here are not compatible with any pre-existing format 
(BBC, Communicator, RiscOS). 

## Module header

| Offset | Description                                   |
|--------|-----------------------------------------------|	
| 0      | BRL instruction to "start" code               |
| 3      | BRL instruction to initialisation code        |
| 6      | BRL instruction to finalisation code          |
| 9      | BRL instruction to service call handler       |
| 12     | Length of module (16bit) (offset to checksum) |
| 14     | 0 - reserved                                  |
| 18     | Flags                                         |
| 22     | Flags2                                        |
| 26     | Flags3                                        |
| 30     | Offset to title string                        |
| 32     | Version number XX.XX BCD                      |
| 34     | Offset to help string / long title            |
| 36     | Offset to command/help table                  |
| 38     | COP index min (or -1)                         |
| 40     | COP index max (or -1)                         |
| ...    | code/data                                     |
| Length | 16 bit checksum                               |

## Module COP calls

### COP COP_34_OPMOD

This COP call performs various actions on a module it is analogous to OS_Module
on Risc OS.

### COP_34_OPMOD - 10 Insert module from memory

On Entry:

	X	10
	BHA	pointer to memory in ROM/RAM

On Exit:

	V=0	Indicates success
	X	16 bit DP "private word" allocated

	V=1	Indicates failure
	X	Error Block


