bison:
	cd src/ && bison -d analyser.y
	flex -o src/scanner.c src/scanner.l
	gcc -g -o src/parser src/*.c
	./src/parser < test/cacl.txt

lex:
	flex -o src/scanner.c src/scanner.l
	gcc -g -o src/parser src/scanner.c -ll
	./src/parser < test/input.c--

clean:
	rm src/*.c src/*.h