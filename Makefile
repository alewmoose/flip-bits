.PHONY: all clean

SRC=$(wildcard %.scm)
EXE=flip-bits

all: $(EXE)

$(EXE): $(SRC)
	csc -static -extend board.scm flip-bits.scm -o $@


clean:
	@-rm -f $(EXE) *.o *.link
