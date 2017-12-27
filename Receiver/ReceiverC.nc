#include <Timer.h>
#include "Receiver.h"
#include "printf.h"

module ReceiverC {
  uses interface Boot;
  uses interface Leds;
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface Receive;
  uses interface SplitControl as AMControl;
}
implementation {
  AckMsg ack;
  message_t sendPkt;

  bool busy;

  event void Boot.booted() {
    busy = FALSE;
	  call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {}
    else { call AMControl.start();}
  }

  event void AMControl.stopDone(error_t err) {}

  event void AMSend.sendDone(message_t* msg, error_t err) {
    if (err == SUCCESS) { call Leds.led1Toggle(); }   // sent successfully
    else { call Leds.led0Toggle(); }
    busy = FALSE;
  }

  bool checkPacket(AnswerMsg* packet) {
    // printf("max = %ld\nmin = %ld\nsum = %ld\naverage = %ld\nmedian = %ld\n",
            // packet->max, packet->min, packet->sum, packet->average, packet->median);
    if (packet->max == ANS_MSG_MAX && packet->min == ANS_MSG_MIN
        && packet->sum == ANS_MSG_SUM && packet->average == ANS_MSG_AVERAGE
        && packet->median == ANS_MSG_MEDIAN) {
        return TRUE;
      } else {
        return FALSE;
      }
  }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
    if (len == sizeof(AnswerMsg)) {
      AnswerMsg* packet = (AnswerMsg*)payload;
      call Leds.led2Toggle();     // received

      if (checkPacket(packet)) {
        printf("Correct result!");
      } else {
        printf("Wrong result...");
      }

      if (!busy) {
        ack.group_id = packet->group_id;
        memcpy(call AMSend.getPayload(&sendPkt, sizeof(AckMsg)), &ack, sizeof ack);
        if (call AMSend.send(AM_BROADCAST_ADDR, &sendPkt, sizeof ack) == SUCCESS) {
          busy = TRUE;
        }
      }
      if (!busy) { call Leds.led0Toggle(); }     // error
    }
    return msg;
  }
}
