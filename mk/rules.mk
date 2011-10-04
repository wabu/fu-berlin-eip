.SUFFIXES: .a .so .c .xc .h .o .O .install .inhead .inlib .uninstall .unhead .unlib

CLEAN += $(BIN:=.clean) $(BIN:=.o.clean) $(LIB:=.a.clean) $(SHR:=.so.clean) $(SRC:=.o.clean)

# compile c files
%.o:	%.c  $(INC:=.h) $(HDR:=.h)
	echo "CC $<"
	$(CC) $(CFLAGS) -c $< -o $@

# link an executable
$(BIN): $(SRC:=.o) $(BIN:=.o)
	echo "LD $@"
	$(LD) $^ $(LDFLAGS) -o $@

# not needed
# create a shared lib
#$(SHR:=.so): $(SRC:=.o)
#	echo "SO $@"
#	$(SO) $(SRC:=.o) -o $@

# create a lib archive
$(LIB:=.a): $(SRC:=.o) $(BIN:=.o)
	echo "AR $@"
	$(AR) $@ $(SRC:=.o) $(BIN:=.o)

$(CLEAN):
	echo "RM $(@:.clean=)"
	rm -f $(@:.clean=)

all: $(BIN) $(SHR:=.so) $(LIB:=.a)
clean: $(CLEAN)

install: $(BININSTALL) $(LIBINSTALL) $(SHRINSTALL) $(INCINSTALL) $(RESINSTALL)
uninstall: $(BINUNINSTALL) $(LIBUNINSTALL) $(INCUNINSTALL) $(RESUNINSTALL)
