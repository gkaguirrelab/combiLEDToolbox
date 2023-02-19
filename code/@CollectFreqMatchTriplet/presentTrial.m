function obj = presentTrial(obj)

% Get the questData
questData = obj.questData;

% Check if we are done presenting trials
currTrial = size(questData.trialData,1)+1;
if currTrial > obj.nTrials
    return
end

% Determine if we are simulating
simulateTrial = ~isempty(obj.simulatePsiParams);

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
intervalOneSound = sin(2*pi*500*t);
intervalTestSound = [sin(2*pi*750*t) sin(2*pi*750*t)];
intervalTwoSound = sin(2*pi*1000*t);
readySound = [intervalOneSound intervalTwoSound];
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

%% First reference interval
if ~simulateTrial

    % Prepare the first reference interval stimulus
    obj.CombiLEDObj.setContrast(intOneParams(1));
    obj.CombiLEDObj.setFrequency(intOneParams(2));
    obj.CombiLEDObj.setPhaseOffset(intOneParams(3));

    % Prepare the subject
    stopTime = tic() + 2*obj.interStimulusIntervalSecs*1e9;
    sound(readySound, Fs);
    obj.waitUntil(stopTime);

    % Present a reference stimulus
    stopTime = stopTime + obj.stimulusDurationSecs*1e9;
    obj.CombiLEDObj.startModulation;
    sound(intervalOneSound, Fs);
    obj.waitUntil(stopTime);

    %% Test interval

    % Prepare the test stimulus
    obj.CombiLEDObj.setContrast(testParams(1));
    obj.CombiLEDObj.setFrequency(testParams(2));
    obj.CombiLEDObj.setPhaseOffset(testParams(3));

    % ISI
    stopTime = stopTime + obj.interStimulusIntervalSecs*1e9;
    obj.waitUntil(stopTime);

    % Present the test stimulus.
    stopTime = stopTime + obj.stimulusDurationSecs*1e9;
    obj.CombiLEDObj.startModulation;
    sound(intervalTestSound, Fs);
    obj.waitUntil(stopTime);

    %% Second reference interval

    % Prepare the second reference interval stimulus
    obj.CombiLEDObj.setContrast(intTwoParams(1));
    obj.CombiLEDObj.setFrequency(intTwoParams(2));
    obj.CombiLEDObj.setPhaseOffset(intTwoParams(3));

    % ISI
    stopTime = stopTime + obj.interStimulusIntervalSecs*1e9;
    obj.waitUntil(stopTime);

    % Present the second reference interval stimulus. Allow the response
    % interval to start shortly after the stimulus starts
    stopTime = stopTime + obj.interStimulusIntervalSecs*1e9;
    obj.CombiLEDObj.startModulation;
    sound(intervalTwoSound, Fs);
    obj.waitUntil(stopTime);

    % Start the response interval
    [intervalChoice, responseTimeSecs] = obj.getResponse;

    % Make sure the stimulus has stopped
    obj.CombiLEDObj.stopModulation;

else

    % We are simulating. Just get a response
    [intervalChoice, responseTimeSecs] = obj.simulateResponse(qpStimParams,ref1Interval);

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
    validResponse = false;
end

% Update questData if a valid response
if validResponse
    % Update questData
    questData = qpUpdate(questData,qpStimParams,outcome);

    % Add in the phase and interval information
    questData.trialData(currTrial).phases = [refPhase,testPhase];
    questData.trialData(currTrial).ref1Interval = ref1Interval;
    questData.trialData(currTrial).responseTimeSecs = responseTimeSecs;
else
    % Buzz the bad trial
    sound(badSound, Fs);
    obj.waitUntil(tic()+3e9);

    % Store a note that we had an invalid response
    questData.trialData.invalidResponseTrials(end+1) = currTrial;
end

% Put questData back into the obj
obj.questData = questData;


end