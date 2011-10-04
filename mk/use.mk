include $(ROOT)/mk/common.mk

USEPATH=$(USE:%=$(ROOT)/%)
USENAME=$(shell grep -h NAME $(USEPATH:%=%/Makefile) | sed 's/NAME *= *//')
USELIB =$(shell grep -h LIB $(USEPATH:%=%/Makefile) | sed 's/LIB *= *//')
USEFILE=$(shell grep -H LIB $(USEPATH:%=%/Makefile) | sed 's/Makefile:LIB *= *//')
USEHDR =$(shell grep -H HDR $(USEPATH:%=%/Makefile) | sed 's/HDR *= *//' | \
	awk -F 'Makefile:' '{split($$2,hdr,/ /); for (h in hdr) print $$1 hdr[h]};')

INCARGS += $(USEPATH:%=-I%)
XMOS_INCARGS += $(USEPATH:%=-I%)
LIBARGS += 
HDR += $(USEHDR)
    
debug: debug-use
debug-use:
	echo "names: $(USENAME)"
	echo "libs:  $(USELIB)"
	echo "files: $(USEFILE)"
	echo "hdrs:  $(USEHDR)"

$(BIN:=$(BINSUFFIX)): $(USEFILE:=$(INFIX).a)
$(SHR:=$(INFIX).so): $(USEFILE:=$(INFIX).a)
$(LIB:=$(INFIX).a):  $(USEFILE:=$(INFIX).a)

$(USEFILE:=$(INFIX).a): $(USEHDR:=.h)
	echo "MK $(dir $@)"
	(cd $(dir $@); make)

