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

///////////////////// SIMULATE PRIZMATIX /////////////////////////////
// Set this variable to use the built-in LED to simulate
// the output of the Prizmatix device
//
bool simulatePrizmatix = true;  // Simulate the prizmatix LEDs

// Fixed hardware values
const int maxVal = 4095;            // maximum setting value for the prizmatix LEDs
const int minLEDAddressTime = 360;  // the time, in microseconds, required refresh an LED setting

// Global variables
String inputString = "";       // a String to hold incoming data
bool stringComplete = false;   // whether the string is complete
bool configMode = false;       // stay in setup mode until commanded otherwise
bool modulationState = false;  // When we are running, are we modulating?

// Define settings and modulations
const int nLEDs = 8;     // number of LEDs defining the number of rows of the settings matrix.
const int nLevels = 40;  // the number of modulation levels that are specified for each LEDint waveform = 1;  // sinusoid
int waveform = 1;
int settings[nLEDs][nLevels] = {
  { 0, 105, 210, 315, 420, 525, 630, 735, 840, 945, 1050, 1155, 1260, 1365, 1470, 1575, 1680, 1785, 1890, 1995, 2100, 2205, 2310, 2415, 2520, 2625, 2730, 2835, 2940, 3045, 3150, 3255, 3360, 3465, 3570, 3675, 3780, 3885, 3990, 4095 },  //LED0
  { 0, 105, 210, 315, 420, 525, 630, 735, 840, 945, 1050, 1155, 1260, 1365, 1470, 1575, 1680, 1785, 1890, 1995, 2100, 2205, 2310, 2415, 2520, 2625, 2730, 2835, 2940, 3045, 3150, 3255, 3360, 3465, 3570, 3675, 3780, 3885, 3990, 4095 },  //LED0
  { 0, 105, 210, 315, 420, 525, 630, 735, 840, 945, 1050, 1155, 1260, 1365, 1470, 1575, 1680, 1785, 1890, 1995, 2100, 2205, 2310, 2415, 2520, 2625, 2730, 2835, 2940, 3045, 3150, 3255, 3360, 3465, 3570, 3675, 3780, 3885, 3990, 4095 },  //LED0
  { 0, 105, 210, 315, 420, 525, 630, 735, 840, 945, 1050, 1155, 1260, 1365, 1470, 1575, 1680, 1785, 1890, 1995, 2100, 2205, 2310, 2415, 2520, 2625, 2730, 2835, 2940, 3045, 3150, 3255, 3360, 3465, 3570, 3675, 3780, 3885, 3990, 4095 },  //LED0
  { 0, 105, 210, 315, 420, 525, 630, 735, 840, 945, 1050, 1155, 1260, 1365, 1470, 1575, 1680, 1785, 1890, 1995, 2100, 2205, 2310, 2415, 2520, 2625, 2730, 2835, 2940, 3045, 3150, 3255, 3360, 3465, 3570, 3675, 3780, 3885, 3990, 4095 },  //LED0
  { 0, 105, 210, 315, 420, 525, 630, 735, 840, 945, 1050, 1155, 1260, 1365, 1470, 1575, 1680, 1785, 1890, 1995, 2100, 2205, 2310, 2415, 2520, 2625, 2730, 2835, 2940, 3045, 3150, 3255, 3360, 3465, 3570, 3675, 3780, 3885, 3990, 4095 },  //LED0
  { 0, 105, 210, 315, 420, 525, 630, 735, 840, 945, 1050, 1155, 1260, 1365, 1470, 1575, 1680, 1785, 1890, 1995, 2100, 2205, 2310, 2415, 2520, 2625, 2730, 2835, 2940, 3045, 3150, 3255, 3360, 3465, 3570, 3675, 3780, 3885, 3990, 4095 },  //LED0
  { 0, 105, 210, 315, 420, 525, 630, 735, 840, 945, 1050, 1155, 1260, 1365, 1470, 1575, 1680, 1785, 1890, 1995, 2100, 2205, 2310, 2415, 2520, 2625, 2730, 2835, 2940, 3045, 3150, 3255, 3360, 3465, 3570, 3675, 3780, 3885, 3990, 4095 },  //LED0
};
int background[nLEDs] = { 20, 20, 20, 20, 20, 20, 20, 20 };
bool ledIsActive[nLEDs] = { true, true, true, true, true, true, true, true };

// Variables that define an amplitude modulation
// int ampModType = 1;
// float ampVals[] = { 1.5, 6 };  // ramp duration, total block duration

int ampModType = 2;
float ampVals[] = { 0.1, 1.0 };  // AM modulation frequency, AM deoth


// timing variables
unsigned long cycleDur = 1e6 / 3;  // initialize at 3 Hz
unsigned long modulationStartTime = micros();
unsigned long lastLEDUpdateTime = micros();
int cycleLED = 0;

// setup
void setup() {

  // Initialize serial port communication
  Serial.begin(57600);

  // Modify the settings if we are simulating
  if (simulatePrizmatix) {
    for (int ii = 1; ii < nLEDs; ii++) {
      for (int jj = 0; jj < nLevels; jj++) {
        settings[ii][jj] = 0;
      }
      background[ii] = 0;
    }
  }

  // Set up the built-in LED if we are simulating
  if (simulatePrizmatix) {
    pinMode(LED_BUILTIN, OUTPUT);
  } else {
    Wire.begin();
    Wire.setClock(400000);
  }

  // Check which LEDs are "active"
  identifyActiveLEDs();

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
    if (waveform == 2) Serial.println("square");
    if (waveform == 3) Serial.println("saw on");
    if (waveform == 4) Serial.println("saw off");
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
    identifyActiveLEDs();
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
    // if the incoming character is a newline,
    // set a flag so the main loop can
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

void identifyActiveLEDs() {
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
    int ii = 0;
    int ledSetting = settings[ii][background[ii]];
    if (ledSetting > (maxVal / 2)) {
      digitalWrite(LED_BUILTIN, HIGH);
    } else {
      digitalWrite(LED_BUILTIN, LOW);
    }
  } else {
    for (int ii = 0; ii < nLEDs; ii++) {
      // Get the setting for this LED
      int ledSetting = settings[ii][background[ii]];
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

void updateLED(double cyclePhase, int ledIndex) {
  if (ledIsActive[ledIndex]) {
    // Get the level for this LED, based upon waveform
    float floatLevel = getFrequencyModulation(cyclePhase);
    floatLevel = applyAmplitudeModulation(floatLevel, ledIndex);
    int ledLevel = (nLevels - 1) * floatLevel;
    int ledSetting = settings[ledIndex][ledLevel];
    if (simulatePrizmatix) {
      pulseWidthModulate(ledSetting);
    } else {
      writeToOneCombiLED(ledSetting, ledIndex);
    }
  }
}

float getFrequencyModulation(float phase) {
  float level = 0;
  if (waveform == 1) {                               // sin
    level = ((sin(2 * 3.1415927 * phase) + 1) / 2);  // 0-1 domain
  }
  if (waveform == 2) {  // square wave
    if (phase >= 0.5) {
      level = 1;
    } else {
      level = 0;
    }
  }
  if (waveform == 3) {  // saw on
    level = phase;
  }
  if (waveform == 4) {  // saw on
    level = 1 - phase;
  }
  return level;
}

float applyAmplitudeModulation(float level, int ledIndex) {
  if (ampModType == 1) {
    float rampDur = ampVals[0];
    float totalDur = ampVals[1];
    // Determine how far along the half-cosine ramp we are
    float elapsedTimeSecs = (micros() - modulationStartTime) / 1e6;
    float modLevel = 0;
    float plateauDur = totalDur - rampDur;
    if (elapsedTimeSecs < rampDur) {
      modLevel = (cos(3.1415927 + 3.1415927 * (elapsedTimeSecs / rampDur)) + 1) / 2;
    }
    if ((elapsedTimeSecs > rampDur) && (elapsedTimeSecs < plateauDur)) {
      modLevel = 1.0;
    }
    if ((elapsedTimeSecs > plateauDur) && (elapsedTimeSecs < totalDur)) {
      modLevel = (cos(3.1415927 * ((elapsedTimeSecs - plateauDur) / rampDur)) + 1) / 2;
    }
    // center the level around the background
    float offset = float(settings[ledIndex][background[ledIndex]]) / float(maxVal);
    level = (level - offset) * modLevel + offset;
  }
  if (ampModType == 2) {
    float AMFrequencyHz = ampVals[0];
    float AMDepth = ampVals[1];
    // Determine how far along the modulation we are
    float elapsedTimeSecs = (micros() - modulationStartTime) / 1e6;
    float modLevel = AMDepth * (sin(2 * 3.1415927 * (elapsedTimeSecs / (1/AMFrequencyHz))) + 1) / 2;
    // center the level around the background
    float offset = float(settings[ledIndex][background[ledIndex]]) / float(maxVal);
    level = (level - offset) * modLevel + offset;
  }
  return level;
}

void pulseWidthModulate(int setting) {
  // Use pulse-width modulation to vary the
  // intensity of the built in arduino LED
  float portionOn = float(setting) / float(maxVal);
  int timeOn = minLEDAddressTime * portionOn;
  int timeOff = minLEDAddressTime - timeOn;
  unsigned long startTime = micros();
  unsigned long currTime = micros();
  digitalWrite(LED_BUILTIN, HIGH);
  bool notDone = true;
  while (notDone) {
    currTime = micros();
    if ((currTime - startTime) > timeOn) {
      notDone = false;
    }
  }
  startTime = micros();
  digitalWrite(LED_BUILTIN, LOW);
  notDone = true;
  while (notDone) {
    currTime = micros();
    if ((currTime - startTime) > timeOff) {
      notDone = false;
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
