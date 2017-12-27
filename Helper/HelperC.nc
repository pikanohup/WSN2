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
#include "Timer.h"
#include "Msg.h"
#include "printf.h"

module HelperC {
  uses {
    interface Boot;
    interface SplitControl as AMControl;   
    interface AMSend;
    interface Receive;
    interface Packet;
    interface AMPacket;
    interface Leds;
  }
}
implementation {
  bool Busy = FALSE;
  nx_uint16_t cur_sequence_number;
  nx_uint32_t cur_random_integer;
  nx_uint32_t num;
  message_t help_packet;

  event void Boot.booted() {
    cur_sequence_number = 0;
    cur_random_integer = 0;
    num = 0;
    call AMControl.start();
  }

  event void AMControl.startDone(error_t error) {
    if(error == SUCCESS) {
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t error) {
  }

  event void AMSend.sendDone(message_t *msg, error_t error) {
      Busy = FALSE;
  }

  event message_t *Receive.receive(message_t *msg, void *payload, uint8_t len) {
    if(len == sizeof(DataMsg)) {
       DataMsg *response_packet;
       DataMsg *temp_packet = (DataMsg *)payload;
       cur_sequence_number = temp_packet -> sequence_number;
       cur_random_integer = temp_packet -> random_integer;
       response_packet = (DataMsg *)(call Packet.getPayload(&help_packet, sizeof(DataMsg)));
       response_packet -> sequence_number = cur_sequence_number;
       response_packet -> random_integer = cur_random_integer;
       if(Busy == FALSE) {
          if (call AMSend.send(AM_BROADCAST_ADDR, &help_packet, sizeof(DataMsg)) == SUCCESS) {
             Busy = TRUE;
          }
       } 
       call Leds.led2Toggle();
       printf("%d\n", cur_sequence_number);
       printfflush();
    }
    return msg;
  }
}
