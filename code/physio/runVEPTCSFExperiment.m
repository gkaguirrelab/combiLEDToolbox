function runVEPTCSFExperiment(subjectID,modDirection,varargin)
% 
%
%{
    subjectID = 'HERO_gka1';
    modDirection = 'LightFlux';
    runVEPTCSFExperiment(subjectID,modDirection);

%}


% Parse the parameters
p = inputParser; p.KeepUnmatched = false;
p.addParameter('dropBoxBaseDir',getpref('combiLEDToolbox','dropboxBaseDir'),@ischar);
            p.addParameter('projectName','combiLED',@ischar);
            p.addParameter('approachName','flickerPhysio',@ischar);
p.addParameter('stimContrastSet',[0,0.05,0.1,0.2,0.4,0.8],@isnumeric);
p.addParameter('stimFreqSetHz',[4,6,10,14,20,28,40],@isnumeric);
p.addParameter('observerAgeInYears',25,@isnumeric);
p.addParameter('fieldSizeDegrees',30,@isnumeric);
p.addParameter('pupilDiameterMm',4.2,@isnumeric);
p.addParameter('simulateStimuli',false,@islogical);
p.addParameter('simulateResponse',false,@islogical);
p.addParameter('verboseCombiLED',false,@islogical);
p.addParameter('verbosePhysioObj',true,@islogical);
p.addParameter('updateFigures',false,@islogical);
p.parse(varargin{:})

%  Pull out of the p.Results structure
simulateStimuli = p.Results.simulateStimuli;
simulateResponse = p.Results.simulateResponse;
verboseCombiLED = p.Results.verboseCombiLED;

% Set our experimentName
experimentName = 'ssVEPTCSF';

% Set a random seed
rng('shuffle');

% Define a location to save data
saveModDir = fullfile(...
    p.Results.dropBoxBaseDir,...
    p.Results.projectName,...
    p.Results.approachName,...
    subjectID,modDirection);

saveDataDir = fullfile(saveModDir,experimentName);

% Create a directory for the subject
if ~isfolder(saveDataDir)
    mkdir(saveDataDir)
end

% Create or load a modulation and save it to the saveModDir
filename = fullfile(saveModDir,'modResult.mat');
if isfile(filename)
    load(filename,'modResult');
else
    % We get away with using zero headroom, as we will always be using
    % contrast levels that are less that 100%
    modResult = designModulation(modDirection,...
        'observerAgeInYears',p.Results.observerAgeInYears,...
        'fieldSizeDegrees',p.Results.fieldSizeDegrees,...
        'pupilDiameterMm',p.Results.pupilDiameterMm, ...
        'primaryHeadroom',0);
    save(filename,'modResult');
end

% Handle the CombiLED object
if ~simulateStimuli
    % Set up the CombiLED
    CombiLEDObj = CombiLEDcontrol('verbose',verboseCombiLED);
    % Send the modulation direction to the CombiLED
    CombiLEDObj.setSettings(modResult);
    CombiLEDObj.setBackground(modResult.settingsBackground);
else
    CombiLEDObj = [];
end

% Create or load the measurementRecord
filename = fullfile(saveDataDir,'measurementRecord.mat');
if isfile(filename)
    load(filename,'measurementRecord');
    stimFreqSetHz = measurementRecord.stimulusProperties.stimFreqSetHz;
    stimContrastSet = measurementRecord.stimulusProperties.stimContrastSet;
    blockIdx = measurementRecord.blockIdx;
    freqIdxOrder = measurementRecord.experimentProperties.freqIdxOrder;
    contrastIdxOrderMatrix = measurementRecord.experimentProperties.contrastIdxOrderMatrix;
else
    % The trial sequence order
    freqIdxOrder = [4, 1, 6, 5, 3, 7, 2, 2, 5, 1, 7, 4, 6, 3, 3, 1, 5, 2, 4, 7, 6, 6, 1, 4, 2, 7, 3, 5, 5, 4, 3, 2, 6, 7, 1, 1, 2, 3, 6, 4, 5, 7, 7, 5, 6, 2, 1, 3, 4];
    contrastIdxOrderMatrix = readmatrix(fullfile(fileparts(mfilename('fullpath')),'t1i1_n6_Seqs.csv'));

    % The contrasts and frequencies themselves
    stimContrastSet = p.Results.stimContrastSet;
    stimFreqSetHz = p.Results.stimFreqSetHz;

    % The blockIdx
    blockIdx = 1;

    % Store the values
    measurementRecord.experimentProperties.freqIdxOrder = freqIdxOrder;
    measurementRecord.experimentProperties.contrastIdxOrderMatrix = contrastIdxOrderMatrix;
    measurementRecord.experimentProperties.modDirection = modDirection;
    measurementRecord.experimentProperties.experimentName = experimentName;
    measurementRecord.experimentProperties.pupilDiameterMm = p.Results.pupilDiameterMm;
    measurementRecord.subjectProperties.subjectID = subjectID;
    measurementRecord.subjectProperties.observerAgeInYears = p.Results.observerAgeInYears;
    measurementRecord.stimulusProperties.stimContrastSet = stimContrastSet;
    measurementRecord.stimulusProperties.stimFreqSetHz = stimFreqSetHz;
    measurementRecord.blockIdx = blockIdx;
    measurementRecord.blockData = [];

    % Save the file
    filename = fullfile(saveDataDir,'measurementRecord.mat');
    save(filename,'measurementRecord');
end

% First check if we are done
if blockIdx > length(freqIdxOrder)
    fprintf('Done with this experiment!\n')
    return
end

% Create the physio object
freqIdx = freqIdxOrder(blockIdx);
stimFreqHz = stimFreqSetHz(freqIdx);
stimContrastOrder = contrastIdxOrderMatrix(blockIdx,:);

obj = FlickerPhysio(CombiLEDObj,subjectID,modDirection,experimentName,...
    'blockIdx',blockIdx,...
    'stimFreqHz',stimFreqHz,...
    'stimContrastSet',stimContrastSet, ...
    'stimContrastOrder',stimContrastOrder);

% Start the block
if ~simulateResponse
    fprintf('Press any key to start trials\n');
    pause
    startTime = datetime();
    obj.collectTrial;
end

% Update and save the measurementRecord
measurementRecord.blockData(blockIdx).startTime = startTime;

% Get the vid delay
vidDelaySecs = nan;
while isnan(vidDelaySecs)
    vidDelaySecs = obj.pupilObj.calcVidDelay(1);
end
measurementRecord.blockData(blockIdx).vidDelaySecs = vidDelaySecs;

% Close the labjack
obj.vepObj.labjackOBJ.shutdown

% Update the trialCount record
measurementRecord.blockIdx = ...
    measurementRecord.blockIdx + 1;

% Save it
filename = fullfile(saveDataDir,'measurementRecord.mat');
save(filename,'measurementRecord');

end

