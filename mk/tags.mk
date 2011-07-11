ctags: $(TAGFILE)
$(TAGFILE): $(HEAD:=.h) $(SRC:=.c) $(BIN:=.c)
	echo TG $(HEAD:=.h) $(SRC:=.c) $(BIN:=.c)
	$(TG) $(HEAD:=.h) $(SRC:=.c) $(BIN:=.c) > /dev/null
ctagsclean:
	echo RM $(TAGFILE)
	rm -f $(TAGFILE) || ture 2>/dev/null
clean:	ctagsclean
all:		ctags
