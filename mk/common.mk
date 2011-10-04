include $(ROOT)/config.mk
BASE?=.
IFS=\n

all:
install:
uninstall:
test:
ctags:
default: all

.PHONY:	all clean install uninstall ctags
.SILENT:

BININSTALL += $(BIN:=.install)
RESINSTALL += $(RES:=.install)
LIBINSTALL += $(LIB:=.a.install)
SHRINSTALL += $(SHR:=.so.install)
INCINSTALL += $(INC:=.h.install)

BINUNINSTALL += $(BIN:=.uninstall)
RESUNINSTALL += $(RES:=.uninstall)
LIBUNINSTALL += $(LIB:=.a.uninstall) $(SHR:=.so.uninstall)
INCUNINSTALL += $(INC:=.h.uninstall)

#cleanup
$(CLEAN):
	echo "RM $(@:.clean=)"
	rm -f $(@:.clean=)

$(BININSTALL): $(BIN)
	echo "IN $(@:.install=) to $(BINDIR)"
	mkdir -p $(BINDIR)
	cp -f $(@:.install=) $(BINDIR)/
	chmod 0775 $(BINDIR)/$(@:.install=)
$(RESINSTALL): $(RES)
	echo "IN $(@:.install=) to $(RESDIR)"
	mkdir -p $(RESDIR)
	cp -f $(@:.install=) $(RESDIR)/
$(LIBINSTALL): $(LIB:=.a) $(SHR:=.so)
	echo "IN $(@:.install=) to $(LIBDIR)"
	mkdir -p $(LIBDIR)
	cp -f $(@:.install=) $(LIBDIR)/
	chmod 0664 $(LIBDIR)/$(@:.install=)
$(SHRINSTALL): $(SHR:=.so)
	echo "IN $(@:.install=) to $(LIBDIR)"
	mkdir -p $(LIBDIR)
	cp -f $(@:.install=) $(LIBDIR)/
	chmod 0775 $(LIBDIR)/$(@:.install=)
$(INCINSTALL): $(INC:=.h)
	echo "IN $(@:.install=) to $(INCDIR)"
	mkdir -p $(INCDIR)
	cp -f $(@:.install=) $(INCDIR)/
	chmod 0664 $(INCDIR)/$(@:.install=)

$(BINUNINSTALL):
	echo "UN $(@:.uninstall=) from $(BINDIR)"
	rm -f $(BINDIR)/$(@:.uninstall=)
$(RESUNINSTALL):
	echo "UN $(@:.uninstall=) from $(RESDIR)"
	rm -f $(RESDIR)/$(@:.uninstall=)
$(LIBUNINSTALL):
	echo "UN $(@:.uninstall=) from $(LIBDIR)"
	rm -f $(LIBDIR)/$(@:.uninstall=)
$(INCUNINSTALL):
	echo "UN $(@:.uninstall=) from $(INCDIR)"
	rm -f $(INCDIR)/$(@:.uninstall=)
