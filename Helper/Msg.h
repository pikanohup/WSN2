#ifndef MSG_H
#define MSG_H

enum {
    ARRAY_SIZE = 2000,
    GROUP_ID = 17,
    AM_BLINKTORADIO = 0,
    SOURCE_ID = 1000,
    MY_CAL = 49
};

typedef nx_struct DataMsg {
    nx_uint16_t sequence_number;
    nx_uint32_t random_integer;
} DataMsg;

#endif