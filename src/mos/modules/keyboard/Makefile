# keyboard Module makefile

		include ../../../Makefile.defs

AS=ca65 
ASFLAGS=--auto-import -I $(TOP)/includes -I $(BUILD) --cpu 65816 -D__DEBUG=1 --feature string_escapes
LD=ld65
INCS=$(wildcard $(TOP)/includes/*.inc) $(filter-out version-date.inc, $(wildcard *.inc))
DEPS=$(INCS) 
TARGETS=keyboard.mod
OBJS_keyboard.mod=	modhead keyboard ../../utils
SCRIPTS=$(TOP)/../scripts
BEEBN=X.KEYBRD

TARGETS_B = $(addprefix $(BUILD)/,$(TARGETS))

LOAD_ADDR = 7D8000

.PHONY: all clean
.PRECIOUS: $(subst %.mod, %.bin, $(TARGETS_B))

all:	$(TARGETS_B)

$(BUILD)/keyboard.bin:$(addprefix $(BUILD)/, $(addsuffix .o, $(OBJS_keyboard.mod)))

$(BUILD)/%.mod: $(BUILD)/%.bin
	$(SCRIPTS)/makemod.pl $< $@
	echo "$(BEEBN) 80808080 80808080" >$@.inf
	echo "*XMLOAD $(BEEBN) #D1 $(LOAD_ADDR)" > $(BUILD)/load.txt

$(BUILD)/%.bin: %.cfg
	$(LD) --start-addr 0x$(LOAD_ADDR) -vm -Ln $(basename $@).sy2 -m $(basename $@).map --dbgfile $(basename $@).dbg -o $@ -C $(filter %.cfg, $^) $(filter %.o, $^) $(LIBS)
	$(SCRIPTS)/ca65lstupdate.pl $(basename $@).dbg $(BUILD)
	$(SCRIPTS)/getsymbols.pl <$(basename $@).sy2 >$(basename $@).1.noi
	$(SCRIPTS)/ld65debugsymbols.pl $(basename $@).dbg $(basename $@).2.noi


$(BUILD)/%.o: 	%.asm $(DEPS) 
	$(AS) $(ASFLAGS) -o $@ -g -l $(basename $@).lst $<


clean:
	-rm $(TARGETS_B) 2>/dev/null
	-rm $(patsubst %.mod, %.bin, $(TARGETS_B)) 2>/dev/null
	-rm $(foreach t, $(basename $(TARGETS)), $(foreach e,.map .sy2 .1.noi .2.noi .noi .dbg .mod.inf .da.s, $(addsuffix $(e), $(addprefix $(BUILD)/,$(t))))) 2>/dev/null
	-rm $(foreach t, $(TARGETS), $(foreach o, $(OBJS_$(t)), $(foreach e,.lst .o .lst.rel, $(addsuffix $(e), $(addprefix $(BUILD)/,$(o)))))) 2>/dev/null


