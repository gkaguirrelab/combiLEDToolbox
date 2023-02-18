////////////////////////////////////////////////////////////////////////////////
// Firmware for the Prizmatix CombiLED light engine
//
// This code supports the presentation of temporal modulations of the
// spectral content of light generated by the CombiLED device. The device
// contains 8, narrow-band LEDs under the control of an Arduino Uno.
//
// The LEDs have the following spectroradiometric properties:
//            peak (nm)    FWHM (nm)     power (mW_)
//  LED0 --   405          14            1900
//  LED1 --   424          27            750
//  LED2 --   470          21            460
//  LED3 --   498          22            295
//  LED4 --   540          67            680
//  LED5 --   598          14            88
//  LED6 --   627          19            480
//  LED7 --   561          15            470
//
// The "settings" vectors specify the highest and lowest intensity levels
// of each LED between 0 and 1 with 1e-4 precision. Over time, a waveform
// defines a linear transition between the high and the low state,
// producing (for example) a change in luminance or L–M contrast. Gamma
// correction is performed on device, and the resulting floating value
// is cast into a 12 bit LED setting.
//
// The modulation is under the control of a waveform (e.g., sin, square) and
// a frequency [Hz]. After setup, the code enters a run loop during which each
// LED is updated sequentially. The waveform is used to define a floating
// point level (0-1), which is mapped between the low and high setting values.
//
// There is a minimum amount of time required to address an LED (about 250
// microseconds). The routine will attempt to update LEDs at this interval,
// but computational overhead results in about 850 microseconds (0.85 msecs)
// per LED update. The program clock advances and, for each cycle, determines
// where we are in the waveform and updates the settings on the next LED. As
// a consequence, different LEDs oscillate at different phase delays of the
// waveform.
//
// Given 8 LEDs to update, and a maximum update rate of 0.85 msecs / LED, the
// Nyquist frequency of the device is ~147 Hz, limiting us to roughly 70 Hz as a
// max modulation frequency. We can do better than this by limiting ourselves to
// fewer than 8 active LEDs. If an LED has the same high and low setting value,
// then that LED is marked as "inactive", and skipped in the sequential 
// updating. This allows the remaining, active LEDs to be updated more 
// frequently.
//
// In addition to the frequency modulation of the waveform, a superimposed
// amplitude modulation may be specified.
//
// In operation, the firmware supports placing the device in three states:
//  RUN MODE (RM) -- continuously present the specified modulation
//  CONFIG MODE (CM) -- change the parameters of the modulation
//  DIRECT MODE (DM) -- pass setting values directly to the LEDs; this
//                      mode is used when performing device calibration.
//
// Global variables of note:
//  simulatePrizmatix   Boolean. If set to true, the code treats the Arduino
//                      built-in LED as LED0. The intensity of the LED is
//                      pulse-width modulated. The other 7 channels are ignored.
//  gammaCorrectInDirectMode  Boolean. Normally set to false. Set to true for
//                      the particular instance of wishing to confirm via a 
//                      calibration measurement the effect of gamma correction.
//  maxLevelVal         4095. This is the max of the 12-bit range.
//  settingScale        1e4. To save memory, many variables are unsigned ints,
//                      with an expected value of 0 - 1e4. The variable is
//                      divided by the setting scale to yield a float.
//  minLEDAddressTime   Scalar, microseconds. We find that it takes 234 microsecs
//                      to write a setting to one LED. We ensure that we don't
//                      try to update settings faster than this, as it causes
//                      collisions in the communication channel.
//  settingsHigh, settingsLow 8x1 int matrix, all between 0 and 1e4. Each value
//                      defines the high or low setting for each of the 8 LEDs.
//                      The specified value is divided by 1e4 to yield a floaat
//                      between 0 and 1. This value is subject to gamma correction
//                      prior to being passed to the LED.
//  background          8x1 int array of value 0-1e4. Specifies the
//                      background level for each LED.
//  fmContrast          Float, between 0 and 1. Defines the contrast of the
//                      modulation relative to its maximum.
//  gammaParams         8x6 float matrix. Defines the parameters of a 5th order
//                      polynomial (plus an offset) that define the conversion
//                      of the desired intensity level to the corresponding
//                      device level for each LED. These parameters are used to
//                      create a gamma correction look-up table.
//  waveformIndex       Scalar. Defines the waveform profile to be used:
//                        0 - no modulation (stay at background)
//                        1 - sinusoid
//                        2 - square wave (off-on)
//                        3 - saw-tooth on
//                        4 - saw-tooth off
//                        5 - compound modulation
//  fmCycleDur          Scalar. The duration in microseconds of the fm waveform.
//  phaseOffset         Float, 0-1. Used to shift the phase of the fm waveform.
//  amplitudeIndex      Scalar. Defines the amplitude modulation profile:
//                        0 - none
//                        1 - sinusoid modulation
//                        2 - half-cosine window
//  amCycleDur          Scalar. The duration in microseconds of the am waveform.
//  amplitudeVals       2x1 float array. Values control the amplitude modulation,
//                      varying by the amplitudeIndex.
//  blinkDurationMSecs  Scalar. Duration of attention event in milliseconds.
//                      During run-mode, passing a "blink" command sets all LEDs
//                      to zero for the blink duration. Default is 100 msecs.
//  ledUpdateOrder      8x1 int array, of values 0-7. Defines the order in which
//                      the LEDs are updated across the cycle. By default, the order
//                      interleaves LEDs.
//
//
//

// package to write to the LEDs
#include <Wire.h>


///////////////////// SIMULATE PRIZMATIX /////////////////////////////
// Set this variable to use the built-in LED to simulate
// the output of the Prizmatix device
//
bool simulatePrizmatix = false;
/////////////////////////////////////////////////////////////////////



///////////////////// DIRECT MODE BEHAVIOR //////////////////////////
// Direct mode is used to calibrate the device. This flag controls
// if the settings that are sent in direct mode are subjected to the
// on-board gamma correction. If the device is being calibrated, we
// generally do not want to gamma correct, as part of the purpose of
// calibration is to measure the gamma table. The primary use of this
// flag is to conduct a test to confirm that the on-board gamma
// correction yields a linear-appearing set of responses in a
// calibration measure that uses this correction.
//
bool gammaCorrectInDirectMode = false;
/////////////////////////////////////////////////////////////////////


// Fixed hardware values
const int maxLevelVal = 4095;       // maximum setting value for the prizmatix LEDs
const int minLEDAddressTime = 250;  // the time, in microseconds, required to send an LED setting

// Fixed reality values
const float pi = 3.1415927;

// Fixed value that scales the settings and background values to floats between 0 and 1
const int settingScale = 1e4;

// The resolution with which we will define various look-up tables
const int nGammaLevels = 25;
const int nAmModLevels = 25;
const int nFmModLevels = 50;

// The number of parameters used to define the gamma polynomial function (5th degree + 1)
const int nGammaParams = 6;

// Define the device states
enum { CONFIG,
       RUN,
       DIRECT } deviceState = RUN;

// Global and control variables
const uint8_t inputStringLen = 12;  // size of the string buffer used to send commands
char inputString[inputStringLen];   // a character vector to hold incoming data
uint8_t inputCharIndex = 0;         // index to count our accumulated characters
bool stringComplete = false;        // whether the input string is complete
bool modulationState = false;       // When we are running, are we modulating?

// Define settings and modulations
const uint8_t nLEDs = 8;  // the number of LEDs

// A default setting, which is 100% Light Flux. 0-1e4 precision
int settingsLow[nLEDs] = { 0, 0, 0, 0, 0, 0, 0, 0 };
int settingsHigh[nLEDs] = { 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000 };
int background[nLEDs] = { 5000, 5000, 5000, 5000, 5000, 5000, 5000, 5000 };

// A frequency modulation look-up table. 0-1e4 precision
int fmModTable[nFmModLevels];

bool interpolateWaveform = true;  // Controls if we perform linear interpolation
                                  // between levels of the fmModTable. Generally,
                                  // we want to do so for continuous (e.g., sin)
                                  // modulations, but not for discontinuous
                                  // (e.g., square wave) modulations.

// Adjust the overall contrast of the modulation between 0 and 1
float fmContrast = 1;

// The ledUpdateOrder vector is regenerated whenever the settings or background
// changes. The idea is to skip updating LEDs if their settings never change
// from the background.
int nActiveLEDs = nLEDs;
uint8_t ledUpdateOrder[] = { 0, 1, 2, 3, 4, 5, 6, 7 };

// A gamma table. 0-1e4 precision
int gammaTable[nLEDs][nGammaLevels];

// Variables that define an amplitude modulation
uint8_t amplitudeIndex = 0;  // Default to no amplitude modulation
float amplitudeVals[3][2] = {
  { 0.0, 0.0 },  // no amplitude modulation;  0) unusued; 1) unusued
  { 0.0, 0.0 },  // sinusoidal modulation; 0) unusued; 1) unusued
  { 1.5, 0.0 },  // half-cosine window: 0) Window duration seconds; 1) unusued
};

// An amplitude modulation look-up table. 0-1e4 precision
int amModTable[nAmModLevels];

// Variables the define compound modulations. Support is provided for a compound modulation
// composed of up to 5 sinusoids. For each sinusoid, we specify the harmonic index relative
// to the fundamental FM modulation frequency (0 for no modulation), the relative amplitude
// of that harmonic component, and the relative phase (in radians). Finally, we need to know
// the min and max values across a full cycle of a given compound waveform. The compoundRange
// variable holds the result. See the function "updateCompoundRange" for details.
float compoundHarmonics[5] = { 1, 2, 4, 0, 0 };         // Multiples of the fundamental
float compoundAmps[5] = { 0.5, 1, 1, 0, 0 };            // Relative amplitudes
float compoundPhases[5] = { 0, 0.7854, 4.3633, 0, 0 };  // Phase delay in radians
float compoundRange[2] = { 0, 1 };

// Timing variables
uint8_t waveformIndex = 1;                     // Default to sinusoid
unsigned long fmCycleDur = round(1e6 / 3);     // Initialize at 3 Hz
unsigned long amCycleDur = round(1e6 / 0.1);   // Initialize at 0.1 Hz
unsigned long modulationStartTime = micros();  // Initialize these with the clock
unsigned long lastLEDUpdateTime = micros();    // Initialize these with the clock
int blinkDurationMSecs = 100;                  // Default duration of the blink event in msecs
uint8_t ledCycleIdx = 0;                       // Counter to index our cycle through updating LEDs
float phaseOffset = 0;                         // 0-1, used to shift the waveform phase
float modulationDurSecs = 0;                   // Duration of the modulation in secs (0 for continuous)
unsigned long cycleCount = 0;                  // Num cycles elapsed since modulation start


// setup
void setup() {
  // Initialize serial port communication
  Serial.begin(57600);
  // Modify the settings and background if we are simulating
  if (simulatePrizmatix) {
    background[0] = 0;
    for (int ii = 1; ii < nLEDs; ii++) {
      settingsHigh[ii] = 0;
      settingsLow[ii] = 0;
      background[ii] = 0;
    }
  }
  // Initialize communication with the LED(s)
  if (simulatePrizmatix) {
    // Use the built-in LED
    pinMode(LED_BUILTIN, OUTPUT);
  } else {
    // USe the wired LEDs
    Wire.begin();
    Wire.setClock(400000);
  }
  // Check which LEDs are "active"
  identifyActiveLEDs();
  // Initialize a linear gammaTable
  initializeGammaTable();
  // Populate the amplitude modulation table
  updateAmModTable();
  // Set the device to background
  setToBackground();
  // Update the compoundRange, in case we have
  // a compound modulation to start
  updateCompoundRange();
  // Populate the frequency modulation table
  updateFmModTable();
  // Show the console menu
  showModeMenu();
}

// loop
void loop() {
  // Handle inputs dependent upon the deviceState
  switch (deviceState) {
    case CONFIG:
      getConfig();
      break;
    case DIRECT:
      getDirect();
      break;
    case RUN:
      getRun();
      break;
  }
  // Advance the LED settings
  if (modulationState) {
    unsigned long currentTime = micros();
    if ((currentTime - lastLEDUpdateTime) > minLEDAddressTime) {
      // Collect diagnostic timing information
      cycleCount++;
      // Determine where we are in the fm cycle
      unsigned long fmCycleTime = ((currentTime - modulationStartTime) % fmCycleDur);
      float fmCyclePhase = float(fmCycleTime) / float(fmCycleDur);
      // Determine where we are in the am cycle
      unsigned long amCycleTime = ((currentTime - modulationStartTime) % amCycleDur);
      float amCyclePhase = float(amCycleTime) / float(amCycleDur);
      // Update the lastTime
      lastLEDUpdateTime = currentTime;
      // Update the next LED
      updateLED(fmCyclePhase, amCyclePhase, ledUpdateOrder[ledCycleIdx]);
      // Advance the ledCycleIdx
      ledCycleIdx++;
      ledCycleIdx = ledCycleIdx % nActiveLEDs;
    }
    // Check if we have exceeded the modulation duration
    if (modulationDurSecs > 0) {
      float elapsedTimeSecs = (currentTime - modulationStartTime) / 1e6;
      if (elapsedTimeSecs > modulationDurSecs) {
        modulationState = false;
        setToBackground();
      }
    }
  }
}

// Had to comment out the menu details as these serial entries
// eat up dynamic memory space.
void showModeMenu() {
  switch (deviceState) {
    case CONFIG:
      Serial.println("CM");
      break;
    case DIRECT:
      Serial.println("DM");
      break;
    case RUN:
      Serial.println("RM");
      break;
  }
}

void getConfig() {
  // Operate in modal state waiting for input
  waitForNewString();
  if (strncmp(inputString, "WF", 2) == 0) {
    // waveformIndex controls the FM modulation form
    Serial.println("WF:");
    clearInputString();
    waitForNewString();
    waveformIndex = atoi(inputString);
    if (waveformIndex == 0) Serial.println("none");
    if (waveformIndex == 1) Serial.println("sin");
    if (waveformIndex == 2) Serial.println("square");
    if (waveformIndex == 3) Serial.println("sawon");
    if (waveformIndex == 4) Serial.println("sawoff");
    if (waveformIndex == 5) {
      Serial.println("compound");
      updateCompoundRange();
    }
    updateFmModTable();
  }
  if (strncmp(inputString, "FQ", 2) == 0) {
    // Carrier modulation frequency (float Hz)
    Serial.println("FQ:");
    clearInputString();
    waitForNewString();
    fmCycleDur = 1e6 / atof(inputString);
    Serial.println(atof(inputString));
  }
  if (strncmp(inputString, "MD", 2) == 0) {
    // Modulation duration (float seconds)
    // Set to zero to have the modulation
    // continue until stopped
    Serial.println("MD:");
    clearInputString();
    waitForNewString();
    modulationDurSecs = atof(inputString);
    Serial.println(modulationDurSecs);
  }
  if (strncmp(inputString, "CN", 2) == 0) {
    // fmContrast (0-1 float)
    Serial.println("CN:");
    clearInputString();
    waitForNewString();
    fmContrast = atof(inputString);
    Serial.println(fmContrast);
  }
  if (strncmp(inputString, "PH", 2) == 0) {
    // Phase offset. Takes a 0-2pi float and
    // converts it to the 0-1 domain
    Serial.println("PH:");
    clearInputString();
    waitForNewString();
    phaseOffset = atof(inputString) / (2 * pi);
    Serial.println(atof(inputString));
  }
  if (strncmp(inputString, "AM", 2) == 0) {
    // Amplitude modulation index
    Serial.println("AM:");
    clearInputString();
    waitForNewString();
    amplitudeIndex = atoi(inputString);
    if (amplitudeIndex == 0) Serial.println("none");
    if (amplitudeIndex == 1) Serial.println("sin");
    if (amplitudeIndex == 2) Serial.println("half-cos");
    updateAmModTable();
  }
  if (strncmp(inputString, "AF", 2) == 0) {
    // Amplitude modulation frequency
    Serial.println("AF:");
    clearInputString();
    waitForNewString();
    amCycleDur = 1e6 / atof(inputString);
    Serial.println(atof(inputString));
    updateAmModTable();
  }
  if (strncmp(inputString, "AV", 2) == 0) {
    // Amplitude modulation values for the current index
    Serial.println("AV:");
    clearInputString();
    waitForNewString();
    float newVal = atof(inputString);
    amplitudeVals[amplitudeIndex][0] = newVal;
    Serial.println(newVal);
    clearInputString();
    waitForNewString();
    newVal = atof(inputString);
    amplitudeVals[amplitudeIndex][1] = newVal;
    Serial.println(newVal);
  }
  if (strncmp(inputString, "CH", 2) == 0) {
    // Compound modulation, 5 harmonic indices
    Serial.println("CH:");
    clearInputString();
    for (int ii = 0; ii < 5; ii++) {
      waitForNewString();
      float newVal = atof(inputString);
      compoundHarmonics[ii] = newVal;
      Serial.println(newVal);
      clearInputString();
    }
    updateCompoundRange();
    updateFmModTable();
  }
  if (strncmp(inputString, "CA", 2) == 0) {
    // Compound modulation, 5 harmonic amplitudes
    Serial.println("CA:");
    clearInputString();
    for (int ii = 0; ii < 5; ii++) {
      waitForNewString();
      float newVal = atof(inputString);
      compoundAmps[ii] = newVal;
      Serial.println(newVal);
      clearInputString();
    }
    updateCompoundRange();
    updateFmModTable();
  }
  if (strncmp(inputString, "CP", 2) == 0) {
    // Compound modulation, 5 harmonic phases
    Serial.println("CP:");
    clearInputString();
    for (int ii = 0; ii < 5; ii++) {
      waitForNewString();
      float newVal = atof(inputString);
      compoundPhases[ii] = newVal;
      Serial.println(newVal);
      clearInputString();
    }
    updateCompoundRange();
    updateFmModTable();
  }
  if (strncmp(inputString, "ST", 2) == 0) {
    // Matrix of settings int, 0-1e4, first
    // settingsLow, then settingsHigh
    Serial.println("ST:");
    clearInputString();
    for (int ii = 0; ii < nLEDs; ii++) {
      waitForNewString();
      int level = atoi(inputString);
      settingsLow[ii] = level;
      Serial.println(level);
      clearInputString();
    }
    for (int ii = 0; ii < nLEDs; ii++) {
      waitForNewString();
      int level = atoi(inputString);
      settingsHigh[ii] = level;
      Serial.println(level);
      clearInputString();
    }
    identifyActiveLEDs();
  }
  if (strncmp(inputString, "GP", 2) == 0) {
    Serial.println("GP:");
    clearInputString();
    updateGammaTable();
    setToBackground();
  }
  if (strncmp(inputString, "BG", 2) == 0) {
    // Matrix of background settings int, 0-1e4
    Serial.println("BG:");
    clearInputString();
    for (int ii = 0; ii < nLEDs; ii++) {
      waitForNewString();
      int level = atoi(inputString);
      background[ii] = level;
      Serial.println(level);
      clearInputString();
    }
    identifyActiveLEDs();
    setToBackground();
  }
  if (strncmp(inputString, "RM", 2) == 0) {
    // Switch to run mode
    modulationState = false;
    deviceState = RUN;
    setToBackground();
    showModeMenu();
  }
  if (strncmp(inputString, "DM", 2) == 0) {
    // Switch to direct control mode
    modulationState = false;
    deviceState = DIRECT;
    showModeMenu();
  }
  clearInputString();
}

void getDirect() {
  // Operate in modal state waiting for input
  waitForNewString();

  // The primary Direct mode activity: send a
  // vector of settings for the LEDs.
  if (strncmp(inputString, "LL", 2) == 0) {
    Serial.println("LL:");
    clearInputString();
    for (int ii = 0; ii < nLEDs; ii++) {
      waitForNewString();
      int level = atoi(inputString);
      Serial.println(level);
      clearInputString();
      // Convert 1e4 level to a 0-1 float level
      float floatSettingLED = float(level) / float(settingScale);
      // gamma correct floatSettingLED
      if (gammaCorrectInDirectMode) floatSettingLED = applyGammaCorrect(floatSettingLED, ii);
      // Convert the floatSettingLED to a 12 bit integer
      int settingLED = round(floatSettingLED * maxLevelVal);
      if (simulatePrizmatix) {
        pulseWidthModulate(settingLED);
      } else {
        writeToOneCombiLED(settingLED, ii);
      }
    }
  }
  if (strncmp(inputString, "DK", 2) == 0) {
    setToOff();
    Serial.println("Lights off");
    modulationState = false;
  }
  if (strncmp(inputString, "RM", 2) == 0) {
    modulationState = false;
    deviceState = RUN;
    setToBackground();
    showModeMenu();
  }
  if (strncmp(inputString, "CM", 2) == 0) {
    modulationState = false;
    deviceState = CONFIG;
    showModeMenu();
  }
  clearInputString();
}

void getRun() {
  // Operate in amodal state; only act if we have
  // a complete string
  pollSerialPort();
  if (stringComplete) {
    stringComplete = false;
    if (strncmp(inputString, "GO", 2) == 0) {
      Serial.println("Start modulation");
      modulationState = true;
      lastLEDUpdateTime = micros();
      modulationStartTime = micros();
      cycleCount = 0;
    }
    if (strncmp(inputString, "SP", 2) == 0) {
      setToBackground();
      modulationState = false;
      unsigned long currentTime = micros();
      float timePerCycle = float(currentTime - modulationStartTime) / float(cycleCount);
      Serial.print("microsecs/cycle: ");
      Serial.println(timePerCycle);
    }
    if (strncmp(inputString, "BL", 2) == 0) {
      Serial.println(".");
      setToOff();
      delay(blinkDurationMSecs);
      setToBackground();
    }
    if (strncmp(inputString, "BG", 2) == 0) {
      setToBackground();
      Serial.println(".");
      modulationState = false;
    }
    if (strncmp(inputString, "DK", 2) == 0) {
      setToOff();
      Serial.println(".");
      modulationState = false;
    }
    if (strncmp(inputString, "DM", 2) == 0) {
      modulationState = false;
      setToBackground();
      deviceState = DIRECT;
      showModeMenu();
    }
    if (strncmp(inputString, "CM", 2) == 0) {
      modulationState = false;
      setToBackground();
      deviceState = CONFIG;
      showModeMenu();
    }
    clearInputString();
  }
}

void updateCompoundRange() {
  // Handle compound modulations. We need
  // to scale the waveform between 0 and 1. Here we examine
  // waveform across an entire cycle and store the range to be
  // used later to scale the levels to within 0 and 1.
  if (waveformIndex < 5) return;
  compoundRange[0] = 0;
  compoundRange[1] = 1;
  float newRange[2] = { 0, 0 };
  float phase = 0;
  float level = 0;
  for (int ii = 0; ii < 1000; ii++) {
    phase = float(ii) / 1000;
    level = calFrequencyModulation(phase);
    newRange[0] = min(newRange[0], level);
    newRange[1] = max(newRange[1], level);
  }
  compoundRange[0] = newRange[0];
  compoundRange[1] = newRange[1];
}

void identifyActiveLEDs() {
  nActiveLEDs = 0;
  // Identify those LEDs that are pinned and remove them from the active list
  for (int ii = 0; ii < nLEDs; ii++) {
    if (settingsHigh[ii] != settingsLow[ii]) {
      ledUpdateOrder[nActiveLEDs] = ii;
      nActiveLEDs++;
    }
  }
}

void setToBackground() {
  for (int ii = 0; ii < nLEDs; ii++) {
    // Get the setting for this LED
    float floatSettingLED = float(background[ii]) / float(settingScale);
    // gamma correct floatSettingLED
    floatSettingLED = applyGammaCorrect(floatSettingLED, ii);
    // Convert the floatSettingLED to a 12 bit integer
    int settingLED = round(floatSettingLED * maxLevelVal);
    if (simulatePrizmatix) {
      if (settingLED > (maxLevelVal / 2)) {
        digitalWrite(LED_BUILTIN, HIGH);
      } else {
        digitalWrite(LED_BUILTIN, LOW);
      }
    } else {
      writeToOneCombiLED(settingLED, ii);
    }
  }
}

void setToOff() {
  if (simulatePrizmatix) {
    // Use the built in Arduino LED, which has a binary state
    digitalWrite(LED_BUILTIN, LOW);
  } else {
    // Loop through the LEDs and set them to zero
    for (int ii = 0; ii < nLEDs; ii++) {
      writeToOneCombiLED(0, ii);
    }
  }
}

void updateLED(float fmCyclePhase, float amCyclePhase, int ledIndex) {
  // Adjust the cyclePhase for the phaseOffset
  fmCyclePhase = fmCyclePhase + phaseOffset;
  // Get the level for the current cyclePhase
  float floatLevel = returnFrequencyModulation(fmCyclePhase);
  // Get the background level for this LED
  float offset = float(background[ledIndex]) / float(settingScale);
  // Scale according to the fmContrast value
  floatLevel = fmContrast * (floatLevel - offset) + offset;
  // Apply any amplitude modulation
  floatLevel = applyAmplitudeModulation(amCyclePhase, floatLevel, offset);
  // ensure that level is within the 0-1 range
  floatLevel = max(floatLevel, 0);
  floatLevel = min(floatLevel, 1);
  // Get the floatSettingLED as the proportional
  // distance between the low and high setting value for this LED
  float floatSettingLED = (floatLevel * (settingsHigh[ledIndex] - settingsLow[ledIndex]) + settingsLow[ledIndex]) / float(settingScale);
  // gamma correct floatSettingLED (about 80 microseconds)
  floatSettingLED = applyGammaCorrect(floatSettingLED, ledIndex);
  // Convert the floatSettingLED to a 12 bit integer
  int settingLED = round(floatSettingLED * maxLevelVal);
  // Update the LED (about 230 microseconds)
  if (simulatePrizmatix) {
    pulseWidthModulate(settingLED);
  } else {
    writeToOneCombiLED(settingLED, ledIndex);
  }
}

float returnFrequencyModulation(float fmCyclePhase) {
  float level = 1;
  float floatCell = fmCyclePhase * (nFmModLevels - 1);
  if (interpolateWaveform) {
    // Linear interpolation between values in the fmModTable
    int lowCell = floor(floatCell);
    if (lowCell == (nFmModLevels - 1)) {
      level = float(fmModTable[lowCell]) / settingScale;
    } else {
      float mantissa = (floatCell)-lowCell;
      level = (float(fmModTable[lowCell]) + mantissa * float(fmModTable[lowCell + 1] - fmModTable[lowCell])) / settingScale;
    }
  } else {
    // Nearest-neighbor in the fmModTable
    level = float(fmModTable[round(floatCell)]) / settingScale;
  }
  return level;
}

void updateFmModTable() {
  for (int ii = 0; ii < nFmModLevels; ii++) {
    float fmCyclePhase = float(ii) / (nFmModLevels - 1);
    float modLevel = calFrequencyModulation(fmCyclePhase);
    fmModTable[ii] = round(modLevel * settingScale);
  }
  // Set the interpolateWaveform state
  if ((waveformIndex == 2) || (waveformIndex == 3) || (waveformIndex == 4)) {
    interpolateWaveform = false;
  } else {
    interpolateWaveform = true;
  }
}

float calFrequencyModulation(float fmCyclePhase) {
  // Provides a continuous level, between 0-1, for a given waveform
  // at the specified phase position. We default to a half-on level
  // if not otherwise specified
  float level = 0.5;

  // Sinusoid
  if (waveformIndex == 1) {
    level = ((sin(2 * pi * fmCyclePhase) + 1) / 2);
  }
  // Square wave, off then on
  if (waveformIndex == 2) {
    if (fmCyclePhase >= 0.5) {
      level = 1;
    } else {
      level = 0;
    }
  }
  // Saw-tooth, ramping on and then sudden off
  if (waveformIndex == 3) {
    level = fmCyclePhase;
  }
  // Saw-tooth, ramping off and then sudden on
  if (waveformIndex == 4) {  // saw off
    level = 1 - fmCyclePhase;
  }
  // Compound modulation
  if (waveformIndex == 5) {
    level = 0;
    for (int ii = 0; ii < 5; ii++) {
      level = level + compoundAmps[ii] * sin(compoundHarmonics[ii] * 2 * pi * fmCyclePhase - compoundPhases[ii]);
    }
    // Use the pre-computed "compoundRange" to place level in the 0-1 range
    level = (level - compoundRange[0]) / (compoundRange[1] - compoundRange[0]);
  }
  return level;
}

float applyAmplitudeModulation(float amCyclePhase, float level, float offset) {
  float modLevel = 1;
  // Linear interpolation between values in the amModTable
  float floatCell = amCyclePhase * (nAmModLevels - 1);
  int lowCell = floor(floatCell);
  if (lowCell == (nAmModLevels - 1)) {
    modLevel = float(amModTable[lowCell]) / settingScale;
  } else {
    float mantissa = (floatCell)-lowCell;
    modLevel = (float(amModTable[lowCell]) + mantissa * float(amModTable[lowCell + 1] - amModTable[lowCell])) / settingScale;
  }
  // center the level around the background, apply the modulation, and
  // re-apply the offset
  level = (level - offset) * modLevel + offset;
  return level;
}


void updateAmModTable() {
  for (int ii = 0; ii < nAmModLevels; ii++) {
    float amCyclePhase = float(ii) / (nAmModLevels - 1);
    float modLevel = calcAmplitudeModulation(amCyclePhase);
    amModTable[ii] = round(modLevel * settingScale);
  }
}

float calcAmplitudeModulation(float amCyclePhase) {
  float modLevel = 1.0;
  if (amplitudeIndex == 0) {
    // No amplitude modulation
  }
  if (amplitudeIndex == 1) {
    // Sinusoid amplitude modulation
    modLevel = (sin(2 * pi * amCyclePhase) + 1) / 2;
  }
  if (amplitudeIndex == 2) {
    // Half-cosine window at block onset and offset
    float totalDurSecs = float(amCycleDur) / 1e6;
    float rampDurSecs = amplitudeVals[amplitudeIndex][0];
    // Determine how far along the half-cosine ramp we are, relative
    // to the modulation frequency given by amplitudeVals[0]
    float elapsedTimeSecs = amCyclePhase * totalDurSecs;
    modLevel = 0;
    float blockOnDurSecs = totalDurSecs / 2;
    float plateauDurSecs = blockOnDurSecs - rampDurSecs;
    if (elapsedTimeSecs < rampDurSecs) {
      modLevel = (cos(pi + pi * (elapsedTimeSecs / rampDurSecs)) + 1) / 2;
    }
    if ((elapsedTimeSecs > rampDurSecs) && (elapsedTimeSecs < plateauDurSecs)) {
      modLevel = 1.0;
    }
    if ((elapsedTimeSecs > plateauDurSecs) && (elapsedTimeSecs < blockOnDurSecs)) {
      modLevel = (cos(pi * ((elapsedTimeSecs - plateauDurSecs) / rampDurSecs)) + 1) / 2;
    }
  }
  return modLevel;
}

void initializeGammaTable() {
  // Loop over the LEDs
  for (int ii = 0; ii < nLEDs; ii++) {
    for (int jj = 0; jj < nGammaLevels; jj++) {
      float corrected = float(jj) / (nGammaLevels - 1);
      gammaTable[ii][jj] = round(corrected * settingScale);
    }
  }
}

void updateGammaTable() {
  // Loop over the LEDs
  for (int ii = 0; ii < nLEDs; ii++) {
    // Receive a set of gammaParams that specify the
    // polynomial form of the gamma correction
    float gammaParams[nGammaParams];
    for (int kk = 0; kk < nGammaParams; kk++) {
      waitForNewString();
      gammaParams[kk] = atof(inputString);
      Serial.println(gammaParams[kk]);
      clearInputString();
    }
    // Use this set of gammaParams to populate the gammaTable
    for (int jj = 0; jj < nGammaLevels; jj++) {
      float input = float(jj) / (nGammaLevels - 1);
      float corrected = 0;
      for (int kk = 0; kk < nGammaParams; kk++) {
        corrected = corrected + gammaParams[kk] * pow(input, (nGammaParams - 1) - kk);
      }
      gammaTable[ii][jj] = round(corrected * settingScale);
    }
  }
}

float applyGammaCorrect(float floatSettingLED, int ledIndex) {
  float corrected = 1;
  // Linear interpolation between values in the gammaTable
  float floatCell = floatSettingLED * (nGammaLevels - 1);
  int lowCell = floor(floatCell);
  if (lowCell == (nGammaLevels - 1)) {
    corrected = float(gammaTable[ledIndex][lowCell]) / settingScale;
  } else {
    float mantissa = (floatCell)-lowCell;
    corrected = (float(gammaTable[ledIndex][lowCell]) + mantissa * float(gammaTable[ledIndex][lowCell + 1] - gammaTable[ledIndex][lowCell])) / settingScale;
  }
  return corrected;
}

void pulseWidthModulate(int setting) {
  // Use pulse-width modulation to vary the
  // intensity of the built in Arduino LED
  float portionOn = float(setting) / float(maxLevelVal);
  int timeOn = round(minLEDAddressTime * portionOn);
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

// Send a setting to a wired LED
void writeToOneCombiLED(int level, int ledIndex) {
  // sanitize the input
  level = max(level, 0);
  level = min(level, maxLevelVal);
  // write the values
  Wire.beginTransmission(0x70);
  Wire.write(1 << ledIndex);
  Wire.endTransmission();
  Wire.beginTransmission(0x61);
  Wire.write(0b01011000);
  Wire.write((uint8_t)(highByte(level << 4)));
  Wire.write((uint8_t)(lowByte(level << 4)));
  Wire.endTransmission(1);
}

void pollSerialPort() {
  // Detect the case that we have received a complete string but
  // have not yet finished doing something with it. In this case,
  // do not accept anything further from the buffer
  if ((stringComplete) && (inputCharIndex == 0)) return;
  // See if there is something in the buffer
  while (Serial.available()) {
    // get the new byte:
    char inChar = (char)Serial.read();
    // add it to the inputString:
    inputString[inputCharIndex] = inChar;
    inputCharIndex++;
    if (inputCharIndex >= inputStringLen) {
      Serial.println("ERROR: Input overflow inputString buffer");
      clearInputString();
      return;
    }
    // if the incoming character is a newline,
    // set a flag so the main loop can
    // do something about it.
    if (inChar == '\n') {
      stringComplete = true;
      inputCharIndex = 0;
    }
  }
}

void waitForNewString() {
  bool stillWaiting = true;
  while (!stringComplete) {
    pollSerialPort();
  }
}

// Clean-up after receiving inputString
void clearInputString() {
  for (int ii = 0; ii < inputStringLen; ii++) {
    inputString[ii] = "";
  }
  inputCharIndex = 0;
  stringComplete = false;
}