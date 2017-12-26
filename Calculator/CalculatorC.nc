// $Id: BlinkToRadioC.nc,v 1.5 2007/09/13 23:10:23 scipio Exp $

/*
 * "Copyright (c) 2000-2006 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/**
 * Implementation of the BlinkToRadio application.  A counter is
 * incremented and a radio message is sent whenever a timer fires.
 * Whenever a radio message is received, the three least significant
 * bits of the counter in the message payload are displayed on the
 * LEDs.  Program two motes with this application.  As long as they
 * are both within range of each other, the LEDs on both will keep
 * changing.  If the LEDs on one (or both) of the nodes stops changing
 * and hold steady, then that node is no longer receiving any messages
 * from the other node.
 *
 * @author Prabal Dutta
 * @date   Feb 1, 2006
 */
#include <Timer.h>
#include "Msg.h"

module CalculatorC {
  uses {
    interface Boot;
    
    interface Timer<TMilli> as Timer;
    interface SplitControl as AMControl;
    
    interface AMSend;
    interface Receive;
    interface Packet;
    interface AMPacket;

    interface Leds;
  }
}
implementation {
  uint32_t integers[INTEGER_NUM];
  uint8_t received[INTEGER_NUM / 8 + 1];
  uint16_t receivedNum;
  bool isAllReceived, isAcked;
  
  bool busy;
  message_t answerPkt;
  AnswerMsg answerMsg;

  bool isReceived(uint16_t index);
  void setReceived(uint16_t index);
  void receiveAndSort(DataMsg *dataMsg);
  void calculate();
  
  task void sendAnswer();
 
  event void Boot.booted() {   
    receivedNum = 0;
    isAllReceived = FALSE;
    isAcked = FALSE;
    busy = TRUE;
    
    call AMControl.start();
    call Timer.startPeriodic(20);
  }

  event void AMControl.startDone(error_t error) {
    if (error == SUCCESS) {
      busy = FALSE;
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t error) {
  }

  event void Timer.fired() {
    if (isAllReceived) {
      call Timer.stop();
      return;
    }
  }

  event void AMSend.sendDone(message_t* msg, error_t err) {
    if (&answerPkt == msg) {
      busy = FALSE;
    }
  }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
    am_addr_t id;
    DataMsg *dataPayload;
    AckMsg *ackPayload;
    
    id = call AMPacket.source(msg);
    if (len == sizeof(DataMsg)) {
      if (id != SOURCE_ID && id != HELPER_ID_1 && id != HELPER_ID_2) {
        return msg;
      }
      dataPayload = (DataMsg *)payload;
      receiveAndSort(dataPayload);
      
      if (isAllReceived && !isAcked) {
        call Leds.led0Toggle();
        calculate();       
        post sendAnswer();
      }
    }
    else if (len == sizeof(AckMsg)) {
      ackPayload = (AckMsg *)payload;
      if (ackPayload->group_id == GROUP_ID) {
        call Leds.led1Toggle();
        isAcked = TRUE;
        printf("ACK OH YEAH\n");
        printfflush();
      }
    }
    return msg;
  }
  
  bool isReceived(uint16_t index) {
    return (*(received + index/8) & (1 << (7-index%8))) != 0;
  }
  
  void setReceived(uint16_t index) {
    *(received + index/8) |= (1 << (7-index%8));
  }
  
  void receiveAndSort(DataMsg *dataMsg) {
    uint16_t i;
    if (isReceived(dataMsg->sequence_number-1)) {
      return;
    }
    for (i = 0; i < receivedNum; i++)
        if (*(integers+i) > dataMsg->random_integer)
            break;
    memmove(integers+i+1, integers+i, (receivedNum-i)*sizeof(uint32_t));    
    setReceived(dataMsg->sequence_number-1);
    *(integers + i) = dataMsg->random_integer;   
    receivedNum++;
    if (receivedNum == INTEGER_NUM) {
      isAllReceived = TRUE;
    }
  }
  
  void calculate() {
    uint16_t i;  
    answerMsg.group_id = GROUP_ID;
    
    answerMsg.max = *(integers + INTEGER_NUM - 1);
    answerMsg.min = *integers;   
    answerMsg.sum = 0;
    for (i = 0; i < INTEGER_NUM; ++i)
        answerMsg.sum += *(integers + i);
    answerMsg.average = answerMsg.sum / INTEGER_NUM;   
    answerMsg.median = (integers[INTEGER_NUM/2] + integers[INTEGER_NUM/2-1]) / 2;
    
    printf("max=%ld, min=%ld, sum=%ld, average=%ld, median=%ld\n",
                        answerMsg.max, answerMsg.min, answerMsg.sum, answerMsg.average,
                        answerMsg.median);
    printfflush();
    
    memcpy(call AMSend.getPayload(&answerPkt, sizeof(AnswerMsg)), &answerMsg, sizeof(AnswerMsg));
  }
  
  task void sendAnswer() {    
    if (!busy) {
      if (call AMSend.send(AM_BROADCAST_ADDR, &answerPkt, sizeof(AnswerMsg)) == SUCCESS) {
        busy = TRUE;
      }
      else {
        post sendAnswer();
      }
    }
    else {
      post sendAnswer();
    }   
  }
  
}
