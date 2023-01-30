// Control code for the Prizmatix LED box
//
//
// maxVal:                  Int. The maximum setting value for any LED (4095)
// settingsMatrix:          8 x n matrix of ints, all between 0 and maxVal.
//                          Each column defines the settings on the 8 LEDs at
//                          each of n levels of the modulation.
// waveform:                r x 1 integer vector, where each value is between
//                          0 and n-1. As we step through time points, the
//                          waveform defines the profile of the cycle. A typical
//                          option would be for the waveform to define a
//                          sinusoidal transition between settings.
//
//

// package to write to the LEDs
#include <Wire.h>

// Determine if we are connected to an Arduino Uno, in which case we should
// set simulation mode to true
bool simulatePrizmatix = false;     // Simulate the prizmatix LEDs
const int nLEDs = 8;                // number of LEDs defining the number of rows of the settings matrix.
const int nLevels = 10;             // the number of modulation levels that are specified for each LED
const int minLEDAddressTime = 360;  // the time, in microseconds, that it takes to refresh an LED setting

// Global variables
int maxVal = 4095;             // maximum setting value for the prizmatix LEDs
String inputString = "";       // a String to hold incoming data
bool stringComplete = false;   // whether the string is complete
bool configMode = false;       // stay in setup mode until commanded otherwise
bool modulationState = false;  // When we are running, are we modulating?

int waveform = 1;  // sinusoid


// Define default waveform and settings
// if (simulatePrizmatix) {
//   int settings[1][2] = {
//     { maxVal, 0 },  //LED0
//   };
//   int nCycleSteps = 100;
//   int waveform[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 };
//   int background[] = { 0 };
//   bool ledIsActive[] = { true };
// } else {
int settings[8][10] = {
  { 0, 455, 910, 1365, 1820, 2275, 2730, 3185, 3640, 4095 },  //LED0
  { 0, 455, 910, 1365, 1820, 2275, 2730, 3185, 3640, 4095 },  //LED0
  { 0, 455, 910, 1365, 1820, 2275, 2730, 3185, 3640, 4095 },  //LED0
  { 0, 455, 910, 1365, 1820, 2275, 2730, 3185, 3640, 4095 },  //LED0
  { 0, 455, 910, 1365, 1820, 2275, 2730, 3185, 3640, 4095 },  //LED0
  { 0, 455, 910, 1365, 1820, 2275, 2730, 3185, 3640, 4095 },  //LED0
  { 0, 455, 910, 1365, 1820, 2275, 2730, 3185, 3640, 4095 },  //LED0
  { 0, 455, 910, 1365, 1820, 2275, 2730, 3185, 3640, 4095 },  //LED0
};
int background[] = {
  2048,
  2048,
  2048,
  2048,
  2048,
  2048,
  2048,
  2048,
};
bool ledIsActive[] = { true, true, true, true, true, true, true, true };
// }

// timing variables
unsigned long cycleDur = 1e6 / 3;  // initialize at 3 Hz
unsigned long modulationStartTime = micros();
unsigned long lastLEDUpdateTime = micros();
int cycleLED = 0;

// setup
void setup() {

  // Initialize serial port communication
  Serial.begin(57600);

  // Set up the built-in LED if we are simulating
  if (simulatePrizmatix) {
    pinMode(LED_BUILTIN, OUTPUT);
  } else {
    Wire.begin();
    Wire.setClock(400000);
  }
  // Check which LEDs are "active"
  checkLEDActive();

  // Set the device to background
  setToBackground();

  // Announce we are starting
  Serial.println("== run mode");
}

void loop() {

  // If configMode, go wait for the next input
  if (configMode) {
    getConfig();
    return;
  }

  // We are in run mode. Poll the serial port, and cycle the LED settings
  pollSerialPort();
  if (stringComplete) {
    stringComplete = false;
    if (inputString.indexOf("go") >= 0) {
      Serial.println("go");
      modulationState = true;
      lastLEDUpdateTime = micros();
      modulationStartTime = micros();
    }
    if (inputString.indexOf("stop") >= 0) {
      setToBackground();
      Serial.println("stop");
      modulationState = false;
    }
    if (inputString.indexOf("off") >= 0) {
      setToOff();
      Serial.println("off");
      modulationState = false;
    }
    if (inputString.indexOf("background") >= 0) {
      setToBackground();
      Serial.println("background");
      modulationState = false;
    }
    if (inputString.indexOf("config") >= 0) {
      Serial.println("== config mode");
      modulationState = false;
      configMode = true;
    }
    inputString = "";
  }

  // Advance the LED settings
  if (modulationState) {
    unsigned long currentTime = micros();
    if ((currentTime - lastLEDUpdateTime) > minLEDAddressTime) {
      // Determine where we are in the cycle
      unsigned long cycleTime = ((currentTime - modulationStartTime) % cycleDur);
      double cyclePhase = double(cycleTime) / double(cycleDur);
      // update the lastTime
      lastLEDUpdateTime = currentTime;
      // send the newLED settings
      updateLED(cyclePhase, cycleLED);
      // advance the cycleLED
      cycleLED++;
      cycleLED = cycleLED % nLEDs;
    }
  }
}

void getConfig() {
  waitForNewString();
  stringComplete = false;
  if (inputString.indexOf("run") >= 0) {
    Serial.println("== run mode");
    configMode = false;
    modulationState = false;
  }
  if (inputString.indexOf("wave") >= 0) {
    inputString = "";
    Serial.print("wave type: ");
    waitForNewString();
    waveform = inputString.toInt();
    if (waveform == 1) Serial.println("sin");
    if (waveform == 2) Serial.println("saw on");
    if (waveform == 3) Serial.println("saw off");
  }
  if (inputString.indexOf("freq") >= 0) {
    inputString = "";
    Serial.print("frequency in Hz: ");
    waitForNewString();
    Serial.print(inputString);
    cycleDur = 1e6 / inputString.toFloat();
  }
  if (inputString.indexOf("led") >= 0) {
    String ledString = inputString.substring(inputString.length() - 2);
    inputString = "";
    int ledIndex = ledString.toInt();
    Serial.print("Settings for LED");
    Serial.print(ledIndex);
    Serial.print(":");
    waitForNewString();
    updateSettingsMatrix(settings, ledIndex, inputString);
    checkLEDActive();
  }
  if (inputString.indexOf("print") >= 0) {
    printCurrentSettings();
  }
  inputString = "";
}

void pollSerialPort() {
  while (Serial.available()) {
    // get the new byte:
    char inChar = (char)Serial.read();
    // add it to the inputString:
    inputString += inChar;
    // if the incoming character is a newline, set a flag so the main loop can
    // do something about it:
    if (inChar == '\n') {
      stringComplete = true;
    }
  }
}

void waitForNewString() {
  bool stillWaiting = true;
  while (stillWaiting) {
    while (Serial.available()) {
      // get the new byte:
      char inChar = (char)Serial.read();
      // add it to the inputString:
      inputString += inChar;
      // if the incoming character is a newline, set a flag so the main loop can
      // do something about it:
      if (inChar == '\n') {
        stringComplete = true;
        stillWaiting = false;
      }
    }
  }
}

void checkLEDActive() {
  // Identify those LEDs that never differ from the background and
  // remove them from the active list
  int nActiveLEDs = 0;

  for (int ii = 0; ii < nLEDs; ii++) {
    int levelIdx = 0;
    bool anyDiff = false;
    bool stillChecking = true;
    while (stillChecking) {
      if (settings[ii][levelIdx] != background[ii]) {
        anyDiff = true;
        stillChecking = false;
      } else {
        levelIdx++;
        if (levelIdx == nLevels) {
          stillChecking = false;
        }
      }
    }
    if (anyDiff) {
      ledIsActive[ii] = true;
      nActiveLEDs++;
    } else {
      ledIsActive[ii] = false;
    }
  }
}

int updateSettingsMatrix(int settings[nLEDs][nLevels], int selectedRow, String inputString) {
  // This function updates settings matrix by accepting a string, converting it to array and
  // appending to settingsMatrix
  inputString += ',';        // Add a comma at the end of the input string to make life easier
  String vectorString = "";  // Set a vector string which will be appended with chars
  int numberOfCommas = -1;   // Comma counter, zero indexed language, so start from -1

  // Loop through input string. if not comma, append to vectorString
  // If comma, assign the completed vectorString to a vector index.
  for (int i = 0; i < inputString.length(); i++) {
    char c = inputString[i];
    if (c != ',') {
      vectorString += c;
    } else {
      numberOfCommas += 1;
      settings[selectedRow][numberOfCommas] = vectorString.toInt();
      vectorString = "";
    }
  }

  return settings[nLEDs][nLevels];
}

void setToBackground() {
  if (simulatePrizmatix) {
    // Use the built in arduino LED, which has a binary state
    int ledSetting = background[0];
    if (ledSetting > (maxVal / 2)) {
      digitalWrite(LED_BUILTIN, HIGH);
    } else {
      digitalWrite(LED_BUILTIN, LOW);
    }
  } else {
    for (int ii = 0; ii < nLEDs; ii++) {
      // Get the setting for this LED
      int ledSetting = background[ii];
      writeToOneCombiLED(ledSetting, ii);
    }
  }
}

void setToOff() {
  if (simulatePrizmatix) {
    // Use the built in arduino LED, which has a binary state
    digitalWrite(LED_BUILTIN, LOW);
  } else {
    for (int ii = 0; ii < nLEDs; ii++) {
      // Get the setting for this LED
      writeToOneCombiLED(0, ii);
    }
  }
}

void updateLED(double cyclePhase, int cycleLED) {
  if (ledIsActive[cycleLED]) {
    // Get the level for this LED, based upon waveform
    int ledLevel = 0;
    if (waveform == 1) ledLevel = (nLevels - 1) * ((sin(2 * 3.1415925 * cyclePhase) + 1) / 2); // sin
    if (waveform == 2) ledLevel = (nLevels - 1) * cyclePhase; // saw on
    if (waveform == 3) ledLevel = (nLevels - 1) - ((nLevels - 1) * cyclePhase); // saw off
    int ledSetting = settings[cycleLED][ledLevel];
    //    int ledSetting = settings[cycleLED][waveform[cycleIndex]];
    if (simulatePrizmatix) {
      // Use the built in arduino LED, which has a binary state
      if (ledSetting > (maxVal / 2)) {
        digitalWrite(LED_BUILTIN, HIGH);
      } else {
        digitalWrite(LED_BUILTIN, LOW);
      }
    } else {
      writeToOneCombiLED(ledSetting, cycleLED);
    }
  }
}

void writeToOneCombiLED(int level, int ledIndex) {
  Wire.beginTransmission(0x70);
  Wire.write(1 << ledIndex);
  Wire.endTransmission();
  Wire.beginTransmission(0x61);
  Wire.write(0b01011000);
  Wire.write((uint8_t)(highByte(level << 4)));
  Wire.write((uint8_t)(lowByte(level << 4)));
  Wire.endTransmission(1);
}

void printCurrentSettings() {
  int numRows = sizeof(settings) / sizeof(settings[0]);
  int numCols = sizeof(settings[0]) / sizeof(settings[0][0]);
  for (int r = 0; r < numRows; r++) {
    Serial.print("\n");
    for (int c = 0; c < numCols; c++) {
      Serial.print(settings[r][c]);
      Serial.print(" ");
    }
  }
  Serial.print("\n");
}
