% Code that interleaves psychometric measurements for different "triplets"
% of stimulus parameters in a measurement of the double-reference 2AFC
% technique of Jogan & Stocker. The code manages a series of files that
% store the data from the experiment. As configured, each testing "session"
% has 20 trials and is about 4 minutes in duration. A complete measurement
% of 100 trials for each of the 50 triplets, would take 4*(100*50)/20
%
%   16 hours 40 mins = 4*(100*50)/20
%
% Might need to decrease the number of triplets, or accept fewer than 100
% trials per triplet.

% Housekeeping
clear
close all

% Set a random seed
rng('shuffle');

% Initiate the PsychJava code. This silences a warning and prevents a
% problem with recording the first trial on startup
warnState = warning();
warning('off','MATLAB:Java:DuplicateClass');
PsychJavaTrouble();
warning(warnState);

% Simulation and verbose
simulateStimuli = false;
simulateResponse = false;
verboseCombiLED = false;
verbosePsychObj = true;
giveFeedback = true;
updateFigures = true;

% Define a location to save data
subjectID = 'Demo';
modDirection = 'LightFlux';
observerAgeInYears = 40;
pupilDiameterMm = 3;
saveDataDir = fullfile('~/Desktop/flickerPsych',subjectID,modDirection);

% Create a directory for the subject
if ~isfolder(saveDataDir)
    mkdir(saveDataDir)
end

% Create or load a modulation and save it to the dataDir
filename = fullfile(saveDataDir,'modResult.mat');
if isfile(filename)
    load(filename,'modResult');
else
    modResult = designModulation(modDirection,...
        'observerAgeInYears',observerAgeInYears,'pupilDiameterMm',pupilDiameterMm, ...
        'primaryHeadroom',0.00);
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
    RefContrastSet = measurementRecord.stimulusProperties.RefContrastSet;
    TestContrastSet = measurementRecord.stimulusProperties.TestContrastSet;
    TestFreqSet = measurementRecord.stimulusProperties.TestFreqSet;
    nTrialsPerPass = measurementRecord.experimentProperties.nTrialsPerPass;
    nPasses = measurementRecord.experimentProperties.nPasses;
    nTripletsPerPass = measurementRecord.experimentProperties.nTripletsPerPass;
else
    % The stimulus and experiment properties
    RefContrastSet = [0.4];
    TestContrastSet = [0.2, 0.8];
    TestFreqSet = [10,20];
    ReferenceFrequencySet = [3, 4, 6, 8, 10, 12, 14, 16, 20, 24, 28, 32, 40];
    nTrialsPerPass = 20; % The number of trials in each pass (about 4.5 minutes)
    nPasses = 5; % The number of nTrialsPerPass trial passes for each triplet
    nTripletsPerPass = 4; % The number of triplets that will be intermixed in a pass

    % Check that we each session will have the same number of trials for
    % each triplet
    assert( mod(nTrialsPerPass,nTripletsPerPass)==0 );

    % Check that we can do an integer number of sessions
    assert( mod((length(RefContrastSet)*length(TestContrastSet)*length(TestFreqSet)*nPasses),(nTripletsPerPass/nTrialsPerPass))==0 );

    % Store the values
    measurementRecord.subjectProperties.subjectID = subjectID;
    measurementRecord.subjectProperties.modDirection = modDirection;
    measurementRecord.subjectProperties.observerAgeInYears = observerAgeInYears;
    measurementRecord.subjectProperties.pupilDiameterMm = pupilDiameterMm;
    measurementRecord.stimulusProperties.RefContrastSet = RefContrastSet;
    measurementRecord.stimulusProperties.TestContrastSet = TestContrastSet;
    measurementRecord.stimulusProperties.TestFreqSet = TestFreqSet;
    measurementRecord.experimentProperties.nTrialsPerPass = nTrialsPerPass;
    measurementRecord.experimentProperties.nPasses = nPasses;
    measurementRecord.experimentProperties.nTripletsPerPass = nTripletsPerPass;
    measurementRecord.trialCount = zeros(length(RefContrastSet),length(TestContrastSet),length(TestFreqSet));
    measurementRecord.sessionData = [];
    save(filename,'measurementRecord');
end

% Define the parameter space within which we will make measurements
nRefContrasts = length(RefContrastSet);
nTestContrasts = length(TestContrastSet);
nTestFreqs = length(TestFreqSet);

% Select the triplets to test for this pass. We select randomly from the
% set of triplets that have the lowest number of collected trials.
trialCountSet = sort(unique(measurementRecord.trialCount(:)));
countSetIdx = 1;
nPassesStillNeeded = nTripletsPerPass;
passIdx = [];
stillLooking = true;
while stillLooking
    availPassIdx = find(measurementRecord.trialCount==trialCountSet(countSetIdx));
    nAvail = length(availPassIdx);
    if nAvail == 0
        countSetIdx = countSetIdx+1;
        if min(measurementRecord.trialCount(:))<=(nPasses*nTrialsPerPass)
            fprintf('Done with this experiment!\n')
            stillLooking = false;
            return
        end
    end
    if nAvail >= nPassesStillNeeded
        availPassIdx = availPassIdx(randperm(length(availPassIdx)));
        passIdx = [passIdx availPassIdx(1:nPassesStillNeeded)];
        stillLooking = false;
    end
    if nAvail < nTripletsPerPass
        availPassIdx = availPassIdx(randperm(length(availPassIdx)));
        passIdx = [passIdx availPassIdx];
        nPassesStillNeeded = nPassesStillNeeded - length(availPassIdx);
        countSetIdx = 2;
    end
end

% Set up the variables that hold this session information
fprintf('Preparing psychometric objects...');
sessionData = struct();
sessionData.passIdx = passIdx;
for ii=1:nTripletsPerPass
    [IdxX,IdxY,IdxZ] = ind2sub([nRefContrasts, nTestContrasts, nTestFreqs],passIdx(ii));
    sessionData.measureIdx(ii,:) = [IdxX,IdxY,IdxZ];
    sessionData.ReferenceContrast(ii) = RefContrastSet(IdxX);
    sessionData.TestContrast(ii) = TestContrastSet(IdxY);
    sessionData.TestFrequency(ii) = TestFreqSet(IdxZ);
    sessionData.fileStem{ii} = [subjectID '_' modDirection ...
        '_' strrep(num2str(sessionData.ReferenceContrast(ii)),'.','x') ...
        '_' strrep(num2str(sessionData.TestContrast(ii)),'.','x') ...
        '_' strrep(num2str(sessionData.TestFrequency(ii)),'.','x')];

    % Create or load the psychometric objects
    filename = fullfile(saveDataDir,[sessionData.fileStem{ii} '.mat']);
    if isfile(filename)
        tmpObj = load(filename,'psychObj');
        sessionObj{ii} = tmpObj.psychObj;
        clear tmpObj
        sessionObj{ii}.CombiLEDObj = CombiLEDObj;
        % Initiate the CombiLED settings
        sessionObj{ii}.initializeDisplay;
    else
        sessionObj{ii} = CollectFreqMatchTriplet(CombiLEDObj,...
            sessionData.TestContrast(ii),sessionData.TestFrequency(ii),sessionData.ReferenceContrast(ii),...
            'ReferenceFrequencySet',ReferenceFrequencySet,...
            'simulateStimuli',simulateStimuli,'simulateResponse',simulateStimuli,...
            'giveFeedback',giveFeedback,'verbose',verbosePsychObj);
    end
    % Clear out the first, bad "getResponse". Not sure why but the first
    % call to this function after restart always fails. This fixes the
    % problem
    sessionObj{ii}.getResponse;
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
for ii=1:nTripletsPerPass
    sessionObj{ii} .blockStartTimes(end+1) = datetime();
end

% Present nTrialsPerPass (should be about 5 minutes). We repeat trials that
% did not elicit a valid response (wrong key, or outside of response
% interval)
psychObjIdx = 1;
trialIdx = 1;
while trialIdx<=nTrialsPerPass
    validResponse = sessionObj{psychObjIdx}.presentTrial;
    if validResponse
        trialIdx = trialIdx + 1;
        psychObjIdx = psychObjIdx + 1;
        if psychObjIdx > nTripletsPerPass
            psychObjIdx = 1;
        end
    end
end

% Play a "done" tone
Fs = 8192; % Sampling Frequency
dur = 0.1; % Duration in seconds
t  = linspace(0, dur, round(Fs*dur));
lowTone = sin(2*pi*500*t);
midTone = sin(2*pi*750*t);
highTone = sin(2*pi*1000*t);
doneSound = [highTone midTone lowTone];
donePlayer = audioplayer(doneSound,Fs);
donePlayer.play;

% Save the sessionObjs and create and save an updated figure
for ii=1:nTripletsPerPass
    % psychometric object
    fileStem = sessionData.fileStem{ii};
    filename = fullfile(saveDataDir,[fileStem '.mat']);
    clear psychObj
    psychObj = sessionObj{ii};
    % empty the CombiLEDObj handle
    psychObj.CombiLEDObj = [];
    save(filename,'psychObj');
    % figure
    if updateFigures
        figHandle = psychObj.plotOutcome('off');
        filename = fullfile(saveDataDir,[fileStem '.pdf']);
        saveas(figHandle,filename,'pdf')
    end
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
measurementRecord.trialCount(sessionData.passIdx) = ...
    measurementRecord.trialCount(sessionData.passIdx)+(nTrialsPerPass/nTripletsPerPass);

% Save it
filename = fullfile(saveDataDir,'measurementRecord.mat');
save(filename,'measurementRecord');

