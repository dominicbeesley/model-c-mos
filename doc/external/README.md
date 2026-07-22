# External References

## The C20K / Blitter hardware "API"

[model-c-hardware API](https://github.com/dominicbeesley/model-c-hardware/blob/main/doc/API.md)

It's not actually an API but a description of the memory layout of the C20K/Blitter systems. 

The key areas to digest for this project are:

 - 6502/65C02/T65 extras
 - 65816 extras
 - FF FE31 SWMOS
 - FF FE3E..3F - 65816 RAM window

 When considering the SWMOS register note that FE31 (sheila_MEM_CTL) is set to have the auto
 boot mode set such that the emulation sees the BBC micro layout at CPU address 00 XXXX but
 native mode only sees this in bank FF


