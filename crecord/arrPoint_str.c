#include <stdio.h>
#include <string.h>

// Array of Pointers to Strings
// https://overiq.com/c-programming-101/array-of-pointers-to-strings-in-c/

int main() {
	char *sports[] = {
		"golf",
		"hockey",
		"football",
		"cricket",
		"shooting"

	};

	printf("sizeof sports=%ld\n", (sizeof(sports) / sizeof(sports[0])));
	int items = sizeof(sports) / sizeof(sports[0]);


	char *p;
	for (int i = 0; i<items;i++) {
		printf("str=%-10s addr=%p\n", sports[i], sports[i]);
		p = sports[i];
		for (int j = 0; j <=strlen(sports[i]); j++) {
			printf("char=%-12c addr=%p\n", *(p+j), p+j);
		}

	}
}

/*
> gcc arrPoint_str.c && ./a.out
sizeof sports=5
str=golf       addr=0x563c73955004
char=g            addr=0x563c73955004
char=o            addr=0x563c73955005
char=l            addr=0x563c73955006
char=f            addr=0x563c73955007
char=            addr=0x563c73955008
str=hockey     addr=0x563c73955009
char=h            addr=0x563c73955009
char=o            addr=0x563c7395500a
char=c            addr=0x563c7395500b
char=k            addr=0x563c7395500c
char=e            addr=0x563c7395500d
char=y            addr=0x563c7395500e
char=            addr=0x563c7395500f
str=football   addr=0x563c73955010
char=f            addr=0x563c73955010
char=o            addr=0x563c73955011
char=o            addr=0x563c73955012
char=t            addr=0x563c73955013
char=b            addr=0x563c73955014
char=a            addr=0x563c73955015
char=l            addr=0x563c73955016
char=l            addr=0x563c73955017
char=            addr=0x563c73955018
str=cricket    addr=0x563c73955019
char=c            addr=0x563c73955019
char=r            addr=0x563c7395501a
char=i            addr=0x563c7395501b
char=c            addr=0x563c7395501c
char=k            addr=0x563c7395501d
char=e            addr=0x563c7395501e
char=t            addr=0x563c7395501f
char=            addr=0x563c73955020
str=shooting   addr=0x563c73955021
char=s            addr=0x563c73955021
char=h            addr=0x563c73955022
char=o            addr=0x563c73955023
char=o            addr=0x563c73955024
char=t            addr=0x563c73955025
char=i            addr=0x563c73955026
char=n            addr=0x563c73955027
char=g            addr=0x563c73955028
char=            addr=0x563c73955029
*/