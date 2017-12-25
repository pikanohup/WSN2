#ifndef MSG_H
#define MSG_H

enum {
    INTEGER_NUM = 2000,
	AM_BLINKTORADIO = 0,
    GROUP_ID = 17,
    SOURCE_ID = 1000,
    DESTINATION_ID = 0
};

typedef nx_struct DataMsg {
    nx_uint16_t sequence_number;
	nx_uint32_t random_integer;
} DataMsg;

typedef nx_struct QueryMsg {
    nx_uint16_t sequence_number;
} QueryMsg;

typedef nx_struct AnswerMsg {
    nx_uint8_t group_id;
    nx_uint32_t max;
    nx_uint32_t min;
    nx_uint32_t sum;
    nx_uint32_t average;
    nx_uint32_t median;
} AnswerMsg;

typedef nx_struct AckMsg {
    nx_uint8_t group_id;
} AckMsg;

#endif
