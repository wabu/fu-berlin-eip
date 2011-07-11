TMPROOT = $(ROOT)/tmp
TMPSELF = $(TMPROOT)/tmp/$(SELF)
TARSELF = $(RES) $(BIN:=.c) $(SRC:=.c) $(INC:=.h) $(HDR:=.h) Makefile
TARROOT = $(ROOT)/.hg $(ROOT)/README $(ROOT)/mk $(ROOT)/config.cyg $(ROOT)/config.unix $(ROOT)/config.tutor


tmp-root:
	echo "RM $(TMPROOT)"
	rm -Rf $(TMPROOT)/tmp
	echo "MD $(TMPROOT)/tmp"
	mkdir -p $(TMPROOT)/tmp
tmp-self:
	echo "MD $(TMPSELF)"
	mkdir -p $(TMPSELF)
tar-root: tmp-root
	echo "MK Makefile"
	echo -e 'ROOT=.\nSELF=.\nNAME=gfx\nSUBS=$(SELF)\ninclude $$(ROOT)/mk/dir.mk' > $(TMPROOT)/tmp/Makefile
	echo "CP $(TMPROOT)"
	cp -Rf $(TARROOT) $(TMPROOT)/tmp
	cp -f $(TMPROOT)/tmp/config.tutor $(TMPROOT)/tmp/config.mk
tar-self: tmp-self
	echo "CP $(TMPSELF)"
	cp -Rf $(TARSELF) $(TMPSELF)
tar: tar-root tar-self
	echo "TAR $(NAME).tar.gz"
	mv $(TMPROOT)/tmp $(TMPROOT)/$(NAME)
	tar -czf $(NAME).tar.gz -C $(TMPROOT) $(NAME)
	echo "RM $(TMPROOT)/$(NAME)"
	rm -Rf $(TMPROOT)/$(NAME)
