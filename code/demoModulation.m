
% Open a CombiLEDcontrol object
obj = CombiLEDcontrol();

% Get observer properties
observerAgeInYears = str2double(GetWithDefault('Age in years','30'));
pupilDiameterMm = str2double(GetWithDefault('Pupil diameter in mm','3'));

% Modulation demos
modDemos = {...
    'melPulses', ...
    'riderStockmanDistortion', ...
    'SConeDistortion', ...
    'lightFluxFlicker', ...
    'slowLminusM' ...
    };

% Present the options
charSet = [97:97+25, 65:65+25];
fprintf('\nSelect a modDemos:\n')
for pp=1:length(modDemos)
    optionName=['\t' char(charSet(pp)) '. ' modDemos{pp} '\n'];
    fprintf(optionName);
end

choice = input('\nYour choice (return for done): ','s');
if ~isempty(choice)
    choice = int32(choice);
    idx = find(charSet == choice);
    modResult = feval(modDemos{idx},obj,observerAgeInYears,pupilDiameterMm);
end

plotModResult(modResult);
obj.startModulation;

foo=1;

%{
obj.stopModulation;
obj.serialClose;
close all
clear
%}


% Send some values to set up that define a compound L-cone modulation described in
% Rider & Stockman 2018 PNAS

function modResult = melPulses(obj,observerAgeInYears,pupilDiameterMm)
    modResult = designModulation('Mel','observerAgeInYears',observerAgeInYears,'pupilDiameterMm',pupilDiameterMm);
    obj.setSettings(modResult);
    obj.setBackground(modResult.settingsLow);
    obj.setWaveformIndex(2);
    obj.setFrequency(0.1);
    obj.setAMIndex(2);
    obj.setAMValues([0.1,0.5]);
end

function modResult = lightFluxFlicker(obj,observerAgeInYears,pupilDiameterMm)
    modResult = designModulation('LightFlux','observerAgeInYears',observerAgeInYears,'pupilDiameterMm',pupilDiameterMm);
    obj.setSettings(modResult);
    obj.setBackground(modResult.settingsBackground);
    obj.setWaveformIndex(1);
    obj.setFrequency(48);
    obj.setAMIndex(0);
    obj.setAMValues([1,1]);
end

function modResult = SConeDistortion(obj,observerAgeInYears,pupilDiameterMm)
    modResult = designModulation('S_foveal','observerAgeInYears',observerAgeInYears,'pupilDiameterMm',pupilDiameterMm);
    obj.setSettings(modResult);
    obj.setBackground(modResult.settingsBackground);
    obj.setWaveformIndex(1);
    obj.setFrequency(30);
    obj.setAMIndex(1);
    obj.setAMValues([0.2,1]);
end

function modResult = riderStockmanDistortion(obj,observerAgeInYears,pupilDiameterMm)
    modResult = designModulation('L_foveal','observerAgeInYears',observerAgeInYears,'pupilDiameterMm',pupilDiameterMm);
    obj.setSettings(modResult);
    obj.setBackground(modResult.settingsBackground);
    obj.setWaveformIndex(5);
    obj.setFrequency(5);
    obj.setAMIndex(1);
    obj.setAMValues([0.333,1]);
    compoundHarmonics=[1,3,4,0,0];
    compoundAmplitudes=[0.5,1,1,0,0];
    compoundPhases=deg2rad([0,333,226,0,0]); % Should look red
    %{
    compoundPhases=deg2rad([0,333,46,0,0]); % Should look green
    %}
    obj.setCompoundModulation(compoundHarmonics,compoundAmplitudes,compoundPhases)
end

function modResult = slowLminusM(obj,observerAgeInYears,pupilDiameterMm)
    modResult = designModulation('LminusM_wide','observerAgeInYears',observerAgeInYears,'pupilDiameterMm',pupilDiameterMm);
    obj.setSettings(modResult);
    obj.setBackground(modResult.settingsBackground);
    obj.setWaveformIndex(1);
    obj.setFrequency(1);
end
