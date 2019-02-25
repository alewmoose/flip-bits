EXE=flip-bits
MOD=utils board ui

TOP_SRC=$(EXE).scm
MOD_SRC=$(MOD:%.scm)
MOD_IMP=$(MOD:%=%.import.scm)
MOD_OBJ=$(MOD:%=%.o)
LIBS=matchable
LINK_LIBS=$(LIBS:%=-link %)
LINK_FLAGS=-L -lncurses

.PHONY: all clean

all: $(EXE)

$(EXE): $(TOP_SRC) $(MOD_IMP) $(MOD_OBJ)
	csc -static $(LINK_LIBS) $(TOP_SRC) -o $(EXE) $(LINK_FLAGS)

%.import.scm : %.scm
	$(eval MODULE=$(basename $<))
	csc $< -c -J -unit $(MODULE)
	@-touch $(MODULE).o
	@-touch $(MODULE).import.scm

clean:
	@-rm -f $(EXE) *.o *.import.scm *.link

