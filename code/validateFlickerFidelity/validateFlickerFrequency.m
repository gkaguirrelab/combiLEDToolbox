% Made measurements using the Tektronix TDS2002B Oscilloscope, with a UDT
% radiometric filter, model 115-9.
% 
%

% Open a CombiLEDcontrol object
obj = CombiLEDcontrol();

modResult = designModulation('LightFlux','primaryHeadRoom',0.05);
obj.setSettings(modResult);
obj.setBackground(modResult.settingsBackground);
obj.setWaveformIndex(1);
obj.setContrast(1);


freqsToTest = logspace(log10(4),log10(128),11);

% First loop over frequencies
for ff=1:length(freqsToTest)

    obj.setFrequency(freqsToTest(ff));
    obj.startModulation();
    pause;
    
end