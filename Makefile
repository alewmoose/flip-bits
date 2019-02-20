.PHONY: all clean

EXE=flip-bits

all: $(EXE)

$(EXE): board.scm flip-bits.scm
	csc -static -extend board.scm flip-bits.scm -o $@

clean:
	@-rm -f $(EXE) *.o *.link
