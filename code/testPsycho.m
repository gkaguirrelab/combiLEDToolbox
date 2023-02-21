combiLEDObj = CombiLEDcontrol('verbose',false);

% Send a particular modulation direction to the CombiLED
modResult = designModulation('LightFlux');
combiLEDObj.setSettings(modResult);
combiLEDObj.setBackground(modResult.settingsBackground);

%% For modulations up to 64 Hz, the max allowable contrast is 0.7

% Define a triplet
TestContrast = 0.15;
TestFrequency = 20;
ReferenceContrast = 0.3;

% Instantiate the psychometric object
clear psychObj
psychObj = CollectFreqMatchTriplet(combiLEDObj,...
    TestContrast,TestFrequency,ReferenceContrast,...
    'simulateStimuli',false,'simulateResponse',false,...
    'simulatePsiParams',[0.15, 0.35, -0.2],...
    'verbose',true);

% Get ready to rumble
fprintf('Press a key to start data collection\n')
pause

% Present 25 trials (about 5 minutes)
for ii=1:25
    psychObj.presentTrial;
end

[~, recoveredParams]=psychObj.reportParams
psychObj.plotOutcome

