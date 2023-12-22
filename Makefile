
TARGETS=bmp2mpp mpp2bmp mppview.tos

AS=vasmm68k_mot
ASOPT=-quiet -m68000 -Ftos
CC=gcc
CFLAGS=-O3 -g -Wall
LDLIBS=-lm
CXXFLAGS=-O3 -g -Wall

all: $(TARGETS)

clean:
	rm -f $(TARGETS) *.o

bmp2mpp: bmp2mpp.o

mpp2bmp: mpp2bmp.o pixbuf.o

spec.o: spec.s #out.bin

mppview.tos: mppview.s mode0.s mode1.s mode2.s mode3.s

%.tos: %.s
	$(AS) $(ASOPT) $< -o $@

