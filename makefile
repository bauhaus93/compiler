NAME = gesamt
CFLAGS = --std=gnu99 -Wall
CFLAGSTOOLS = --std=gnu99

all: $(NAME)

$(NAME): $(NAME).o lex.o $(NAME)_iburg.o asmprint.o condition.o error.o globals.o reg.o symbol.o tree.o
	gcc $(CFLAGS) -o $(NAME) $(NAME).o lex.o $(NAME)_iburg.o asmprint.o condition.o error.o globals.o reg.o symbol.o tree.o

asmprint.o: asmprint.c
	gcc $(CFLAGS) -c -o asmprint.o asmprint.c

condition.o: condition.c
	gcc $(CFLAGS) -c -o condition.o condition.c

error.o: error.c
	gcc $(CFLAGS) -c -o error.o error.c

globals.o: globals.c
	gcc $(CFLAGS) -c -o globals.o globals.c

reg.o: reg.c
	gcc $(CFLAGS) -c -o reg.o reg.c

symbol.o: symbol.c
	gcc $(CFLAGS) -c -o symbol.o symbol.c

tree.o: tree.c
	gcc $(CFLAGS) -c -o tree.o tree.c

lex.yy.c: oxout.l oxout.tab.h
	flex oxout.l

lex.o: lex.yy.c oxout.tab.h
	gcc $(CFLAGSTOOLS) -c -o lex.o lex.yy.c

oxout.tab.c oxout.tab.h: oxout.y
	bison -v -d oxout.y

oxout.y oxout.l: $(NAME).y $(NAME).l
	ox $(NAME).y $(NAME).l

$(NAME)_iburg.c: $(NAME).bfe
	bfe < $(NAME).bfe | iburg > $(NAME)_iburg.c

$(NAME)_iburg.o: $(NAME)_iburg.c
	gcc $(CFLAGSTOOLS) -c -DUSE_IBURG -DBURM -o $(NAME)_iburg.o $(NAME)_iburg.c

$(NAME).o: oxout.tab.c
	gcc $(CFLAGSTOOLS) -c -DUSE_IBURG -o $(NAME).o oxout.tab.c

.PHONY: clean
clean:
	rm -f lex.yy.c $(NAME)_iburg.c $(NAME) oxout.* *.o
