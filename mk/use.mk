include $(ROOT)/mk/common.mk

USEPATH=$(ROOT)/$(USE)
USEFILE=$(USEPATH)/lib$(USE:=).a

INCARGS += -I$(USEPATH)
LIBARGS += -L$(USEPATH) -l$(USE)
HDR += $(USEPATH)/$(USE)

$(BIN): $(USEFILE)
$(SHR:=.so): $(USEFILE)
$(LIB:=.a): $(USEFILE)

tar-self: tar-$(USE)

tar-$(USE):
	echo "MK tar-$(USE) in $(USEPATH)"
	(cd $(USEPATH); make tar-self)
$(USEFILE): $(USEPATH)/$(USE).h
	echo "MK lib$(USE).a in $(USEPATH)"
	(cd $(USEPATH); make)

