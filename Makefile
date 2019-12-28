all:
	gcc -g -o src/parser src/scanner.c src/analyzer.tab.c
	./src/parser < test/input.c--

bison:
	cd src/ && bison -d analyzer.y

lex:
	flex -o src/scanner.c src/scanner.l

clean:
	rm src/*.c

pair:
	flex -o src/testPair.c src/testPair.l
	gcc -g -o src/testPair src/testPair.c -ll
	./src/testPair < test/input.c--