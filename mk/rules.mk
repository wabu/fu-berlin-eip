.SUFFIXES: .a .so .c .xc .h .o .O .install .inhead .inlib .uninstall .unhead .unlib
include $(ROOT)/mk/common.mk
include $(ROOT)/mk/tar.mk

CLEAN += $(BIN:=.clean) $(BIN:=.o.clean) $(LIB:=.a.clean) $(SHR:=.so.clean) $(SRC:=.o.clean)

BININSTALL += $(BIN:=.install)
RESINSTALL += $(RES:=.install)
LIBINSTALL += $(LIB:=.a.install)
SHRINSTALL += $(SHR:=.so.install)
INCINSTALL += $(INC:=.h.install)

BINUNINSTALL += $(BIN:=.uninstall)
RESUNINSTALL += $(RES:=.uninstall)
LIBUNINSTALL += $(LIB:=.a.uninstall) $(SHR:=.so.uninstall)
INCUNINSTALL += $(INC:=.h.uninstall)


# compile c files
%.o:	%.c  $(INC:=.h) $(HDR:=.h)
	echo "CC $<"
	$(CC) $(CFLAGS) -c $< -o $@

# compile c files
%.o:	%.xc $(INC:=.h) $(HDR:=.h)
	echo "XCC $<"
	$(XCC) $(XCCFLAGS) -c $< -o $@

%.dvi: %.tex
	echo "TX $<"
	latex "$<"

# link an executable
$(BIN): $(SRC:=.o) $(BIN:=.o)
	echo "LD $@"
	$(LD) $^ $(LDFLAGS) -o $@.xe

# not needed
# create a shared lib
#$(SHR:=.so): $(SRC:=.o)
#	echo "SO $@"
#	$(SO) $(SRC:=.o) -o $@

# create a lib archive
$(LIB:=.a): $(SRC:=.o) $(BIN:=.o)
	echo "AR $@"
	$(AR) $@ $(SRC:=.o) $(BIN:=.o)

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

all: $(BIN) $(SHR:=.so) $(LIB:=.a)
clean: $(CLEAN)

install: $(BININSTALL) $(LIBINSTALL) $(SHRINSTALL) $(INCINSTALL) $(RESINSTALL)
uninstall: $(BINUNINSTALL) $(LIBUNINSTALL) $(INCUNINSTALL) $(RESUNINSTALL)
