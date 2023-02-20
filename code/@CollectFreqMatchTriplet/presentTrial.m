function obj = presentTrial(obj)

% Get the questData
questData = obj.questData;

% Get the current trial index
currTrialIdx = size(questData.trialData,1)+1;

% Determine if we are simulating the stimuli
simulateStimuli = obj.simulateStimuli;
simulateResponse = obj.simulateResponse;

% Determine if we are giving feedback on each trial
giveFeedback = obj.giveFeedback;

% The contrast levels of the stimuli are set by the calling routine
TestContrast = obj.TestContrast;
ReferenceContrast = obj.ReferenceContrast;

% The test frequency is set by the calling function
TestFrequency = obj.TestFrequency;

% The frequency parameters are provided by Quest+, but must be transformed
% from relative, scaled, log units, to absolute, linear frequency units.
qpStimParams = qpQuery(questData);
ref1Frequency = obj.inverseTransVals(qpStimParams(1),TestFrequency);
ref2Frequency = obj.inverseTransVals(qpStimParams(2),TestFrequency);

% Prepare the sounds
Fs = 8192; % Sampling Frequency
dur = 0.1; % Duration in seconds
t  = linspace(0, dur, round(Fs*dur));
lowTone = sin(2*pi*500*t);
midTone = sin(2*pi*750*t);
highTone = sin(2*pi*1000*t);
readySound = [lowTone midTone highTone];
correctSound = sin(2*pi*750*t);
incorrectSound = sin(2*pi*250*t);
badSound = [sin(2*pi*250*t) sin(2*pi*250*t)];

% Determine if we have random phase or not
if obj.randomizePhase
    refPhase = rand()*2*pi;
    testPhase = rand()*2*pi;
else
    refPhase = 0;
    testPhase = 0;
end

% Assemble the param sets
ref1Params = [ReferenceContrast,ref1Frequency,refPhase];
ref2Params = [ReferenceContrast,ref2Frequency,refPhase];
testParams = [TestContrast,TestFrequency,testPhase];

% Randomly pick which interval contains ref1
ref1Interval = 1+logical(round(rand()));

% Assign the stimuli to the intervals
switch ref1Interval
    case 1
        intOneParams = ref1Params;
        intTwoParams = ref2Params;
    case 2
        intOneParams = ref2Params;
        intTwoParams = ref1Params;
    otherwise
        error('Not a valid ref1Interval')
end

% Handle verbosity
if obj.verbose
    fprintf('Trial %d; test [%2.2f]; int1 [%2.2f]; int2 [%2.2f]...', ...
        currTrialIdx,testParams(2),intOneParams(2),intTwoParams(2));
end

%% Present the stimuli
if ~simulateStimuli

    % Alert the subject the trial is about to start
    sound(readySound, Fs);
    stopTime = tic() + 1e9;
    obj.waitUntil(stopTime);

    % Present two alternations of interval one reference and the test
    for ii=1:2

        % Prepare the first reference interval stimulus
        obj.CombiLEDObj.setContrast(intOneParams(1));
        obj.CombiLEDObj.setFrequency(intOneParams(2));
        obj.CombiLEDObj.setPhaseOffset(intOneParams(3));

        % Present a reference stimulus
        sound(lowTone, Fs);
        stopTime = tic() + obj.stimulusDurationSecs*1e9;
        obj.CombiLEDObj.startModulation;
        obj.waitUntil(stopTime);

        % Prepare the test stimulus
        obj.CombiLEDObj.setContrast(testParams(1));
        obj.CombiLEDObj.setFrequency(testParams(2));
        obj.CombiLEDObj.setPhaseOffset(testParams(3));

        % Present the test stimulus.
        sound(midTone, Fs);
        stopTime = tic() + obj.stimulusDurationSecs*1e9;
        obj.CombiLEDObj.startModulation;
        obj.waitUntil(stopTime);
    end

    % ISI
    stopTime = stopTime + obj.interStimulusIntervalSecs*1e9;
    obj.waitUntil(stopTime);

    % Present two alternations of interval two reference and the test
    for ii=1:2

        % Prepare the first reference interval stimulus
        obj.CombiLEDObj.setContrast(intTwoParams(1));
        obj.CombiLEDObj.setFrequency(intTwoParams(2));
        obj.CombiLEDObj.setPhaseOffset(intTwoParams(3));

        % Present a reference stimulus
        sound(highTone, Fs);
        stopTime = tic() + obj.stimulusDurationSecs*1e9;
        obj.CombiLEDObj.startModulation;
        obj.waitUntil(stopTime);

        % Prepare the test stimulus
        obj.CombiLEDObj.setContrast(testParams(1));
        obj.CombiLEDObj.setFrequency(testParams(2));
        obj.CombiLEDObj.setPhaseOffset(testParams(3));

        % Present the test stimulus.
        sound(midTone, Fs);
        stopTime = tic() + obj.stimulusDurationSecs*1e9;
        obj.CombiLEDObj.startModulation;
        if ii==1
            % Only wait it is the first cycle. On the second cycle we jump
            % right to the response interval for the inpatient subject.
            obj.waitUntil(stopTime);
        end
    end

    % Start the response interval
    if ~simulateResponse
        [intervalChoice, responseTimeSecs] = obj.getResponse;
    else
        [intervalChoice, responseTimeSecs] = obj.getSimulatedResponse(qpStimParams,ref1Interval);
    end

    % Make sure the stimulus has stopped
    obj.CombiLEDObj.stopModulation;

else

    % Start the response interval
    if ~simulateResponse
        [intervalChoice, responseTimeSecs] = obj.getResponse;
    else
        [intervalChoice, responseTimeSecs] = obj.getSimulatedResponse(qpStimParams,ref1Interval);
    end

end

% Determine if the subject has selected reference One or Two
if ~isempty(intervalChoice)
    validResponse = true;
    if ref1Interval==intervalChoice
        % The subject said that reference 1 is more similar to the test
        outcome = 1;
    else
        outcome = 2;
    end
else
    outcome = nan;
    validResponse = false;
end

if obj.verbose
    fprintf('choice = %d', intervalChoice);
end

% Handle feedback at the end of the trial
if giveFeedback && validResponse
    % If we are giving feedback, determine if the subject correctly
    % selected the interval with the frequency that is closer to the test
    [~,correctReference] = min(abs(qpStimParams));
    if outcome == correctReference
        if ~simulateStimuli
            sound(correctSound, Fs);
        end
        if obj.verbose
            fprintf('; correct');
        end
    else
        if ~simulateStimuli
            sound(incorrectSound, Fs);
        end
        if obj.verbose
            fprintf('; incorrect');
        end
    end
    if ~simulateStimuli
        obj.waitUntil(tic()+5e8);
    end
end

if obj.verbose
    fprintf('\n');
end

if ~giveFeedback && validResponse
    % If we aren't giving feedback, but the subject did make a valid
    % response, we give the same, pleasing tone after every trial.
    sound(correctSound, Fs);
end

% Update questData if a valid response
if validResponse
    % Update questData
    questData = qpUpdate(questData,qpStimParams,outcome);

    % Add in the phase and interval information
    questData.trialData(currTrialIdx).phases = [refPhase,testPhase];
    questData.trialData(currTrialIdx).ref1Interval = ref1Interval;
    questData.trialData(currTrialIdx).responseTimeSecs = responseTimeSecs;
else
    % Buzz the bad trial
    if ~simulateStimuli
        sound(badSound, Fs);
    end
    obj.waitUntil(tic()+3e9);

    % Store a note that we had an invalid response
    if ~isfield(questData,'invalidResponseTrials')
        questData.invalidResponseTrials = currTrialIdx;
    else
        questData.invalidResponseTrials(end+1) = currTrialIdx;
    end
end

% Put questData back into the obj
obj.questData = questData;


end