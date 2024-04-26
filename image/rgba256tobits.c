#include <stdint.h>
#include <stdio.h>

typedef union {
    uint32_t    pixel;
    uint8_t     component[4];
} Color;

Color colors[256];
int num_colors = 0;

int main(int argc, const char** argv) {
    if (argc != 3) {
        printf("Use: rgba16tobits.c <inputfilepath> <outputfilepath>\r\n");
        return -3;
    }

    printf("Converting %s to %s\r\n", argv[1], argv[2]);
    FILE* fin = fopen(argv[1], "rb");
    if (fin) {
        FILE* fout = fopen(argv[2], "wb");
        if (fout) {
            Color color[2];
            while (fread(&color, sizeof(Color), 2, fin) == 2) {
                uint8_t found = 0;

                uint8_t c0 = 0;
                for (int i = 0; i < num_colors; i++) {
                    if (colors[i].pixel == color[0].pixel) {
                        c0 = i;
                        found = 1;
                        break;
                    }
                }
                if (!found) {
                    if (num_colors >= 256) {
                        printf("Too many colors!\n");
                        return -4;
                    }
                    c0 = num_colors;
                    colors[num_colors++].pixel = color[0].pixel;
                }

                found = 0;
                uint8_t c1 = 0;
                for (int i = 0; i < num_colors; i++) {
                    if (colors[i].pixel == color[1].pixel) {
                        c1 = i;
                        found = 1;
                        break;
                    }
                }
                if (!found) {
                    if (num_colors >= 256) {
                        printf("Too many colors!\n");
                        return -4;
                    }
                    c1 = num_colors;
                    colors[num_colors++].pixel = color[1].pixel;
                }

                fprintf(fout, "%02X %02X\n", c0, c1);
            }
            fclose(fout);
            fclose(fin);

            for (int i = 0; i < num_colors; i++) {
                printf("%X%X%X\n",
                    colors[i].component[0] >> 4,
                    colors[i].component[1] >> 4,
                    colors[i].component[2] >> 4);
            }
            return 0;
        } else {
            fclose(fin);
            printf("Cannot open %s", argv[2]);
            return -2;
        }
    } else {
        printf("Cannot open %s", argv[1]);
        return -1;
    }
}