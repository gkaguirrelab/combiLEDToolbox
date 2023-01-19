String inputString = "";         // a String to hold incoming data
bool stringComplete = false;  // whether the string is complete

// setup
void setup() {
  Serial.begin(57600);
}

void loop() {
  listen();
  if (stringComplete) {
    switch (inputString[0]) {      // just get the first letter of the string for now 
      case 'g':
        Serial.println("Continuing");
        break;
      case 'v':  
        inputString = "";
        stringComplete = false;
        waitForNewString();
        Serial.println(inputString);
        break;
    }        
    inputString = "";
    stringComplete = false; 
  }
}  

void listen() {
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