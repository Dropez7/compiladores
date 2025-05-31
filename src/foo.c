#include <stdio.h>
#include <stdlib.h>

int main()
{
    char str[] = "12345678";
    // print size of the string
    int size = sizeof(str);
    printf("Size of the string: %d\n", size); // -1 to exclude the null terminator

    return 0;
}