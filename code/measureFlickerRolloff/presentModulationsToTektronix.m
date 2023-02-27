% Made measurements using the Tektronix TDS2002B Oscilloscope, with a UDT
% photodiode / radiometric filter, model 115-9.
%
% The modulation is 90% light flux; we use 5% headroom to keep away from
% the imperfect gamma control at the boundaries of the settings.
%
% Each modulation was measured using the Tektronix and a CSV file saved.
% 
% These measurements were made for OneLight and CombiLED modulations. We
% can assume that the OneLight has essentially zero temporal roll-off in
% this frequency range. Given that, we use the OneLight measurements to
% obtain the temporal role-off of the photodiode, and then correct the
% measurements of the CombiLED for the photodiode attenuation.
%

% Open a CombiLEDcontrol object
obj = CombiLEDcontrol();

modResult = designModulation('LightFlux','primaryHeadRoom',0.05);
obj.setSettings(modResult);
obj.setBackground(modResult.settingsBackground);
obj.setWaveformIndex(1);
obj.setContrast(1);


% Frequencies at which measurements were made with the CombiLED and
% OneLight
freqsToTest = [8, 10, 16, 20, 32, 40, 64, 80];

% Frequencies at which measurements were made just with the CombiLED. These
% are the frequencies used in the perceptual experiments.
freqsToTest = [1, 2, 3, 4, 5, 6, 8, 10, 12, 14, 16, 20, 24, 28, 32, 40];

% First loop over frequencies
for ff=1:length(freqsToTest)

    fprintf('Presenting %d Hz\n',freqsToTest(ff));
    obj.setFrequency(freqsToTest(ff));
    obj.startModulation();
    pause;
    
end