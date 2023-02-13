
% Open a CombiLEDcontrol object
obj = CombiLEDcontrol();

% Establish a serial connection
obj.serialOpen;

% Modulation demos
modDemos = {...
    'melanopsin pulses', ...
    'Rider & Stockman distortion red', ...
    'S-cone flicker distortion', ...
    'penumbral cone flicker', ...
    'light flux flicker', ...
    'L–M slow modulation' ...
    };

% Present the options
charSet = [97:97+25, 65:65+25];
fprintf('\nSelect a modDemos:\n')
for pp=1:length(modDemos)
    optionName=['\t' char(charSet(pp)) '. ' modDemos{pp} '\n'];
    fprintf(optionName);
end

choice = input('\nYour choice (return for done): ','s');
idx = 0;
if ~isempty(choice)
    choice = int32(choice);
    idx = find(charSet == choice);
    notDone = true;
else
    notDone = false;
end

switch idx
    case 1
        melDemo(obj)
    case 2
        riderStockmanDemo(obj)
    case 3
        SConeDistortion(obj)
    case 4
        penumbralConeFlicker(obj)
    case 5
        lightFluxFlicker(obj)
    case 6
        slowLminusM(obj)
end

obj.startModulation;

%{
obj.stopModulation;
obj.serialClose;
%}


% Send some values to set up that define a compound L-cone modulation described in
% Rider & Stockman 2018 PNAS

function melDemo(obj)
    modResult = designModulation('Mel','observerAgeInYears',53);
    obj.setSettings(modResult.settings);
    obj.setWaveformIndex(2);
    obj.setFrequency(0.2);
    obj.setAMIndex(2);
    obj.setAMValues([0.2,0.5]);
end

function lightFluxFlicker(obj)
    modResult = designModulation('LMS');
    obj.setSettings(modResult.settings);
    obj.setWaveformIndex(1);
    obj.setFrequency(48);
    obj.setAMIndex(1);
    obj.setAMValues([1,1]);
end

function SConeDistortion(obj)
    modResult = designModulation('S_foveal');
    obj.setSettings(modResult.settings);
    obj.setWaveformIndex(1);
    obj.setFrequency(30);
    obj.setAMIndex(1);
    obj.setAMValues([1,1]);
end

function riderStockmanDemo(obj)
    modResult = designModulation('L_foveal');
    obj.setSettings(modResult.settings);
    obj.setWaveformIndex(5);
    obj.setFrequency(5);
    obj.setAMIndex(1);
    obj.setAMValues([0.33,1]);
    compoundHarmonics=[1,3,4,0,0];
    compoundAmplitudes=[0.5,1,1,0,0];
    compoundPhases=deg2rad([0,333,226,0,0]);
    obj.setCompoundModulation(compoundHarmonics,compoundAmplitudes,compoundPhases)
end

function slowLminusM(obj)
    modResult = designModulation('LminusM_wide','searchBackground',false);
    obj.setSettings(modResult.settings);
    obj.setBackground(modResult.backgroundPrimary);
    obj.setWaveformIndex(1);
    obj.setFrequency(1);
end
