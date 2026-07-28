

# 65816 code checker

 - check for entry / exit: DP, bank, reg sizes
 - add ;.XXX keywords to assist, relax rules etc
 - check 24 bit symbols cast to a: or z: are in correct DP/BANK
 - follow JSR, JSL, JMP, JML, Bxx and PEA/RTS PEA/PEA/RTI
 - check funtions entered with correct return type
 - use symbols from link
 - check .cfg file?
 - macro expansion
 - parse listing files rather than assembly - expand macros?
 - parse all assembly files
 - change more of the COP call API to use arguments on stack: most calls push pop BHA before calling then push BHA!
 