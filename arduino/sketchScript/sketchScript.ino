String inputString = "";         // a String to hold incoming data
bool stringComplete = false;  // whether the string is complete

// setup
void setup() {
  Serial.begin(57600);
}

void loop() {
  // Listen for a serial input and if a serial string is complete, go into a switch case.
  listen();                                      
  if (stringComplete) {
    switch (inputString[0]) {      
      // This case just prints a line currently               
      case 'g':  
        Serial.println("Continuing");
        break;
      // This case listens for a second input and saves it into a vector
      case 'v':  
        inputString = "";
        stringComplete = false;
        waitForNewString();
        
        // This next section converts the second input into a vector
        // Uses comma delimeters to parse
        inputString += ',';                                 // Add a comma at the end of the input string to make life easier      
        String vectorString = "";                           // Set a vector string which will be appended with chars 
        int numberOfCommas = -1;                            // Comma counter, zero indexed language, so start from -1
        int vector[30];                                     // We set a vector which can hold 30 bytes
        
        // Loop through input string. if not comma, append to vectorString
        // If comma, assign the completed vectorString to a vector index.
        for(int i =0; i < inputString.length(); i++ ) {
          char c = inputString[i];
          if (c != ',') {
            vectorString += c;
          }
          else {
            numberOfCommas += 1;
            vector[numberOfCommas] = vectorString.toInt();
            vectorString = "";            
          }
        }

        // Print each items of the complete vector
        for(int i = 0; i < numberOfCommas+1; i++)
        {
          Serial.println(vector[i]);
        }
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
