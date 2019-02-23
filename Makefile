EXE=flip-bits
MOD=board screen

TOP_SRC=$(EXE).scm
MOD_SRC=$(MOD:%.scm)
MOD_IMP=$(MOD:%=%.import.scm)
MOD_OBJ=$(MOD:%=%.o)

LINK_FLAGS=-L -lncurses

.PHONY: all clean

all: $(EXE)

$(EXE): $(TOP_SRC) $(MOD_IMP) $(MOD_OBJ)
	csc $(TOP_SRC) -static $(LINK_FLAGS) -o $(EXE)

%.import.scm : %.scm
	csc $< -c -J -unit $(basename $<)

clean:
	@-rm -f $(EXE) *.o *.import.scm *.link

