EXE=flip-bits
MODS=utils cursor board ui

TOP_SRC=$(EXE).scm
MODS_IMP=$(MODS:%=%.import.scm)
MODS_OBJ=$(MODS:%=%.o)
LIBS=matchable
IMPORT_LIBS=$(LIBS:%=-R %) $(MODS:%=-R %)
LINK_FLAGS=-L -lncurses

PREFIX=/usr/local
BINDIR=$(PREFIX)/bin


.PHONY: all clean install uninstall


all: $(EXE)

$(EXE): $(TOP_SRC) $(MODS_IMP) $(MODS_OBJ)
	csc -static $(IMPORT_LIBS) $(TOP_SRC) -o $(EXE) $(LINK_FLAGS)

%.import.scm : %.scm
	$(eval MODULE=$(basename $<))
	csc $< -c -J -unit $(MODULE)
	@-touch $(MODULE).o
	@-touch $(MODULE).import.scm

clean:
	@-rm -f $(EXE) *.o *.import.scm *.link

install: $(EXE)
	@-install -m 755 $(EXE) $(BINDIR)

uninstall:
	@-rm -f $(BINDIR)/$(EXE)
