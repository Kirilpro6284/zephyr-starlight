#ifndef INCLUDE_CHECKER
    #define INCLUDE_CHECKER

    ivec2 checker2x2 (int i) 
    {
        return ivec2(i, (i + 1) >> 1) & ivec2(1);
    }

    ivec2 checker4x4 (int i) 
    {
        return checker2x2(i) * 2 + checker2x2(i >> 2);
    }

    ivec2 checker8x8 (int i) 
    {
        return checker4x4(i) * 2 + checker2x2(i >> 4);
    }

#endif