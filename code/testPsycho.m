combiLEDObj = CombiLEDcontrol('verbose',false);

% Send a particular modulation direction to the CombiLED
modResult = designModulation('LightFlux');
combiLEDObj.setSettings(modResult);
combiLEDObj.setBackground(modResult.settingsBackground);

% When we simulate, we need to have a non-zero value for the bias
psychObj = CollectFreqMatchTriplet(combiLEDObj,0.5,7.8082,0.75);

fprintf('Press a key to start data collection\n')
pause

% Present 40 trials
for ii=1:40
    psychObj.presentTrial;
end
