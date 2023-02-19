combiLEDObj = CombiLEDcontrol('verbose',true);

% Send a particular modulation direction to the CombiLED
modResult = designModulation('LightFlux');
combiLEDObj.setSettings(modResult);
combiLEDObj.setBackground(modResult.settingsBackground);

% When we simulate, we need to have a non-zero value for the bias
simulatePsiParams = [0.25, 0.1, -0.15];
psychObj = CollectFreqMatchTriplet(combiLEDObj,0.5,7.8082,0.75,'simulatePsiParams',simulatePsiParams);

fprintf('Press a key to start data collection\n')
pause

% Present 40 trials
for ii=1:200
    psychObj.presentTrial;
end
