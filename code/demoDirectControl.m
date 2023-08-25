
% Open a CombiLEDcontrol object
obj = CombiLEDcontrol();

% Device settings are given as a vector of floats in the range of 0-1.
mySettings = [1,0,0,0,0,0,0,0];

% Send the settings
obj.setPrimaries(mySettings);
pause

% Close the device
obj.serialClose;
clear obj
