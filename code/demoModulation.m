
% Select a calibration file
cal = selectCal();

% Open a CombiLEDcontrol object
obj = CombiLEDcontrol('verbose',false);

% Update the gamma table
obj.setGamma(cal.processedData.gammaTable);

% Get observer properties
observerAgeInYears = str2double(GetWithDefault('Age in years','30'));
pupilDiameterMm = str2double(GetWithDefault('Pupil diameter in mm','3'));

% Get the photoreceptors for this observer
photoreceptors = photoreceptorDictionaryHuman('observerAgeInYears',observerAgeInYears,'pupilDiameterMm',pupilDiameterMm);

% Modulation demos
modDemos = {...
    'melPulses', ...
    'riderStockmanDistortion', ...
    'SConeDistortion', ...
    'lightFluxFlicker', ...
    'slowLminusM' ...
    'lightFluxShifted'
    };

% Present the options
charSet = [97:97+25, 65:65+25];
fprintf('\nSelect a modDemos:\n')
for pp=1:length(modDemos)
    optionName=['\t' char(charSet(pp)) '. ' modDemos{pp} '\n'];
    fprintf(optionName);
end
choice = input('\nYour choice (return for done): ','s');

% Obtain the mod result
if ~isempty(choice)
    choice = int32(choice);
    idx = find(charSet == choice);
    modResult = feval(modDemos{idx},obj,photoreceptors,cal);
end

% Plot the modulation
plotModResult(modResult);

% Pause and do a couple of cycles of presenting the modulation
obj.goDark;
pause
obj.startModulation;
pause
obj.stopModulation;
obj.goDark;
pause
obj.startModulation;
pause
obj.stopModulation;
obj.goDark;
pause
obj.startModulation;
pause
obj.goDark;
pause
obj.startModulation;
pause
obj.stopModulation;
obj.goDark;
pause
obj.startModulation;
pause
obj.stopModulation;
obj.goDark;
pause
obj.startModulation;
pause

% Clean up
obj.serialClose;
close all
clear




function modResult = melPulses(obj,photoreceptors,cal)
modResult = designModulation('Mel_shiftBackground',photoreceptors,cal);
obj.setSettings(modResult);
obj.setUnimodal();
obj.setWaveformIndex(2); % square-wave
obj.setFrequency(0.1);
obj.setAMIndex(2); % half-cosine windowing
obj.setAMFrequency(0.1);
obj.setAMValues([0.5,0]); % 0.5 second half-cosine on; second value unused
end

function modResult = lightFluxFlicker(obj,photoreceptors,cal)
modResult = designModulation('LightFlux',photoreceptors,cal);
obj.setSettings(modResult);
obj.setWaveformIndex(1);
obj.setFrequency(16);
obj.setContrast(1);
obj.setAMIndex(1);
obj.setAMFrequency(0.1);
end

function modResult = SConeDistortion(obj,photoreceptors,cal)
modResult = designModulation('S_foveal',photoreceptors,cal);
obj.setSettings(modResult);
obj.setWaveformIndex(1);
obj.setFrequency(30);
obj.setAMIndex(1);
obj.setAMFrequency(1);
end

function modResult = riderStockmanDistortion(obj,photoreceptors,cal)
% A compound L-cone modulation described in Rider & Stockman 2018 PNAS
modResult = designModulation('L_foveal',photoreceptors,cal);
obj.setSettings(modResult);
obj.setWaveformIndex(5);
obj.setFrequency(5);
obj.setAMIndex(1);
obj.setAMFrequency(1);
compoundHarmonics=[1,3,4,0,0];
compoundAmplitudes=[0.5,1,1,0,0];
compoundPhases=deg2rad([0,333,226,0,0]); % Should look red
%{
    compoundPhases=deg2rad([0,333,46,0,0]); % Should look green
%}
obj.setCompoundModulation(compoundHarmonics,compoundAmplitudes,compoundPhases);
end

function modResult = slowLminusM(obj,photoreceptors,cal)
modResult = designModulation('LminusM_wide',photoreceptors,cal);
obj.setSettings(modResult);
obj.setWaveformIndex(1);
obj.setFrequency(1);
obj.setAMIndex(0);
end

function modResult = lightFluxShifted(obj,photoreceptors,cal)
backgroundPrimary = [0.5222    0.4528    0.1896    0.5264    0.2302    0.3250    0.4875    0.4882]';

modResult = designModulation('LightFlux',photoreceptors,cal,...
    'searchBackground',false,...
    'contrastMatchConstraint',4,...
    'backgroundPrimary',backgroundPrimary);
obj.setSettings(modResult);
obj.setWaveformIndex(1);
obj.setAMIndex(2); % half-cosine windowing
obj.setAMFrequency(1/24);
obj.setAMValues([1.5,0]); % duration half-cosine ramp; second value unused
obj.setDuration(15);
obj.setFrequency(4);
end

