function runCDTExperiment(subjectID,modDirection,...
    observerAgeInYears,pupilDiameterMm,varargin)
% Code that interleaves psychometric measurements for measurements of a
% contrast detection threshold in a 2AFC experiment. The purpose is to
% measure threshold sensitivity across a range of stimulus frequencies. The
% code manages a series of files that store the data from the experiment.
% As configured, each testing "session" has 20 trials and is about 4
% minutes in duration. A complete measurement of 100 trials for each of the
% 7 frequencies takes about 2 hours and 20 minutes.
%
% Examples:
%{
    subjectID = 'HERO_gka';
    modDirection = 'LightFlux';
    observerAgeInYears = 53;
    pupilDiameterMm = 3;
    runCDTExperiment(subjectID,modDirection,observerAgeInYears,pupilDiameterMm)
%}

% Parse the parameters
p = inputParser; p.KeepUnmatched = false;
p.addParameter('TestFreqSet',[3,6,10,14,20,28,40],@isnumeric);
p.addParameter('dataDirRoot','~/Desktop/flickerPsych',@ischar);
p.addParameter('simulateStimuli',false,@islogical);
p.addParameter('simulateResponse',false,@islogical);
p.addParameter('verboseCombiLED',false,@islogical);
p.addParameter('verbosePsychObj',false,@islogical);
p.addParameter('updateFigures',false,@islogical);
p.parse(varargin{:})

%  Pull out of the p.Results structure
simulateStimuli = p.Results.simulateStimuli;
simulateResponse = p.Results.simulateResponse;
verboseCombiLED = p.Results.verboseCombiLED;
verbosePsychObj = p.Results.verbosePsychObj;
updateFigures = p.Results.updateFigures;

% Set our psychType
psychType = 'CDT';

% Set a random seed
rng('shuffle');

% Initiate the PsychJava code. This silences a warning and prevents a
% problem with recording the first trial on startup
warnState = warning();
warning('off','MATLAB:Java:DuplicateClass');
PsychJavaTrouble();
warning(warnState);

% Define a location to save data
saveModDir = fullfile(p.Results.dataDirRoot,subjectID,modDirection);
saveDataDir = fullfile(p.Results.dataDirRoot,subjectID,modDirection,psychType);

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
        'observerAgeInYears',observerAgeInYears,...
        'pupilDiameterMm',pupilDiameterMm, ...
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
    TestFreqSet = measurementRecord.stimulusProperties.TestFreqSet;
    nTrialsPerPass = measurementRecord.experimentProperties.nTrialsPerPass;
    nPasses = measurementRecord.experimentProperties.nPasses;
    nStimsPerPass = measurementRecord.experimentProperties.nStimsPerPass;
else
    % The stimulus and experiment properties
    TestFreqSet = p.Results.TestFreqSet;
    nTrialsPerPass = 20; % The number of trials in each pass (about 4.5 minutes)
    nPasses = 5; % The number of nTrialsPerPass trial passes for each triplet
    nStimsPerPass = 4; % The number of frequencies that will be intermixed in a pass

    % Check that we each session will have the same number of trials for
    % each triplet
    assert( mod(nTrialsPerPass,nStimsPerPass)==0 );

    % Check that we can do an integer number of sessions
    assert( mod((length(TestFreqSet)*nPasses),(nTrialsPerPass/nStimsPerPass))==0 );

    % Store the values
    measurementRecord.subjectProperties.subjectID = subjectID;
    measurementRecord.subjectProperties.observerAgeInYears = observerAgeInYears;
    measurementRecord.experimentProperties.modDirection = modDirection;
    measurementRecord.experimentProperties.psychType = psychType;
    measurementRecord.experimentProperties.pupilDiameterMm = pupilDiameterMm;
    measurementRecord.stimulusProperties.TestFreqSet = TestFreqSet;
    measurementRecord.experimentProperties.nTrialsPerPass = nTrialsPerPass;
    measurementRecord.experimentProperties.nPasses = nPasses;
    measurementRecord.experimentProperties.nStimsPerPass = nStimsPerPass;
    measurementRecord.trialCount = zeros(1,length(TestFreqSet));
    measurementRecord.sessionData = [];
    save(filename,'measurementRecord');
end

% Select the stimuli to test for this pass. We select randomly from the
% set of stimuli that have the lowest number of collected trials.
trialCountSet = sort(unique(measurementRecord.trialCount(:)));

% First check if we are done
if min(trialCountSet) >= (nTrialsPerPass*nPasses)
    fprintf('Done with this experiment!\n')
    return
end

% Find some stimuli that need measuring
countSetIdx = 1;
nPassesStillNeeded = nStimsPerPass;
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
    if nAvail < nStimsPerPass
        availPassIdx = availPassIdx(randperm(length(availPassIdx)));
        passIdx = [passIdx availPassIdx];
        nPassesStillNeeded = nPassesStillNeeded - length(availPassIdx);
        countSetIdx = 2;
    end
end

% Randomly order the passIdx, so that the order of the intermixed stimuli
% will vary on every pass
passIdx = passIdx(randperm(length(passIdx)));

% Set up the variables that hold this session information
fprintf('Preparing psychometric objects...');
sessionData = struct();
sessionData.passIdx = passIdx;
for ii=1:nStimsPerPass
    IdxX = passIdx(ii);
    sessionData.measureIdx(ii) = IdxX;
    sessionData.TestFrequency(ii) = TestFreqSet(IdxX);
    sessionData.fileStem{ii} = [subjectID '_' modDirection '_' psychType ...
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
        sessionObj{ii} = PsychDetectionThreshold(CombiLEDObj,...
            sessionData.TestFrequency(ii),...
            'simulateStimuli',simulateStimuli,'simulateResponse',simulateStimuli,...
            'verbose',verbosePsychObj);
    end
    % Clear out the first, bad "getResponse". Not sure why but the first
    % call to this function after restart always fails. This fixes the
    % problem
    storeResponseDur = sessionObj{ii}.responseDurSecs;
    sessionObj{ii}.responseDurSecs = 0.1;
    sessionObj{ii}.getResponse;
    sessionObj{ii}.responseDurSecs = storeResponseDur;
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
for ii=1:nStimsPerPass
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
        if psychObjIdx > nStimsPerPass
            psychObjIdx = 1;
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
end

% Save the sessionObjs and create and save an updated figure
for ii=1:nStimsPerPass
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
    measurementRecord.trialCount(sessionData.passIdx)+(nTrialsPerPass/nStimsPerPass);

% Save it
filename = fullfile(saveDataDir,'measurementRecord.mat');
save(filename,'measurementRecord');

end
