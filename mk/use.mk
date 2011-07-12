include $(ROOT)/mk/common.mk

USEPATH=$(ROOT)/$(USE)
USENAME=$(shell grep NAME $(USEPATH)/Makefile | sed 's/NAME *= *//')
USELIB =$(shell grep LIB $(USEPATH)/Makefile | sed 's/LIB *= *//')
USEFILE=$(USEPATH)/$(USELIB).a
USEHDR =$(shell grep HDR $(USEPATH)/Makefile | sed 's/HDR *= *//')

INCARGS += -I$(USEPATH)
LIBARGS += -L$(USEPATH) -l$(USELIB)
HDR += $(USEHDR)

$(BIN):      $(USEFILE)
$(SHR:=.so): $(USEFILE)
$(LIB:=.a):  $(USEFILE)

tar-self: tar-$(USE)

tar-$(USE):
	echo "MK tar-$(USENAME) in $(USEPATH)"
	(cd $(USEPATH); make tar-self)

$(USEFILE): $(USEHDR:=.h)
	echo "MK $(USELIB).a in $(USEPATH)"
	(cd $(USEPATH); make $(USELIB).a)

