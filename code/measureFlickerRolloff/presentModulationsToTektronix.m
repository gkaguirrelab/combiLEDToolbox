% Made measurements using the Tektronix TDS2002B Oscilloscope, with a UDT
% radiometric filter, model 115-9.
%
% The modulation is 90% light flux; we use 5% headroom to keep away from
% the imperfect gamma control at the boundaries of the settings.
%
% Each modulation was measured using the Tektronix and a CSV file saved.
% 
% These measurements were made for OneLight and CombiLED modulations. The
% measurements were repeated for the CombiLED, but using an OSI
% optoelectronics photodiode (10D, 11-01-004) with reportedly higher
% temporal sampling.
%

% Open a CombiLEDcontrol object
obj = CombiLEDcontrol();

modResult = designModulation('LightFlux','primaryHeadRoom',0.05);
obj.setSettings(modResult);
obj.setBackground(modResult.settingsBackground);
obj.setWaveformIndex(1);
obj.setContrast(1);


freqsToTest = [8, 10, 16, 20, 32, 40, 64, 80];

% First loop over frequencies
for ff=1:length(freqsToTest)

    fprintf('Presenting %d Hz\n',freqsToTest(ff));
    obj.setFrequency(freqsToTest(ff));
    obj.startModulation();
    pause;
    
end