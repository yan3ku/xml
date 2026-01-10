#
CC=gcc
LEX=flex

% : %.tab.o %.o
	$(CC) $< $*.o $(LDFLAGS) -o $@

%.tab.c %.tab.h: %.y
	bison -Wcounterexamples --debug -v -d $<

%.c: %.l %.tab.h
	$(LEX) --debug -t $< > $@

x: x.y x.l

clean:
	rm -f x lex.yy.c x.tab.c x.tab.h
