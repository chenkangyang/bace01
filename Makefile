bison:
	cd src/ && bison -d analyser.y
	flex -o src/scanner.c src/scanner.l
	gcc -g -o src/parser src/*.c
	./src/parser < test/input.c--

lex:
	flex -o src/scanner.c src/scanner.l
	gcc -g -o src/parser src/*.c -ll
	./src/parser < test/input.c--

clean:
	rm src/*.c

pair:
	flex -o src/testPair.c src/testPair.l
	gcc -g -o src/testPair src/testPair.c -ll
	./src/testPair < test/input.c--