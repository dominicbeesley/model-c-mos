# MOS ROM Modules Makefile

		include ../../Makefile.defs

.PHONY:		all

SUBDIRSWIMAKE:=$(shell for a in $$(find -mindepth 1 -type d); do if [ -e $$a/Makefile ]; then echo $$a; fi; done;)

LOADSCRIPT=$(BUILD)/loadscript.txt

all: 
	$(foreach a,$(SUBDIRSWIMAKE), $(MAKE) -C $(a) all;)

	echo "*| LOAD MODULES" > $(LOADSCRIPT)
	$(foreach a,$(SUBDIRSWIMAKE), cat $(BUILD)/$(a)/load.txt >> $(LOADSCRIPT);)


clean: 
	-rm $(LOADSCRIPT)
	$(foreach a,$(SUBDIRSWIMAKE), $(MAKE) -C $(a) clean;)
