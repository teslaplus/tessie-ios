/*

Copyright (c) 2015 Tesla Plus

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

#include <stdio.h>
#include <SPI.h>
#include <EEPROM.h>
#include <boards.h>
#include <RBL_nRF8001.h>

struct Command {
  byte action;
  unsigned char command[16] = {0};
  unsigned char length = 0;
 
  bool complete = false;
  void reset() {
    action = NULL;
    length = 0;
    complete = false;
    memset(command, 0, sizeof(command));
  }
  void invoke() {
    const char* argData = (const char*) command;
    int intArg = 10;
    if (length > 0) {
      intArg = atoi(argData);
    }
    switch (action) {
      case 'u': 
        Mouse.move(0, -intArg);
        break;
      case 'd':
        Mouse.move(0, intArg);
        break;
      case 'l':
        Mouse.move(-intArg, 0);
        break;
      case 'r':
        Mouse.move(intArg, 0);
        break;
      case 'c':
        Mouse.click(MOUSE_LEFT);
        break;
      case 'w':
        delay(intArg);
        Serial.println("Sleeping");
        break;
    }
  }
};

Command *command = new Command();

const byte PACKET_INIT = 1;
const byte PACKET_READ_ACTION = 2;
const byte PACKET_READ_ARGS = 3;

byte readState = PACKET_INIT;

void setup()
{
  // Set your BLE Shield name here, max. length 10
  ble_set_name("Tessie");

  // Init. and start BLE library.
  ble_begin();

  Mouse.begin();

  // Enable serial debug
  Serial.begin(57600);
}

int counter = 0;

void loop()
{
  // TODO handshake / auth
  if ( ble_available() )
  {
    digitalWrite(9, counter++ % 2 == 0 ? HIGH : LOW); 
    while ( ble_available() )
    {
      char inChar = ble_read();
      switch (readState) {
        case PACKET_INIT:
          if (inChar == '#') {
            readState = PACKET_READ_ACTION;
            command->reset();
          }
          break;
        case PACKET_READ_ACTION:
          if (inChar == '$') {
            readState = PACKET_INIT;
            command->complete = true;
            // TODO: Add command to executor list
            // TODO: Checksum
          } else {
            command->action = inChar;
            readState = PACKET_READ_ARGS;
          }
          break;
        case PACKET_READ_ARGS:
          if (inChar == '$') {
            readState = PACKET_INIT;
            command->complete = true;
            // TODO: Add command to executor list
            // TODO: Checksum
          } else {
            // add byte to command
            command->command[command->length++] = inChar;
          }
          break;
      }
    }
    
    if (command->complete) {
      command->invoke();
      delay(10);
      command->reset();
    }
  }

  ble_do_events();
}


