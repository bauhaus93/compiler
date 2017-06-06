#include <stdio.h>

extern long f(long);
extern long gcd(long, long);
extern long f2(long, long);
extern long f3(long);

int main(int argc, char** argv) {
	printf("****test****\n");
	printf("f(4):\t\t%5d == 24\n", f(4));
	printf("gcd(18, 42):\t%5d == 6\n", gcd(18, 42));
	printf("f2(0, 5):\t%5d == 2\n", f2(0, 5));
	printf("f2(-1, 2):\t%5d == 1\n", f2(-1, 2));
	printf("f2(-1, 5):\t%5d == 6\n", f2(-1, 5));
	printf("f3(-1):\t\t%5d == 1\n", f3(-1));
	printf("f3(0):\t\t%5d == 1\n", f3(0));
	printf("************\n");
}
