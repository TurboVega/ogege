#include <stdio.h>

static const char* lines[] = {
//00000000001111111111222222222233333333334444444444555555555566666666667777777777
//01234567890123456789012345678901234567890123456789012345678901234567890123456789
 "================================================================================", //00
 "                                                                                ", //01
 "                                                                                ", //02
 "                                                                                ", //03
 "                                                                                ", //04
 "                                                                                ", //05
 "                                                                                ", //06
 "                                                                                ", //07
 "                                                                                ", //08
 "                                                                                ", //09
 "                                                                                ", //10
 "                                                                                ", //11
 "                                                                                ", //12
 "                                                                                ", //13
 "            GGGG    A    TTTTT  EEEEE  M   M    A    TTTTT  EEEEE               ", //14
 "           G       A A     T    E      MM MM   A A     T    E                   ", //15
 "           G      A   A    T    E      M M M  A   A    T    E                   ", //16
 "           G  GG  AAAAA    T    EEEE   M   M  AAAAA    T    EEEE                ", //17
 "           G   G  A   A    T    E      M   M  A   A    T    E                   ", //18
 "           G   G  A   A    T    E      M   M  A   A    T    E                   ", //19
 "            GGGG  A   A    T    EEEEE  M   M  A   A    T    EEEEE               ", //20
 "                                                                                ", //21
 "                                                                                ", //22
 "                                                                                ", //23
 "                     PPPP    SSS   RRRR     A    M   M                          ", //24
 "                     P   P  S   S  R   R   A A   MM MM                          ", //25
 "                     P   P  S      R   R  A   A  M M M                          ", //26
 "                     PPPP    SSS   RRRR   AAAAA  M   M                          ", //27
 "                     P          S  R   R  A   A  M   M                          ", //28
 "                     P      S   S  R   R  A   A  M   M                          ", //29
 "                     P       SSS   R   R  A   A  M   M                          ", //30
 "                                                                                ", //31
 "                                                                                ", //32
 "                                                                                ", //33
 "                        TTTTT  EEEEE   SSS   TTTTT                              ", //34
 "                          T    E      S   S    T                                ", //35
 "                          T    E      S        T                                ", //36
 "                          T    EEEE    SSS     T                                ", //37
 "                          T    E          S    T                                ", //38
 "                          T    E      S   S    T                                ", //39
 "                          T    EEEEE   SSS     T                                ", //40
 "                                                                                ", //41
 "                                                                                ", //42
 "                                                                                ", //43
 "                                                                                ", //44
 "                                                                                ", //45
 "                             Address: ????????                                  ", //46
 "                                                                                ", //47
 "                               Write:     ????                                  ", //48
 "                                                                                ", //49
 "                                Read:     ????                                  ", //50
 "                                                                                ", //51
 "                                                                                ", //52
 "                                                                                ", //53
 "                                                                                ", //54
 "                                                                                ", //55
 "                                                                                ", //56
 "                                                                                ", //57
 "                                                                                ", //58
 "================================================================================"  //59
//00000000001111111111222222222233333333334444444444555555555566666666667777777777
//01234567890123456789012345678901234567890123456789012345678901234567890123456789
};

int main() {
    for (int c = 0; c < 84; c++) {
        for (int r = 0; r < 64; r++) {
            unsigned char color = 0x20;
            unsigned char code = 0x20;
            if (c < 80 && r < 60) {
                code = lines[r][c];
                if (r >= 34 && r <= 40) color = 0x80;
                else if (c > 0 && code != ' ' && lines[r][c-1] == '/') color = 0xF0;
                else if (code == '?') color = 0xF0;
            }
            printf("%02hX%02hX\n", color, code);
        }
    }
    return 0;
}