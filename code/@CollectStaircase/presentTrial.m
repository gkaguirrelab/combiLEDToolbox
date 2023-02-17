function obj = presentTrial(obj)

% Check if we are done presenting trials
if obj.trialIdx < obj.nTrials
    return
end

% Prepare the sounds
Fs = 14400;                                     % Sampling Frequency
dur = 0.1;
t  = linspace(0, dur, round(Fs*dur));                        %  Time Vector
intOneSound = sin(2*pi*500*t);                                   % Create Tone
intTwoSound = sin(2*pi*1000*t);                                   % Create Tone
badSound = sin(2*pi*100*t);

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

% Randomly pick which goes first, test or reference
referenceGoesFirst = logical(round(rand()));

% Assign the stimuli to the intervals
if referenceGoesFirst
    intOneParams = [refContrast,refFrequency,refPhase];
    intTwoParams = [testContrast,testFrequency,testPhase];
else
    intOneParams = [testContrast,testFrequency,testPhase];
    intTwoParams = [refContrast,refFrequency,refPhase];
end

% Prepare the first stimulus
obj.CombiLEDObj.setContrast(intOneParams(1));
obj.CombiLEDObj.setFrequency(intOneParams(2));
obj.CombiLEDObj.setPhaseOffset(intOneParams(3));

% Present the first stimulus
sound(intOneSound, Fs);
obj.CombiLEDObj.startModulation;
pause(obj.stimulusDurationSecs);

% ISI
pause(obj.interStimulusIntervalSecs);

% Prepare the second stimulus
obj.CombiLEDObj.setContrast(intTwoParams(1));
obj.CombiLEDObj.setFrequency(intTwoParams(2));
obj.CombiLEDObj.setPhaseOffset(intTwoParams(3));

% Present the second stimulus
sound(intTwoSound, Fs);
obj.CombiLEDObj.startModulation;
pause(obj.stimulusDurationSecs);

% ISI
pause(obj.interStimulusIntervalSecs);

% Start the response interval
response = obj.getResponse;

% Apply the staircase
validResponse = false;
if strcmp(response,"1") && referenceGoesFirst
    % The reference came first, and the subject said the first interval
    % (ref) was faster, so make the test faster
    obj.currentTestFreqIdx = obj.currentTestFreqIdx+1;
    validResponse = true;
end
if strcmp(response,"1") && ~referenceGoesFirst
    % The reference came second, and the subject said that the first
    % interval (test) was faster, so make the test slower
    obj.currentTestFreqIdx = obj.currentTestFreqIdx-1;
    validResponse = true;
end
if strcmp(response,"2") && referenceGoesFirst
    % The reference came first, and the subject said the second interval
    % (test) was faster, so make the test slower
    obj.currentTestFreqIdx = obj.currentTestFreqIdx-1;
    validResponse = true;
end
if strcmp(response,"2") && ~referenceGoesFirst
    % The reference came second, and the subject said that the second
    % interval (ref) was faster, so make the test faster
    obj.currentTestFreqIdx = obj.currentTestFreqIdx+1;
    validResponse = true;
end

% Handle the bounds on the currentTestFreqIdx
if obj.currentTestFreqIdx < 1
    obj.currentTestFreqIdx = 1;
end
if obj.currentTestFreqIdx > length(obj.TestFrequencySet)
    obj.currentTestFreqIdx = length(obj.TestFrequencySet);
end

% Iterate the trial counter
obj.trialIndex = obj.trialIndex+1;

% Buzz the bad trials
if ~validResponse
    sound(badSound, Fs);
end

end