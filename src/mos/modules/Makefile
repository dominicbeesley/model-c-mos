# MOS ROM Modules Makefile

.PHONY:		all

SUBDIRSWIMAKE:=$(shell for a in $$(find -mindepth 1 -type d); do if [ -e $$a/Makefile ]; then echo $$a; fi; done;)

all: 
	$(foreach a,$(SUBDIRSWIMAKE), $(MAKE) -C $(a) all;)

clean: 
	$(foreach a,$(SUBDIRSWIMAKE), $(MAKE) -C $(a) all;)
