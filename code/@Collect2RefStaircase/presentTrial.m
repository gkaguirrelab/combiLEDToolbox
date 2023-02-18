function obj = presentTrial(obj)

% Check if we are done presenting trials
if obj.trialIdx > obj.nTrials
    return
end

% Prepare the sounds
Fs = 8192;                                     % Sampling Frequency
dur = 0.1;
t  = linspace(0, dur, round(Fs*dur));                        %  Time Vector
oneSound = sin(2*pi*500*t);                                   % Create Tone
twoSound = sin(2*pi*1000*t);                                   % Create Tone
readySound = [oneSound twoSound];                                   % Create Tone
badSound = [sin(2*pi*250*t) sin(2*pi*250*t)];

% Assemble the stimulus parameters
refContrast = obj.ReferenceContrast;
refFrequency = obj.ReferenceFrequency;
testContrast = obj.TestContrast;
testFrequency = obj.TestFrequencySet(obj.currentTestFreqIdx);

% Determine if we have random phase or not
if obj.randomizePhase
    refPhase = rand()*2*pi;
    testPhase = rand()*2*pi;
else
    refPhase = 0;
    testPhase = 0;
end

% Assemble the param sets
refParams = [refContrast,refFrequency,refPhase];
testParams = [testContrast,testFrequency,testPhase];

% Randomly pick interval contains the test
testInterval = 1+logical(round(rand()));

% Assign the stimuli to the intervals
switch testInterval
    case 1
        intOneParams = testParams;
        intTwoParams = refParams;
    case 2
        intOneParams = refParams;
        intTwoParams = testParams;
    otherwise
        error('The ref has to go somewhere')
end

% Prepare the first stimulus
obj.CombiLEDObj.setContrast(intOneParams(1));
obj.CombiLEDObj.setFrequency(intOneParams(2));
obj.CombiLEDObj.setPhaseOffset(intOneParams(3));

% Prepare the subject
stopTime = tic() + 2*obj.interStimulusIntervalSecs*1e9;
sound(readySound, Fs);
obj.waitUntil(stopTime);

% Present the first stimulus
stopTime = stopTime + obj.stimulusDurationSecs*1e9;
obj.CombiLEDObj.startModulation;
sound(oneSound, Fs);
obj.waitUntil(stopTime);

% Prepare the second stimulus
obj.CombiLEDObj.setContrast(intTwoParams(1));
obj.CombiLEDObj.setFrequency(intTwoParams(2));
obj.CombiLEDObj.setPhaseOffset(intTwoParams(3));

% ISI
stopTime = stopTime + obj.interStimulusIntervalSecs*1e9;
obj.waitUntil(stopTime);

% Present the second stimulus. Allow the response interval to start
% one second after the second stimulus starts
stopTime = stopTime + 1e9;
obj.CombiLEDObj.startModulation;
sound(twoSound, Fs);
obj.waitUntil(stopTime);

% Start the response interval
response = obj.getResponse;

% Make sure the stimulus has stopped
obj.CombiLEDObj.stopModulation;

% Apply the staircase
if ~isempty(response)
    validResponse = true;
    if response==testInterval
        % The subject said the test was faster, so make the test slower
        obj.currentTestFreqIdx = obj.currentTestFreqIdx-1;
    else
        % The subject said that the reference was faster, so make the test
        % faster
        obj.currentTestFreqIdx = obj.currentTestFreqIdx+1;
    end
else
    validResponse = false;
end

% Store the trial data
obj.trialHistory(obj.trialIdx).testInterval = testInterval;
obj.trialHistory(obj.trialIdx).response = response;
obj.trialHistory(obj.trialIdx).refParams = refParams;
obj.trialHistory(obj.trialIdx).testParams = testParams;
obj.trialHistory(obj.trialIdx).validResponse = validResponse;

% Handle the bounds on the currentTestFreqIdx
if obj.currentTestFreqIdx < 1
    obj.currentTestFreqIdx = 1;
end
if obj.currentTestFreqIdx > length(obj.TestFrequencySet)
    obj.currentTestFreqIdx = length(obj.TestFrequencySet);
end

% Iterate the trial counter
obj.trialIdx = obj.trialIdx+1;

% Buzz the bad trials
if validResponse
else
    sound(badSound, Fs);
    obj.waitUntil(tic()+3e9);
end

end