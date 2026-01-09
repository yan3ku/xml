#
CC=gcc
LEX=flex

% : %.tab.o %.o
	$(CC) $< $*.o $(LDFLAGS) -o $@

%.tab.c %.tab.h: %.y
	bison --debug -v -d $<

%.c: %.l %.tab.h
	$(LEX) -t $< > $@

x: x.y x.l

clean:
	rm x x.tab.c x.tab.h
