# model-c-mos 

*An Operating System for the "Model C Micro" and "C20K" and the 65816 which 
allows existing BBC Micro / Master programs and ROMs to coexist with full 
native mode 65816 executables*

The model-c-mos is a proof of concept operating system that presents a new 
clean API using the 65816's COP instruction to perform system calls. The
calls are loosely based on those of the MOS developed for the Acorn 
Communicator in the prototype phase, though that is likely to change if a 
proper full-blown OS is developed.

The driver for the the model-c-mos is twofold:
 - to allow new user applications to break the 64K limit of the 6502 and grow 
   into the 16MB address space of the 65186.
 - to allow existing filing system ROMS, applications and games to run in a
   pseudo-virtual environment

Aims:
 - existing games, applications and ROMs to be able to run
 - new applications can access 16-bit filing systems
 - 8-bit applications can access 16-bit filing systems

# Challenges

## Duplicate APIs

16-bit applications in general will use the COP call mechanism to access system
resources, where these are provided by an 8-bit ROM extension, for example 
an existing filing system the 16-bit OS will transform the call into one or
more 8-bit system calls and use the 8-bit vectors and ROM switching to pass the
call to the 8-bit ROM

Conversely 8-bit applications can call the 8-bit API and if the services i.e.
filing system is provided as a 16-bit module the call will be passed up to the
16-bit filing system.

## Interrupts and Exceptions

One of the main challenges is to handle interrupts in a way which is efficient
and allows interrupts to occur in either 8-bit (emulation) or 16-bit (native) 
mode seamlessly. Interrupts must also be passed round the 16-bit modules and 
8-bit ROMS where relevant.

The current PoC code manages this, but with a fair amount of overhead. 

## Stacks and Direct Page

The 65186 allows for larger program stacks (up to 64K) and for the Direct Page
to be located at different locations within bank 0. This provides a good deal
of flexibility and allows for different processes to have different stacks
which is a boon for writing multi-tasking operating systems

One of the challenges in future will be in handling the switching of stacks 
and stack contents between the 8 and 16-bit arenas, currently some of the stack
contents must be copied on switches from 8- to 16-bit modes which is costly.

# Current state of play Aug 2025

## Supported
- 8-bit filing systems supports
- 8-bit ROMs and service calls
- nascent 16-bit modules (keyboard, VDU)
- COP call dispatching some services implemented (VDU, memory management)
- 8-bit OSBYTE/OSWORD emulation (pass back to 16-bit APIs)

## Pending
- 8-bit filing systems load to 16MB memory space not supported, WINDOW!
- 16-bit filing systems not yet defined
- executable load format (relocatable o65 or a.out format?)
- eveything else!

