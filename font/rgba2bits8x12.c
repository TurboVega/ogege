#include <stdio.h>

#define _COMPILE_HEX_DATA_
#define __root /**/
#include "font8x12.h"

#define INPUT_BYTES_PER_PIXEL   4
#define INPUT_COLUMNS           16
#define INPUT_ROWS              6
#define CHAR_WIDTH              8
#define INPUT_CHAR_HEIGHT       16
#define CHAR_HEIGHT             12
#define BYTES_PER_INPUT_COLUMN  (CHAR_WIDTH*INPUT_BYTES_PER_PIXEL)
#define BYTES_PER_INPUT_LINE    (INPUT_COLUMNS*BYTES_PER_INPUT_COLUMN)
#define BYTES_PER_INPUT_ROW     (BYTES_PER_INPUT_LINE*INPUT_CHAR_HEIGHT)

int main() {
    for (int srow=0; srow<CHAR_HEIGHT; srow++) {
        for (int i=0; i<CHAR_WIDTH*32; i++) {
            printf("000\n");
        }
        for (int row=0; row<INPUT_ROWS; row++) {
            for (int col=0; col<INPUT_COLUMNS; col++) {
                for (int scol=0; scol<CHAR_WIDTH; scol++) {                
                    int index = (row*BYTES_PER_INPUT_ROW +
                        col*BYTES_PER_INPUT_COLUMN +
                        srow*BYTES_PER_INPUT_LINE +
                        scol*INPUT_BYTES_PER_PIXEL);

                    //printf("%i %i %i %i -> %i (%04X)\n",row,col,srow,scol,index,index);
                    const unsigned char* p = &gfont8x12_Data[index];

                    unsigned char in_alpha = p[3];
                    unsigned char out_alpha = (((unsigned short)in_alpha)*100)/255;
                    if (out_alpha >= 100)
                        printf("110\n"); // 100% opaque
                    else if (out_alpha >= 88)
                        printf("101\n"); // 75% opaque
                    else if (out_alpha >= 71)
                        printf("100\n"); // 67% opaque
                    else if (out_alpha >= 43)
                        printf("011\n"); // 50% opaque
                    else if (out_alpha >= 29)
                        printf("010\n"); // 33% opaque
                    else if (out_alpha >= 13)
                        printf("001\n"); // 25% opaque
                    else
                        printf("000\n"); // 0% opaque
                }
            }
        }
        for (int i=0; i<CHAR_WIDTH*128; i++) {
            printf("000\n");
        }
    }
}