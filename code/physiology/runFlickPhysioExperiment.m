function runFlickPhysioExperiment(subjectID,modDirection,varargin)
% 
%
%{
    subjectID = 'HERO_gka';
    modDirection = 'LightFlux';
    runDiscrimExperiment(subjectID,modDirection);
%}


% Parse the parameters
p = inputParser; p.KeepUnmatched = false;
p.addParameter('dropBoxBaseDir',getpref('combiLEDToolbox','dropboxBaseDir'),@ischar);
            p.addParameter('projectName','combiLED',@ischar);
            p.addParameter('approachName','flickerPhysio',@ischar);
p.addParameter('nBlocksToCollect',5,@isnumeric);
p.addParameter('testContrastSet',[0.05,0.1,0.2,0.4,0.8],@isnumeric);
p.addParameter('testFreqSetHz',[4,6,10,14,20,28,40],@isnumeric);
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
verbosePhysioObj = p.Results.verbosePhysioObj;
updateFigures = p.Results.updateFigures;

% Set our experimentName
experimentName = 'envelopeResponse';

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
    testFreqSetHz = measurementRecord.stimulusProperties.testFreqSetHz;
    testContrastSet = measurementRecord.stimulusProperties.testContrastSet;
    nTrialsPerStim = measurementRecord.experimentProperties.nTrialsPerStim;
    nTrialsPerSession = measurementRecord.experimentProperties.nTrialsPerSession;
    nStimsPerSession = measurementRecord.experimentProperties.nStimsPerSession;
else
    testContrastSet = p.Results.testContrastSet;
    testFreqSetHz = p.Results.testFreqSetHz;

    % The number of stims and trials
    nTrialsPerStim = 10; % Total n trials per stimulus
    nTrialsPerSession = 40; % nTrials in a session
    nStimsPerSession = 40; % nStimuli that will be intermixed in a session

    % Store the values
    measurementRecord.subjectProperties.subjectID = subjectID;
    measurementRecord.subjectProperties.observerAgeInYears = p.Results.observerAgeInYears;
    measurementRecord.experimentProperties.modDirection = modDirection;
    measurementRecord.experimentProperties.experimentName = experimentName;
    measurementRecord.experimentProperties.pupilDiameterMm = p.Results.pupilDiameterMm;
    measurementRecord.stimulusProperties.testContrastSet = testContrastSet;
    measurementRecord.stimulusProperties.testFreqSetHz = testFreqSetHz;
    measurementRecord.experimentProperties.nTrialsPerStim = nTrialsPerStim;
    measurementRecord.experimentProperties.nTrialsPerSession = nTrialsPerSession;
    measurementRecord.experimentProperties.nStimsPerSession = nStimsPerSession;
    measurementRecord.trialCount = zeros(length(testContrastSet),length(testFreqSetHz));
    measurementRecord.sessionData = [];

    % Save the file
    filename = fullfile(saveDataDir,'measurementRecord.mat');
    save(filename,'measurementRecord');
end

% Select the stimuli to test for this session. We select randomly from the
% set of stimuli that have the lowest number of collected trials.
trialCountSet = sort(unique(measurementRecord.trialCount(:)));

% First check if we are done
if min(trialCountSet) >= nTrialsPerStim
    fprintf('Done with this experiment!\n')
    return
end

% Find some stimuli that need measuring
countSetIdx = 1;
nStimsStillNeeded = nStimsPerSession;
stimIdx = [];
stillLooking = true;
while stillLooking
    availStimIdx = find(measurementRecord.trialCount==trialCountSet(countSetIdx));
    nAvail = length(availStimIdx);
    if nAvail == 0
        countSetIdx = countSetIdx+1;
        if min(measurementRecord.trialCount(:))>=nTrialsPerStim
            fprintf('Done with this experiment!\n')
            return
        end
    end
    if nAvail >= nStimsStillNeeded
        availStimIdx = availStimIdx(randperm(length(availStimIdx)));
        stimIdx = [stimIdx; availStimIdx(1:nStimsStillNeeded)];
        stillLooking = false;
    end
    if nAvail < nStimsStillNeeded
        availStimIdx = availStimIdx(randperm(length(availStimIdx)));
        stimIdx = [stimIdx; availStimIdx];
        nStimsStillNeeded = nStimsStillNeeded - length(availStimIdx);
        countSetIdx = countSetIdx+1;
    end
end

% Randomly order the stimIdx, so that the order of the intermixed stimuli
% will vary on every pass
stimIdx = stimIdx(randperm(length(stimIdx)));

% Set up the variables that hold this session information
fprintf('Preparing physio objects...');
sessionData = struct();
sessionData.stimIdx = stimIdx;
for ii=1:nStimsPerSession
    [IdxX,IdxY] = ind2sub([length(testContrastSet),length(testFreqSetHz)],stimIdx(ii));
    sessionData.measureIdx(ii) = stimIdx(ii);
    sessionData.testContrast(ii) = testContrastSet(IdxX);
    sessionData.testFreqHz(ii) = testFreqSetHz(IdxY);
    sessionData.fileStem{ii} = [subjectID '_' modDirection '_' experimentName ...
        '_' strrep(num2str(sessionData.testContrast(ii)),'.','x') ...
        '_' strrep(num2str(sessionData.testFreqHz(ii)),'.','x')];
    % Assemble the stimulus inputs
    testFreqHz = sessionData.testFreqHz(ii);
    testContrast = testContrastSetMatrix(IdxX,IdxY);
    % Create or load the physio objects
    filename = fullfile(saveDataDir,[sessionData.fileStem{ii} '.mat']);
    if isfile(filename)
        tmpObj = load(filename,'physioObj');
        sessionObj{ii} = tmpObj.physioObj;
        clear tmpObj
        sessionObj{ii}.CombiLEDObj = CombiLEDObj;
        % Initiate the CombiLED settings
        sessionObj{ii}.initializeDisplay;
    else
        sessionObj{ii} = FlickerPhysio(CombiLEDObj,...
            subjectID,modDirection,experimentName, ...
            'stimFreqHz',testFreqHz,'stimContrast',testContrast,...
            'verbose',verbosePhysioObj);
    end
    % Update the console text
    fprintf([num2str(ii) '...']);
end
fprintf('\n');

% Start the session
if ~simulateResponse
    fprintf('Press any key to start trials\n');
    pause
end

% Store the block start time
for ii=1:nStimsPerSession
    sessionObj{ii} .blockStartTimes(end+1) = datetime();
end

% Present nTrialsPerSession. We repeat trials that did not elicit a valid
% response (wrong key, or outside of response interval)
physioObjIdx = 1;
trialIdx = 1;
while trialIdx<=nTrialsPerSession
    validResponse = sessionObj{physioObjIdx}.presentTrial;
    if validResponse
        trialIdx = trialIdx + 1;
        physioObjIdx = physioObjIdx + 1;
        if physioObjIdx > nStimsPerSession
            physioObjIdx = 1;
        end
    end
end

% Play a "done" tone
if ~simulateResponse
    Fs = 8192; % Sampling Frequency
    dur = 0.1; % Duration in seconds
    t  = linspace(0, dur, round(Fs*dur));
    lowTone = sin(2*pi*500*t);
    midTone = sin(2*pi*750*t);
    highTone = sin(2*pi*1000*t);
    doneSound = [highTone midTone lowTone];
    donePlayer = audioplayer(doneSound,Fs);
    donePlayer.play;
    pause(0.5);
end

% Save the sessionObjs and create and save an updated figure
for ii=1:nStimsPerSession
    % physio object
    fileStem = sessionData.fileStem{ii};
    filename = fullfile(saveDataDir,[fileStem '.mat']);
    clear physioObj
    physioObj = sessionObj{ii};
    % empty the CombiLEDObj handle
    physioObj.CombiLEDObj = [];
    save(filename,'physioObj');
end

% Update and save the measurementRecord. First transfer fields from the
% sessionData.
fields = fieldnames(sessionData);
for ff = 1:length(fields)
    if ff==1
        measurementRecord.sessionData(end+1).(fields{ff}) = sessionData.(fields{ff});
    end
    measurementRecord.sessionData(end).(fields{ff}) = sessionData.(fields{ff});
end

% Update the trialCount record
measurementRecord.trialCount(sessionData.stimIdx) = ...
    measurementRecord.trialCount(sessionData.stimIdx)+(nTrialsPerSession/nStimsPerSession);

% Save it
filename = fullfile(saveDataDir,'measurementRecord.mat');
save(filename,'measurementRecord');

end

