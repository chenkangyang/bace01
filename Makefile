all:
	flex -o src/scanner.c src/scanner.l
	bison -d src/analyser.y
	gcc -g -o src/parser src/scanner.c src/analyser.tab.c -ll
	./src/parser < test/input.c--
