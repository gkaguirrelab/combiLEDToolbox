% Housekeeping
clear
close all

% Define a location to save data
subjectID = 'hero_gka';
modDirection = 'LightFlux';
saveDataDir = fullfile('~/Desktop/flickerPsych',subjectID,modDirection);

% Create a directory for the subject
if ~isfolder(saveDataDir)
    mkdir(saveDataDir)
end

% Define the parameter space within which we will make measurements
RefContrastSet = [0.1, 0.8];
nRefContrasts = length(RefContrastSet);
TestContrastSet = [0.05, 0.1, 0.2, 0.4, 0.8];
nTestContrasts = length(TestContrastSet);
TestFreqSet = [6,10,14,20,18];
nTestFreqs = length(TestFreqSet);

% Create or load a tensor in which we will track our measurements
filename = fullfile(saveDataDir,'measurementRecord.mat');
if isfile(filename)
    load(filename,'measurementRecord');
else
    measurementRecord = zeros(nRefContrasts,nTestContrasts,nTestFreqs);
    save(filename,'measurementRecord');
end

% Create or load a modulation and save it to the dataDir
filename = fullfile(saveDataDir,'modResult.mat');
if isfile(filename)
    load(filename,'modResult');
else
    modResult = designModulation('LightFlux','primaryHeadroom',0.05);
    save(filename,'modResult');
end

% Set up the CombiLED
clear combiLEDObj
combiLEDObj = CombiLEDcontrol('verbose',false);

% Send the modulation direction to the CombiLED
combiLEDObj.setSettings(modResult);
combiLEDObj.setBackground(modResult.settingsBackground);

% Select a stimulus triplet to measure
measureCount = max(measurementRecord(:))+1;
availMeasureIdx = find(measurementRecord==0);
availMeasureIdx = availMeasureIdx(randperm(length(availMeasureIdx)));
measureRecordIdx = availMeasureIdx(1);
[IdxX,IdxY,IdxZ] = ind2sub(size(measurementRecord),measureRecordIdx);

% Extract the stimulus values
ReferenceContrast = RefContrastSet(IdxX);
TestContrast = TestContrastSet(IdxY);
TestFrequency = TestFreqSet(IdxZ);

% Instantiate the psychometric object
clear psychObj
combiLEDObj = [];
psychObj = CollectFreqMatchTriplet(combiLEDObj,...
    TestContrast,TestFrequency,ReferenceContrast,...
    'simulateStimuli',false,'simulateResponse',false,...
    'verbose',true);

% Loop through ~5 minute measurement periods
stillMeasuring = true;
while stillMeasuring

    msg = GetWithDefault('Press enter to start, q to quit','');

    if strcmp(msg,'q')
        stillMeasuring = false;
    else

        % Present 25 trials (about 5 minutes)
        for ii=1:25
            psychObj.presentTrial;
        end
    end
end

% Save the psychObj
fileStem = [subjectID '_' modDirection '_' sprintf('%02d',measureCount) ...
    '_' strrep(num2str(ReferenceContrast),'.','x') ...
    '_' strrep(num2str(TestContrast),'.','x') ...
    '_' strrep(num2str(TestFrequency),'.','x') '.mat'];
filename = fullfile(saveDataDir,fileStem);
save(filename,'psychObj');

% Update and save the measurementRecord
measurementRecord(measureRecordIdx) = measureCount;
filename = fullfile(saveDataDir,'measurementRecord.mat');
save(filename,'measurementRecord');

% Report the results for this measurement
[~, recoveredParams]=psychObj.reportParams;
psychObj.plotOutcome

