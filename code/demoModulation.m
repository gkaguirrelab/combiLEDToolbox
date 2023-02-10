
% Open a CombiLEDcontrol object
obj = CombiLEDcontrol();

% Establish a serial connection
obj.serialOpen;

% Send some values to set up that define a compound L-cone modulation described in
% Rider & Stockman 2018 PNAS
% M, sinusoidal modulation at 10 Hz with
% a 0.5 Hz AM envelope
obj.setFrequency(5);
obj.setAMIndex(1);
obj.setAMValues([0.2,1]);

compoundHarmonics=[1,3,4,0,0];
compoundAmplitudes=[0.5,1,1,0,0];
compoundPhases=deg2rad([0,333,226,0,0]);
obj.setCompoundModulation(compoundHarmonics,compoundAmplitudes,compoundPhases)

pause

% Start the modulation, wait 3 seconds, present a blink attention event,
% wait 2 more seconds, then stop the modulation
obj.runModulation;
pause(2.5)
obj.blink;
pause(2.5)
obj.stopModulation;

% Close the serial connection
obj.serialClose;
