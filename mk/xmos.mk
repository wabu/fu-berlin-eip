.SUFFIXES: .a .so .c .xc .h .o .O .install .inhead .inlib .uninstall .unhead .unlib

INFIX=.x
CLEAN_X += $(BIN:=$(INFIX).xe.clean) $(BIN:=$(INFIX).o.clean) $(LIB:=$(INFIX).a.clean) $(SHR:=$(INFIX).so.clean) $(SRC:=$(INFIX).o.clean)

# compile c files
%$(INFIX).o:	%.c  $(INC:=.h) $(HDR:=.h)
	echo "CC $<"
	$(XMOS_CC) $(XMOS_CFLAGS) -c $< -o $@

# compile c files
%$(INFIX).o:	%.xc $(INC:=.h) $(HDR:=.h)
	echo "XCC $<"
	$(XMOS_XCC) $(XMOS_XCCFLAGS) -c $< -o $@

# link an executable
$(BIN:=$(XMOS_BINSUFFIX)): $(SRC:=$(INFIX).o) $(BIN:=$(INFIX).o)
	echo "LD $@"
	$(XMOS_LD) $^ $(XMOS_LDFLAGS) -o $@

# not needed
# create a shared lib
#$(SHR:=.so): $(SRC:=.o)
#	echo "SO $@"
#	$(SO) $(SRC:=.o) -o $@

# create a lib archive
$(LIB:=$(INFIX).a): $(SRC:=$(INFIX).o) $(BIN:=$(INFIX).o)
	echo "AR $@"
	$(XMOS_AR) $@ $(SRC:=$(INFIX).o) $(BIN:=$(INFIX).o)
$(CLEAN_X):
	echo "RM $(@:.clean=)"
	rm -f $(@:.clean=)

all: $(BIN:=$(XMOS_BINSUFFIX)) $(SHR:=$(INFIX).so) $(LIB:=$(INFIX).a)
clean: $(CLEAN_X)

install: $(BININSTALL) $(LIBINSTALL) $(SHRINSTALL) $(INCINSTALL) $(RESINSTALL)
uninstall: $(BINUNINSTALL) $(LIBUNINSTALL) $(INCUNINSTALL) $(RESUNINSTALL)
