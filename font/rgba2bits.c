#include <stdio.h>

#define _COMPILE_HEX_DATA_
#define __root /**/
#include "font8x8.h"
#include "font8x12.h"

int main() {
    // 8x8 characters
    printf("8x8\n");
    for (int i=0; i<32*8*8; i++) {
        printf("000\n");
    }
    int offset=0;
    for (int row=0; row<6; row++) {
        for (int col=0; col<16; col++) {
            for (int srow=0; srow<8; srow++) {
                for (int scol=0; scol<8; scol++) {
                    int index = (row*16*8*8*4 + col*8*4 + srow*16*8*4 + scol*4);
                    //printf("%i %i %i %i -> %i\n",row,col,srow,scol,index);
                    const unsigned char* p = &gfont8x8_Data[index];
                    if (p[0]==0x00 && p[1]==0x00 && p[2]==0x00)
                        printf("110\n"); // 100% opaque
                    else if (p[0]==0x00 && p[1]==0x00 && p[2]==0x65)
                        printf("100\n"); // 75% opaque
                    else if (p[0]==0x65 && p[1]==0x00 && p[2]==0x00)
                        printf("110\n"); // 75% opaque
                    else if (p[0]==0x65 && p[1]==0x00 && p[2]==0x65)
                        printf("011\n"); // 50% opaque
                    else if (p[0]==0xB6 && p[1]==0xFF && p[2]==0xB6)
                        printf("011\n"); // 50% opaque
                    else if (p[0]==0xB6 && p[1]==0xFF && p[2]==0xFF)
                        printf("001\n"); // 25% opaque
                    else if (p[0]==0xFF && p[1]==0xFF && p[2]==0xB6)
                        printf("001\n"); // 25% opaque
                    else if (p[0]==0xFF && p[1]==0xFF && p[2]==0xFF)
                        printf("000\n"); // 0% opaque
                    else
                        printf("%02hX %02hX %02hX ERROR\n", p[0], p[1], p[2]);
                }
            }
        }

        offset+=6*16*4;
    }
    for (int i=0; i<128*8*8; i++) {
        printf("000\n");
    }

    // 8x12 characters
    printf("8x12\n");
}