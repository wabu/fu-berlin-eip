include $(ROOT)/mk/common.mk

MKSUBDIR = \
	for i in $$dirs; do \
		if [ ! -d "$$i" ]; then \
			echo "Skipping nonexistent directory: $$i" 1>&2; \
		else \
			echo "MK $${targ} in $(BASE)/$$i"; \
			(cd "$$i" && $(MAKE) BASE="$(BASE)/$$i" "$${targ}") || exit $?; \
		fi; \
	done

all:
	dirs="$(SUBS)"; targ=all; $(MKSUBDIR)
test:
	dirs="$(SUBS)"; targ=test; $(MKSUBDIR)
ctags:
	dirs="$(SUBS)"; targ=ctags; $(MKSUBDIR)
clean:
	dirs="$(SUBS)"; targ=clean; $(MKSUBDIR)
install:
	dirs="$(SUBS)"; targ=install; $(MKSUBDIR)
uninstall:
	dirs="$(SUBS)"; targ=uninstall; $(MKSUBDIR)
