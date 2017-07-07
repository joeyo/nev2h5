CC = h5cc

all: nev2h5

nev2h5: dynamicarray.h dynamicarray.c nev2h5.c
	$(CC) -Wattributes -std=c99 -O2 -o nev2h5 nev2h5.c dynamicarray.c

clean:
	rm -f *.o *.dot *.py *.pyc *.pm *.pdf
