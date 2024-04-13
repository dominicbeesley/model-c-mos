		include ../Makefile.defs

AS=ca65 
ASFLAGS=--auto-import -I $(TOP)/includes -I $(BUILD) --cpu 65816 -D__DEBUG=1 --feature string_escapes
LD=ld65
INCS=$(wildcard $(TOP)/includes/*.inc) $(filter-out version-date.inc, $(wildcard *.inc))
DEPS=$(INCS) 
TARGETS=boot.mos
OBJS_boot.mos=	kernel deice boot-vecs font roms debug vectors bbc-ext-vectors \
				bbc-nat-vectors b0blocks vdu cop irqs hardware bbcmosapi osbyte_word \
				buffers
SSD_EXTRAS=_21BOOT.txt.inf
SSD=$(SSDS)/model-c-mos.ssd
DEPLOY=$(DEPLOY_TOP)/model-c-mos
SCRIPTS=../../scripts

TARGETS_B = $(addprefix $(BUILD)/,$(TARGETS))



.PHONY: all clean

all:	$(TARGETS_B)

ssd:	all $(SSD)

deploy: ssd
	mkdir -p $(DEPLOY)
	dfs read -i -d $(DEPLOY) $(SSD)

UC=$(shell echo '$1'|tr '[:lower:]' '[:upper:]')

$(BUILD)/boot.mos:$(addprefix $(BUILD)/, $(addsuffix .o, $(OBJS_boot.mos)))

$(BUILD)/%.mos: %.cfg
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map --dbgfile $(basename $@).dbg -o $@ -C $(filter %.cfg, $^) $(filter %.o, $^) $(LIBS)
	echo "M.$(call UC,$(notdir $(basename $@))) FFFFC000 FFFFC000" >$@.inf
	$(SCRIPTS)/ca65lstupdate.pl $(basename $@).dbg $(BUILD)
	$(SCRIPTS)/getsymbols.pl <$(basename $@).sy2 >$(basename $@).1.noi
	$(SCRIPTS)/ld65debugsymbols.pl $(basename $@).dbg $(basename $@).2.noi

$(BUILD)/%.rom: %.cfg
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map --dbgfile $(basename $@).dbg -o $@ -C $(filter %.cfg, $^) $(filter %.o, $^) $(LIBS)
	echo "R.$(call UC,$(notdir $(basename $@))) FFFF8000 FFFF8000" >$@.inf
	$(SCRIPTS)/ca65lstupdate.pl $(basename $@).dbg $(BUILD)
	$(SCRIPTS)/getsymbols.pl $(ROMNO) <$(basename $@).sy2 >$(basename $@).noi
	$(SCRIPTS)/ld65debugsymbols.pl --romno $(ROMNO) $(basename $@).dbg $(basename $@).2.noi

$(BUILD)/%.o: 	%.asm $(DEPS) 
	$(AS) $(ASFLAGS) -o $@ -g -l $(basename $@).lst $<

$(SSD):	$(TARGETS_B) $(SSD_EXTRAS)
	dfs form -80 $(SSD)
	dfs title $(SSD) "model-c-mos"
	dfs opt4 -3 $(SSD)
	dfs add $(SSD) $(addprefix $(BUILD)/, $(addsuffix .inf, $(TARGETS))) $(SSD_EXTRAS)

clean:
	-rm $(TARGETS_B) 2>/dev/null
	-rm $(foreach t, $(TARGETS), $(foreach e,.map .sy2 .1.noi .2.noi .noi .dbg, $(addsuffix $(e), $(addprefix $(BUILD)/,$(t))))) 2>/dev/null
	-rm $(foreach t, $(TARGETS), $(foreach o, $(OBJS_$(t)), $(foreach e,.lst .o, $(addsuffix $(e), $(addprefix $(BUILD)/,$(o)))))) 2>/dev/null
	-rm $(SSD)


