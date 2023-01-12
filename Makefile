
TARGETS=bmp2mpp mpp2bmp

AS=vasmm68k_mot
LD=vlink
ASOPT=-quiet -m68000 -Fvobj
LDOPT=-bataritos -s
CC=gcc
CFLAGS=-O3 -g -Wall
LDLIBS=-lm
CXXFLAGS=-O3 -g -Wall

all: $(TARGETS)

clean:
	rm -f $(TARGETS) bmp2mpp out.bin *.bgz include.s *.o

bmp2mpp: bmp2mpp.o

mpp2bmp: mpp2bmp.o pixbuf.o

spec.o: spec.s #out.bin

colors.o: colors.s ../lib/lib_tos.s

mppview.o: mppview.s mode0.s mode1.s mode2.s mode3.s

out.bin: bmp2mpp
	./bmp2mpp -1 images/test_11.bmp out.bin

%.tos: %.o
	$(LD) $(LDOPT) $^ -o $@

%_emb.o: %.s
	/bin/echo -e "\t.include \"../lib/lib_emb.s\"" > include.s
	$(AS) $(ASOPT) $< -o $@

%.bin: %_emb.o
	$(LD) $(LDOPT) $^ -o $@
	../../tools/stripper $@ && mv out.tos $@
	../../tools/reloc -b $@ `grep mod_org ../lib/config.s|sed 's/.*,//'`

%.gz: %
	7z a -mx=9 $@ $^

%.bgz: %.bin.gz
	../../../tests/packing/gunzip $^ && mv out.bgz $@
	rm out.bin

%.o: %.s
	/bin/echo -e "\t.include \"../lib/lib_tos.s\"" > include.s
	$(AS) $(ASOPT) $< -o $@
