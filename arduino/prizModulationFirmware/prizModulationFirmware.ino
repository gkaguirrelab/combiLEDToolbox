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

// Explicit definition of constants that define array sizes
const int nLEDs = 8;    // number of LEDs defining the number of rows of the settings matrix.
const int nLevels = 2;  // the number of modulation levels that are specified for each LED

// Global variables
int maxVal = 4095;              // maximum setting value for the prizmatix LEDs
String inputString = "";        // a String to hold incoming data
bool stringComplete = false;    // whether the string is complete
bool configMode = true;         // stay in setup mode until commanded otherwise
bool simulatePrizmatix = true;  // Simulate the prizmatix LEDs
bool modulationState = false;   // When we are running, are we modulating?

// Define default waveform and settings
int settings[nLEDs][nLevels] = {
  { maxVal, 0 },  //LED0
  { 0, 0 },       //LED1
  { 0, 0 },       //LED2
  { 0, 0 },       //LED3
  { 0, 0 },       //LED4
  { 0, 0 },       //LED5
  { 0, 0 },       //LED6
  { 0, 0 },       //LED7
};
int nCycleSteps = 100;
int waveform[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 };
int background[] = { 0, 0, 0, 0, 0, 0, 0, 0 };
bool ledIsActive[] = { true, false, false, false, false, false, false, false };

// timing variables
unsigned long lastTime = micros();
unsigned long stepTime = 1e6 / (3*nCycleSteps);  // initialize at 3 Hz
int cycleIndex = 0;

// setup
void setup() {

  // Initialize serial port communication
  Serial.begin(57600);

  // Initialize the built-in LED
  pinMode(LED_BUILTIN, OUTPUT);

  // Set the LEDs to background
  digitalWrite(LED_BUILTIN, LOW);

  // Check which LEDs are "active"
  checkLEDActive();

  // Set the device to background
  setToBackground();

  // Announce we are starting
  Serial.println("== config mode ==");
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
    if (inputString.indexOf("config") >= 0) {
      Serial.println("== config mode");
      modulationState = false;
      configMode = true;
    }
    if (inputString.indexOf("go") >= 0) {
      Serial.println("go");
      modulationState = true;
      cycleIndex = 0;
    }
    if (inputString.indexOf("stop") >= 0) {
      setToBackground();
      Serial.println("stop");
      modulationState = false;
    }
    inputString = "";
  }

  // Advance the LED settings
  if (modulationState) {
    unsigned long currentTime = micros();
    if ((currentTime - lastTime) > stepTime) {
      lastTime = currentTime;
      // loop through the LEDs
      updateLEDs(cycleIndex);
      // advance the cycleIndex
      cycleIndex++;
      if (cycleIndex >= nCycleSteps) cycleIndex = 0;
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
  if (inputString.indexOf("freq") >= 0) {
    inputString = "";
    Serial.print("frequency in Hz: ");
    waitForNewString();
    Serial.print(inputString);
    stepTime = 1e6 / (nCycleSteps * inputString.toFloat());
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


void updateLEDs(int cycleIndex) {
  for (int ii = 0; ii < nLEDs; ii++) {
    // Check if the LED is active
    if (ledIsActive[ii]) {
      // Get the setting for this LED
      int ledSetting = settings[ii][waveform[cycleIndex]];
      if (simulatePrizmatix) {
        // Use the built in arduino LED, which has a binary state
        if (ledSetting > (maxVal / 2)) {
          digitalWrite(LED_BUILTIN, HIGH);
        } else {
          digitalWrite(LED_BUILTIN, LOW);
        }
      } else {
        writeToOneCombiLED(ledSetting, ii);
      }
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
