
# Model C MOS Memory Map

```

Emulation Mode                                    Native Mode

Log     Phys                                                 
0000    00 0000 +---------------------------------------------------------+     00 0000
                | Shared MOS Zero Page                                    | 
0100    00 0100 +---------------------------------------------------------+     00 0100
                | EMU only Stack                                          |
0200    00 0200 +---------------------------------------------------------+     00 0200
                | Shared MOS System Variables                             |
0300    00 0300 +---------------------------------------------------------+     00 0300
                | Shared VDU Variables                                    | 
0380    00 0380 +---------------------------------------------------------+     00 0380
                | Reserved / CFS / RFS                                    |
0400    00 0400 +---------------------------------------------------------+     00 0400
                | BBC MOS / EMU Language dependent                        |
0800    00 0800 +---------------------------------------------------------+     00 0800
                | Shared SOUND (printer buffer moved?)                    | 
0A00    00 0A00 +---------------------------------------------------------+     00 0A00
                | EMU Transient command buffer                            |
0B00    00 0B00 +---------------------------------------------------------+     00 0B00
                | Soft key buffers                                        |
0C00    00 0C00 +---------------------------------------------------------+     00 0C00
                | Character definitions 128-159                           | 
0D00    00 0D00 +---------------------------------------------------------+     00 0D00
                | EMU NMI / Econet / Ext vectors / ROM private pointers   |
0E00    00 0E00 +---------------------------------------------------------+     00 0E00
                |                                                         |
1000    FF 1000 +..........................+----+-------------------------+     00 1000 
                B                          B    |                         |
                B      ROM workspace       B    |                         |
          PAGE  B--------------------------B    |                         |
                B      Language            B    |                         |
                B                          B    |                         |
         HIMEM  B--------------------------B    |                         |
                B                          B    |                         |
                B      Screen Memory       B    |                         |
                B                          B    |                         |
                B                          B    |                         |
8000    XX XXXX +--------------------------+    |                         |
                S                          S    |                         |
                S      Paged ROMs          S    |-------------------------|     00 A000
                S                          S    | B0Blocks "handle blocks"|
C000    FF C000 +-----------------+--------+----+-------------------------|     00 C000
                M                 |                                       |
                M      MOS ROM    | HAZEL                  (may be moved  |
                M                 |                            in future) |
E000    ?? ???? ?-----------------+---------------------------------------|
                ?      **WINDOW**          ?    |                         |
                ? MOS at boot can be any   ?    |                         |
                ?     2K boundary          ?    |                         |
F000    FF F000 M--------------------------M    |                         |
                M                          M    |-------------------------|     00 F700
                M      MOS ROM             M    | Native mode OS Stack    |
FB00    FF FB00 M--------------------------M    |-------------------------|     00 FB00
                M  EMU/NAT handler code    M>>>>| copy of EMU/NAT code    |     copied at boot
FC00    FF FC00 +--------------------------+    |-------------------------|     00 FC00
          FRED  h                          h    | DeIce stack/workspace   |
FD00    FF FD00 h                          h    |-------------------------|     00 FD00
           JIM  h  Hardware registers      h    | Native OS vectors       |
FE00    FF FE00 h                          h    |-------------------------|     00 FE00
        SHEILA  h                          h    | System pointers         |
FF00    FF FF00 +--------------------------+    |-------------------------|     00 FF00
                M  EMU Ext vector entry    M    | EXSYS                   |
                M  points and HW vectors   M    |                         |
                +--------------------------+    +-------------------------+     01 0000
                                                | Handle pointers         |
                                                +-------------------------+     01 0100
                                                |                         |
                                                |   --- reserved ---      |
                                                |                         |
                                                +-------------------------+     02 0000
                                                |                         |
                                                |   USER PROGRAM MEMORY?  |
                                                |                         |
                                                +-------------------------+ END OF RAM 
                                                |XXXXXXXXXXXXXXXXXXXXXXXXX|
                                                |XXXXXXX RESERVED XXXXXXXX|
                                                |XXXXXXXXXXXXXXXXXXXXXXXXX|
                                                +-------------------------+     60 0000
                                                |XXXXXXXXXXXXXXXXXXXXXXXXX|
                                                |XXXXXXX RESERVED XXXXXXXX|
                                                |XXXXXXXXXXXXXXXXXXXXXXXXX|
                                                +-------------------------+ BB RAM BASE
                                                |                         |
                                                |   BATTERY BACKED RAM    |
                                                |        (optional)       |
                                                |       +-----------------+     7C 0000
                                                |       |                 |
                                                |       |  EMU SW RAM     |
                                                |       |                 |
                                                +-------+-----------------+     80 0000
                                                |XXXXXXXXXXXXXXXXXXXXXXXXX|
                                                |XXXXXXX RESERVED XXXXXXXX|  [Flash repeats]
                                                |XXXXXXXXXXXXXXXXXXXXXXXXX|
                                                +-------------------------+ Flash BASE (98 0000)
                                                |                         |
                                                |   Flash Memory 39x040   |
                                                |                         |
                                                |       +-----------------+     9C 0000
                                                |       |                 |
                                                |       |  EMU SW ROM/MOS |
                                                |       |                 |
                                                +-------+-----------------+     A0 0000
                                                |XXXXXXXXXXXXXXXXXXXXXXXXX|
                                                |XXXXXXX RESERVED XXXXXXXX|  [Flash repeats]
                                                |XXXXXXXXXXXXXXXXXXXXXXXXX|
                                                +-------------------------+     F3 0000
                                                |                         |
                                                | "Screen memory"         |
                                                | unmapped access to BBC  |
                                                | low ram without overlays|
                                                +-------------------------+     F3 8000
                                                | Motherboard ROMs        |
                                                +-------------------------+     F3 C000
                                                | Motherboard MOS         |
                                                +-------------------------+     F4 0000
                                                |XXXXXXXXXXXXXXXXXXXXXXXXX|
                                                |XXXXXXX RESERVED XXXXXXXX|  undefined
                                                |XXXXXXXXXXXXXXXXXXXXXXXXX|
                                                +-------------------------+     FC 0000
                                                |                         |
                                                | Debug/Version info      |
                                                |                         |
                                                +-------------------------+     FD 0000
                                                |XXXXXXX RESERVED XXXXXXXX|  undefined
                                                +----------+--------------+     FE FC00
                                                |          |XX RESERVED XX|
                                                |          +--------------+     FE FC80
                                                |          | Blitter      |
                                                |          +--------------+     FE FC80
                                                |          | Paula sound  |      
                                                |          +--------------+     FE FC90
                                                |          | DMA          |
                                                |          +--------------+     FE FCA0
                                                |          | Blitter ext  |
                                                |          +--------------+     FE FCB0
                                                |          | Aeris        |
                                                |          +--------------+     FE FCC0
                                                |          |XX RESERVED XX|
                                                |          +--------------+     FE FCD0
                                                |          | i2/c eeprom  |
                                                |          +--------------+     FE FCE0
                                                |          |XX RESERVED XX|
                                                +----------+--------------+     FE FD00
                                                |XXXXXXX RESERVED XXXXXXXX|  undefined
                                                +-------------------------+     FF 0000
                                                |                         |
                                                | Mirror of emu bank 0    |
                                                |                         |
                                                +-------------------------+     
                                                



```
