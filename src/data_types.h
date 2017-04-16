#ifdef DATA_TYPES_H
#error Already included.
#else

#define DATA_TYPES_H

typedef unsigned char u8;
typedef unsigned short int u16;

typedef char Check_u8[sizeof(u8) == 1 ? 1: -1];
typedef char Check_u16[sizeof(u16) == 2 ? 1: -1];

#endif

