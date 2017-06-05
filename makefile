NAME = codeb

all: $(NAME)

$(NAME): $(NAME).o lex.o $(NAME)_iburg.o
	gcc --std=gnu99 -o $(NAME) $(NAME).o lex.o $(NAME)_iburg.o

lex.yy.c: oxout.l oxout.tab.h
	flex oxout.l

lex.o: lex.yy.c oxout.tab.h
	gcc -c --std=gnu99 -o lex.o lex.yy.c

oxout.tab.c oxout.tab.h: oxout.y
	bison -v -d oxout.y

oxout.y oxout.l: $(NAME).y $(NAME).l
	ox $(NAME).y $(NAME).l

$(NAME)_iburg.c: $(NAME).bfe
	bfe < $(NAME).bfe | iburg > $(NAME)_iburg.c

$(NAME)_iburg.o: $(NAME)_iburg.c $(NAME).h
	gcc -std=gnu99 -c -DUSE_IBURG -DBURM -o $(NAME)_iburg.o $(NAME)_iburg.c

$(NAME).o: oxout.tab.c $(NAME).h
	gcc -std=gnu99 -c -DUSE_IBURG -o $(NAME).o oxout.tab.c

.PHONY: clean
clean:
	rm -f oxout.l oxout.y lex.yy.c oxout.tab.c oxout.tab.h  oxout.output $(NAME)_iburg.c $(NAME)_iburg.o $(NAME).o $(NAME) lex.o
