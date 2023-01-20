String inputString = "";         // a String to hold incoming data
bool stringComplete = false;     // whether the string is complete
const int numberLEDs = 8;        // number of LEDs defining the number of rows of the settings matrix.
const int matrixLength = 5;      // matrix length. Needs to be a constant int.
int settings[numberLEDs][matrixLength];             // Initiate 8 x n matrix. 

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
      case 'p':
        printCurrentSettings();
        break;
      case '1':  
        inputString = "";
        stringComplete = false;
        Serial.println("Enter the values for row 1:");
        waitForNewString();
        updateSettingsMatrix(settings, 0, inputString);
        break;
      case '2':  
        inputString = "";
        stringComplete = false;
        Serial.println("Enter the values for row 2:");
        waitForNewString();
        updateSettingsMatrix(settings, 1, inputString);
        break;
      case '3':  
        inputString = "";
        stringComplete = false;
        Serial.println("Enter the values for row 3:");
        waitForNewString();
        updateSettingsMatrix(settings, 2, inputString);
        break;
      case '4':  
        inputString = "";
        stringComplete = false;
        Serial.println("Enter the values for row 4:");
        waitForNewString();
        updateSettingsMatrix(settings, 3, inputString);
        break;
      case '5':  
        inputString = "";
        stringComplete = false;
        Serial.println("Enter the values for row 5:");
        waitForNewString();
        updateSettingsMatrix(settings, 4, inputString);
        break;
      case '6':  
        inputString = "";
        stringComplete = false;
        Serial.println("Enter the values for row 6:");
        waitForNewString();
        updateSettingsMatrix(settings, 5, inputString);
        break;
      case '7':  
        inputString = "";
        stringComplete = false;
        Serial.println("Enter the values for row 7:");
        waitForNewString();
        updateSettingsMatrix(settings, 6, inputString);
        break;
      case '8':  
        inputString = "";
        stringComplete = false;
        Serial.println("Enter the values for row 8:");
        waitForNewString();
        updateSettingsMatrix(settings, 7, inputString);
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

int updateSettingsMatrix(int settings[numberLEDs][matrixLength], int selectedRow, String inputString) {
  // This function updates settings matrix by accepting a string, converting it to array and 
  // appending to settingsMatrix 
  inputString += ',';                                 // Add a comma at the end of the input string to make life easier      
  String vectorString = "";                           // Set a vector string which will be appended with chars 
  int numberOfCommas = -1;                            // Comma counter, zero indexed language, so start from -1
        
  // Loop through input string. if not comma, append to vectorString
  // If comma, assign the completed vectorString to a vector index.
  for(int i =0; i < inputString.length(); i++ ) {
    char c = inputString[i];
    if (c != ',') {
      vectorString += c;
    }
    else {
      numberOfCommas += 1;
      settings[selectedRow][numberOfCommas] = vectorString.toInt();
      vectorString = "";            
    }
  }

  return settings[8][matrixLength];
}

void printCurrentSettings() {
  int numRows = sizeof(settings)/sizeof(settings[0]);
  int numCols = sizeof(settings[0])/sizeof(settings[0][0]);
  for(int r =0; r < numRows; r++ ) {
    Serial.print("\n");
    for(int c =0; c < numCols; c++ ) {
      Serial.print(settings[r][c]);
      Serial.print(" ");
    }    
  }
  Serial.print("\n");  
}
