CC = h5cc

all: nev2h5

nev2h5: dynamicarray.h dynamicarray.c nev2h5.c
	$(CC) -std=c99 -O2 nev2h5.c dynamicarray.c -o nev2h5
