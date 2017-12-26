#ifndef RECEIVER_H
#define RECEIVER_H

enum {
    ANS_MSG_MAX = 4997,
    ANS_MSG_MIN = 4,
    ANS_MSG_SUM = 4999792,
    ANS_MSG_AVERAGE = 2499,
    ANS_MSG_MEDIAN = 2484,
    AM_ID = 0
}

typedef nx_struct AckMsg {
    nx_uint8_t group_id;
} AckMsg;

typedef nx_struct AnswerMsg {
    nx_uint8_t group_id;
    nx_uint32_t max;
    nx_uint32_t min;
    nx_uint32_t sum;
    nx_uint32_t average;
    nx_uint32_t median;
} AnswerMsg;

#endif
