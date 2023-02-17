combiLEDObj = CombiLEDcontrol('verbose',false);

% Get observer properties
modResult = designModulation('LightFlux');
combiLEDObj.setSettings(modResult);
combiLEDObj.setBackground(modResult.settingsBackground);
combiLEDObj.setWaveformIndex(1);
combiLEDObj.setAMIndex(2);
combiLEDObj.setAMFrequency(0.5);
combiLEDObj.setDuration(2);

% Open a stairCase object
psychObj = CollectStaircase(combiLEDObj,0.5,16,0.5);

% Present 10 trials
for ii=1:10
psychObj.presentTrial;
end
