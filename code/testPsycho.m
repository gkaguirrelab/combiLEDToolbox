combiLEDObj = CombiLEDcontrol('verbose',false);

% Get observer properties
modResult = designModulation('LightFlux');
combiLEDObj.setSettings(modResult);
combiLEDObj.setBackground(modResult.settingsBackground);
combiLEDObj.setWaveformIndex(1);
combiLEDObj.setAMIndex(0);
combiLEDObj.setDuration(3);

% Open a stairCase objects to start from a high and a low point
psychObj{1} = Collect2AFCStaircase(combiLEDObj,0.5,7.8082,0.8,'startHigh',true);
psychObj{2} = Collect2AFCStaircase(combiLEDObj,0.5,7.8082,0.8,'startHigh',false);

% Present 40 trials
for ii=1:40
    psychObj{1}.presentTrial;
    psychObj{2}.presentTrial;
end
