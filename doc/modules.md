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
| 12     | Length of module (offset to checksum)         |
| 14     | Flags                                         |
| 18     | Offset to title string                        |
| 20     | Version number XX.XX BCD                      |
| 22     | Offset to help string / long title            |
| 24     | Offset to command/help table                  |
| 26*    | COP index min (or -1)                         |
| 30*    | COP index max (or -1)                         |
| 34...  | code/data                                     |
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


