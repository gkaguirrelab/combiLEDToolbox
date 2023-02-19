combiLEDObj = CombiLEDcontrol('verbose',false);

% Send a particular modulation direction to the CombiLED
modResult = designModulation('LightFlux');
combiLEDObj.setSettings(modResult);
combiLEDObj.setBackground(modResult.settingsBackground);

% Define a triplet
TestContrast = 0.5;
TestFrequency = 7;
ReferenceContrast = 0.75;

% Instantiate the psychometric object
psychObj = CollectFreqMatchTriplet(combiLEDObj,TestContrast,TestFrequency,ReferenceContrast);

% Get ready to rumble
fprintf('Press a key to start data collection\n')
pause

% Present 25 trials (about 5 minutes)
for ii=1:25
    psychObj.presentTrial;
end
