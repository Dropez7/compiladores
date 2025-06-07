SCANNER := lex
SCANNER_PARAMS := src/lex.l
PARSER := yacc
PARSER_PARAMS := -d src/sin.y

all: compile translate clean

compile:
		$(SCANNER) $(SCANNER_PARAMS)
		$(PARSER) $(PARSER_PARAMS)
		g++ -o glf y.tab.c -ll

debug:	PARSER_PARAMS += -Wcounterexamples
debug: 	all

translate: glf
		./glf < example/exemplo.mpr

clean:
	rm y.tab.c
	rm y.tab.h
	rm lex.yy.c
	rm glf
	rm -f output.c
	rm -f output

execute:
	./glf < example/exemplo.mpr > output.c
	gcc -o output output.c
	./output

run: 	compile execute clean