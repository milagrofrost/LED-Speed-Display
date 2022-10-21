/*
  MAX7219 7-segment LED Module test

  This program is used to test ProtoSupplies.com 7-Segment display modules
  and also provides a good starting point for using these displays in a system

  To allow the same baseboard to support 3, 4 or 5 digit displays, the left-most
  digit is considered digit 0 which is the opposite of how most software is
  setup.

  This program does the following:
  - Writes 8's to all connected displays, then moves a decimal point across all.
  - Displays all 9's to all 1's on all displays.
  - Continually counts up on the 1st display 0-999, 0-9999 or 0-99999 then loops.
  - If a 2nd display is connected, it is used to show the loop count.

  Based on the LedControl library that can be installed from the IDE library manager

  The subroutine DspNumber is where the magic happens
*/
#include "LedControl.h"

// For errors with LedControl.  This works without issue for Arduinos.  For ESP32/ESP8266 you'll need to modify your local copy
// of the LedControl library and replace the line "#include <avr/pgmspace.h>" with:

// #if defined(AVR)
// #include <avr/pgmspace.h>
// #else  //defined(AVR)
// #include <pgmspace.h>
// #endif  //defined(AVR)

// https://forum.arduino.cc/t/fatal-error-avr-pgmspace-h-no-such-file-or-directory-error-for-esp8266/538262/4


// Our example assumes we have two 4-digit displays connected

// Define pins for LedControl. These can be any digital pins on microcontroller.
// LedControl(DataIn, Clk, Load/CS, # of MAX7219 in chain)
LedControl lc = LedControl(23, 18, 5, 19);
const int LEDSIZE = 3;  // # digits in LED modules we are using

String inString = "";
bool connected = false;
bool brightness = false;
int timeout = 0;

int dispToggle = 0;
int currentToggle = 100;

String lockState = "UNLCK";
String currentState = "UNLCK";

String readTurbo = "notrbo";
String currentTrbo = "notrbo";

const uint8_t switch1 = 12;
const uint8_t led1 = 32;

const uint8_t switch2 = 16;
const uint8_t led2 = 17;

const uint8_t switch3 = 27;

#define DEBOUNCE_TIME  750
volatile unsigned long button_press_timestamp = 0;

struct ledSequence
{
  int pos;
  byte row;
};

ledSequence spinnySpinny[10]
{
  {0, B00001000},
  {0, B00000100},
  {0, B00000010},
  {0, B01000000},
  {1, B01000000},
  {2, B01000000},
  {2, B00100000},
  {2, B00010000},
  {2, B00001000},
  {1, B00001000}
};


/*===============================================================================
   Subroutine - DspNumber (number, dsp, pos, dp, dpPos)

   number = number to display
   dsp = display to write the number on in the MAX7219 chain (0-7)
   pos = position of first digit to write.  3 digits=2, 4 digit=3, 5 digit=4
   dp = boolean flag whether to show a decimal point
   dpPos = position to put the decimal point if there is one to show.

   Default argument values can be useful to minimize the number of arguments that
   need to be passed if items such as the decimal point or LED size do not change.
   If you always want one digit to right of decimal point change dp=true, dpPos=1
   as an example
  =============================================================================== */
void DspNumber(long number, int dsp = 0, byte pos = LEDSIZE - 1,
               boolean dp = false, byte dpPos = 0, boolean autodecimal = true) {

  byte digit = number % 10;           // Get first digit on right

  //Serial.println(digit);

  if (dp && dpPos == pos && autodecimal == true)             // Check if DP needs to be displayed
    lc.setDigit(dsp, pos, digit, true); // Display digit with DP
  else
    lc.setDigit(dsp, pos, digit, false); // Display digit without DP

  //Serial.println(pos);

  long remainingDigits = number / 10; // Check if another digit to display
  if (remainingDigits > 0) {          // If there is, do it all again
    DspNumber(remainingDigits, dsp,  pos - 1, dp, dpPos, autodecimal);
  }
  else {
    if ( pos != 0 && autodecimal == true) {
      lc.setDigit(dsp, 0, 0, true);
    }

  }

}


void toggle() {

  if (millis() - button_press_timestamp > DEBOUNCE_TIME) {
    dispToggle++;
    digitalWrite(led2, HIGH);
    button_press_timestamp = millis();
  }

}


//===============================================================================
//  Initialization
//===============================================================================
void setup() {
  // Initialize all displays
  for (int dsp = 0; dsp < lc.getDeviceCount(); dsp++) {
    lc.setScanLimit(dsp, LEDSIZE); // Limit scan to size of LED module
    lc.shutdown(dsp, false); // Wakeup display
    lc.setIntensity(dsp, 8); // Set brightness to a lower level (1-15)
    lc.clearDisplay(dsp);   // Clear the display
  }

  pinMode(switch1, INPUT_PULLUP);
  pinMode(led1, OUTPUT);

  pinMode(led2, OUTPUT);
  pinMode(switch2, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(switch2), toggle, CHANGE);

  pinMode(switch3, INPUT_PULLUP);

  Serial.begin(115200);
  delay(100);

  //Serial.println("Type something!");
}
//===============================================================================
//  Main
//===============================================================================
void loop() {



  // Check to see if buttons are pressed
  int read1 = digitalRead(switch1);
  // Serial.println(read1);


  if (read1 == 1) {
    Serial.println("TURBO");
    digitalWrite(led1, HIGH);
    readTurbo = "turbo";

  } else {
    digitalWrite(led1, LOW);
    Serial.println("NoTRBO");
    readTurbo = "notrbo";
  }

  if (readTurbo != currentTrbo) {
    if (readTurbo == "turbo") {
      int x = 1;
      int structLength = (sizeof(spinnySpinny) / sizeof(spinnySpinny[0])) - 1;
      while ( x < 200 ) {
        for (int i = 0; i <= structLength; i++) {
          lc.clearDisplay(0);
          lc.setRow(0, spinnySpinny[i].pos, spinnySpinny[i].row);
          digitalWrite(led1, !digitalRead(led1));
          digitalWrite(led2, !digitalRead(led2));
          delay(20 / (x / 100.0));
          x++;
        }
        lc.clearDisplay(0);
        currentTrbo = readTurbo;
      }
    }
    if (readTurbo == "notrbo") {
      currentTrbo = readTurbo;
    }
  }


  // Check to see if buttons are pressed
  int read3 = digitalRead(switch3);
  // Serial.println(read3);



  if (read3 == 0) {
    Serial.println("LOCK");
    lockState = "LOCK";
  } else {
    Serial.println("UNLCK");
    lockState = "UNLCK";
  }

  if (currentState != lockState ) {
    if (lockState == "LOCK") {
      lc.setChar(0, 0, 'L', false);
      lc.setRow(0, 1, B00011101);
      lc.setChar(0, 2, 'C', false);
      delay(1000);
    }
    if (lockState == "UNLCK") {
      lc.setRow(0, 0, B00011100);
      lc.setRow(0, 1, B00010101);
      lc.setChar(0, 2, 'L', false);
      delay(1000);
    }
    currentState = lockState;
  }

  if (dispToggle > 3) {
    dispToggle = 0;
  }

  //Serial.println(dispToggle);

  if (currentToggle != dispToggle ) {
    if ( dispToggle == 0 ) {
      Serial.println("CPU");
      lc.setChar(0, 0, 'C', false);
      lc.setChar(0, 1, 'P', false);
      lc.setRow(0, 2, B00011100);
      currentToggle = dispToggle;
    }
    if ( dispToggle == 1 ) {
      Serial.println("GPU");
      lc.setRow(0, 0, B1111011);
      lc.setChar(0, 1, 'P', false);
      lc.setRow(0, 2, B00011100);
      currentToggle = dispToggle;
    }
    if ( dispToggle == 2 ) {
      Serial.println("NET");
      lc.setRow(0, 0, B00010101);
      lc.setChar(0, 1, 'E', false);
      lc.setRow(0, 2, B00000111);
      currentToggle = dispToggle;
    }
    if ( dispToggle == 3 ) {
      Serial.println("RAM");
      lc.setRow(0, 0, B00000101);
      lc.setChar(0, 1, 'A', false);
      lc.setDigit(0, 2, 3, false);
      currentToggle = dispToggle;
    }
    delay(1000);
    digitalWrite(led2, LOW);
    lc.clearDisplay(0);
  }


  if ( dispToggle == 0 ) {
    Serial.println("CPU");
  }
  if ( dispToggle == 1 ) {
    Serial.println("GPU");
  }
  if ( dispToggle == 2 ) {
    Serial.println("NET");
  }
  if ( dispToggle == 3 ) {
    Serial.println("RAM");
  }

  int inChar = Serial.read();
  if (inChar == 'b') {
    brightness = true;
  }
  if (isDigit(inChar)) {
    // convert the incoming byte to a char and add it to the string:
    inString += (char)inChar;
  }
  // if you get a newline, print the string, then the string's value:
  if (inChar == '\n') {
    //Serial.print("Value:");
    //Serial.println(inString.toInt());
    if (brightness) {
      //Serial.println("Setting Brightness...");
      lc.setIntensity(0, inString.toInt());
      brightness = false;
    }


    if (inString != "") {
      lc.clearDisplay(0);
      Serial.print("Sending to display: ");
      Serial.println(inString);
      if ( dispToggle == 0 ) {
        DspNumber (inString.toInt(), 0, 2, true, 0, true);
      }
      else {
        DspNumber (inString.toInt(), 0, 2, true, 0, false);
      }
      timeout = 0;
    }

    // clear the string for new input:
    inString = "";

  }

  if (timeout > 100) {
    DspNumber (888, 0, 2, true, 0, true);
    delay (100);
    DspNumber (888, 0, 2, true, 1, true);
    delay (100);
    DspNumber (888, 0, 2, true, 2, true);
    delay (100);
    timeout = 101;
  }
  else {
    delay(100);
  }

  timeout++;

}
