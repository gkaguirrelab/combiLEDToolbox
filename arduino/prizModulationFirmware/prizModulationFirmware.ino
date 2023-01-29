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
String inputString = "";        // a String to hold incoming data
bool stringComplete = false;    // whether the string is complete
bool configMode = true;         // stay in setup mode until commanded otherwise
bool simulatePrizmatix = true;  // Simulate the prizmatix LEDs
bool modulationState = false;   // When we are running, are we modulating?

const int nLEDs = 8;      // number of LEDs defining the number of rows of the settings matrix.
const int maxVal = 4095;       // maximum setting value for the prizmatix LEDs
const int nLevels = 2;  // the number of discrete settings

// Define default waveform and settings
int cycleIndex = 0;
int nCycleSteps = 100;
int waveform[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1,  0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 };
int settings[nLEDs][nLevels] = {
  { 0, maxVal },  //LED1
  { 0, maxVal },  //LED1
  { 0, maxVal },  //LED1
  { 0, maxVal },  //LED1
  { 0, maxVal },  //LED1
  { 0, maxVal },  //LED1
  { 0, maxVal },  //LED1
  { 0, maxVal },  //LED1
};

// Default values for the timing
unsigned long stepTime =  1e6 / nCycleSteps;   // initialize at 1 Hz
unsigned long lastTime = micros();

// setup
void setup() {

  // Initialize serial port communication
  Serial.begin(57600);

  // Initialize the built-in LED
  pinMode(LED_BUILTIN, OUTPUT);

  // Set the LED to off
  digitalWrite(LED_BUILTIN, LOW);
  
  // update lastTime
  double lastTime = micros();

  // Announce we are starting
  Serial.println("== entering setup mode ==");
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
    Serial.println(inputString);
    stringComplete = false;
    if (inputString.indexOf("config") >= 0) {
      Serial.println("== entering setup mode ==");
      modulationState = false;
      configMode = true;
    }
    if (inputString.indexOf("go") >= 0) {
      Serial.println("= modulation go =");
      modulationState = true;
    }
    if (inputString.indexOf("stop") >= 0) {
      Serial.println("= modulation stop =");
      modulationState = false;
    }
    inputString = "";
  }

  // Advance the LED settings
  if (modulationState) {
    unsigned long currentTime = micros();
    if ((currentTime - lastTime) > stepTime) {
      lastTime = currentTime;
      if (simulatePrizmatix) {
        int led1Setting = settings[0][waveform[cycleIndex]];
        if (led1Setting > (maxVal / 2)) {
          digitalWrite(LED_BUILTIN, HIGH);
        } else {
          digitalWrite(LED_BUILTIN, LOW);
        }
        cycleIndex++;
        if (cycleIndex >= nCycleSteps) cycleIndex = 0;
      }
    }
  }
}

void getConfig() {
    Serial.println("at getConfig");
  waitForNewString();
    Serial.println(inputString);
  stringComplete = false;
  if (inputString.indexOf("run") >= 0) {
    Serial.println("== entering run mode ==");
    configMode = false;
    modulationState = false;
  }
  if (inputString.indexOf("freq") >= 0) {
    inputString = "";
    Serial.println("frequency in Hz: ");
    waitForNewString();
    stepTime = 1e6 / (nCycleSteps * inputString.toFloat());
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
