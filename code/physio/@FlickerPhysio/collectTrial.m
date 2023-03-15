function collectTrial(obj)

% Determine if we are simulating the stimuli
simulateStimuli = obj.simulateStimuli;

% Pull out the stimulus frequency and contrast
stimFreqHz = obj.stimFreqHz;
stimContrastAdjusted = obj.stimContrastAdjusted;

% Prepare the sounds
Fs = 8192; % Sampling Frequency
dur = 0.1; % Duration in seconds
t  = linspace(0, dur, round(Fs*dur));
lowTone = sin(2*pi*500*t);
midTone = sin(2*pi*750*t);
highTone = sin(2*pi*1000*t);
readySound = [lowTone midTone highTone];
audioObjs.ready = audioplayer(readySound,Fs);
audioObjs.finished = audioplayer(fliplr(readySound),Fs);

% Handle verbosity
if obj.verbose
    fprintf('Trial %d; Freq [%2.2f Hz], contrast [%2.4f]...', ...
        obj.pupilObj.trialIdx,obj.stimFreqHz,obj.stimContrast);
end

% Present the stimuli
if ~simulateStimuli

    % Alert the subject the trial is about to start
    audioObjs.ready.play;

    % Add a pre-trial jitter so that the start time is less predicatable
    stopTime = tic() + 1e9 * (rand()*range(obj.preTrialJitterRangeSecs)+obj.preTrialJitterRangeSecs(1));

    % While we are waiting, configure the CombiLED
    obj.CombiLEDObj.setContrast(stimContrastAdjusted);
    obj.CombiLEDObj.setFrequency(stimFreqHz);
    obj.CombiLEDObj.setAMIndex(2); % half-cosine ramped
    obj.CombiLEDObj.setAMFrequency(obj.amFreqHz);
    obj.CombiLEDObj.setAMPhase(pi);
    obj.CombiLEDObj.setAMValues([obj.halfCosineRampDurSecs, 0]);
    obj.CombiLEDObj.setDuration(obj.cycleDurationSecs)

    % Finish waiting
    obj.waitUntil(stopTime);

    % Set the video recording in motion, and give it one second for the
    % recording to get going
    obj.pupilObj.recordTrial;
    obj.waitUntil(tic() + 1e9);

    % Loop over the cycles of the amplitude modulation
    vepDataStructs={};
    cycleStopTimes = [];
    modulationStartTime = tic();
    for ii=1:obj.nSubTrials

        % Start the stimulus
        stopTime = tic() + obj.cycleDurationSecs*1e9;
        obj.CombiLEDObj.startModulation;

        % Set the ssVEP recording in motion. Want to return to this and try and
        % get the VEP recording working in the background
        vepDataStructs{ii} = obj.vepObj.recordTrial;

        % Wait for the trial duration
        obj.waitUntil(stopTime);

        % Calculate and store the cycle overage, so we can adjust for the
        % actual modulation frequency in the pupil analysis
        cycleStopTimes(ii)=tic()-modulationStartTime;
    end

    % Store the ssVEP data
    for ii=1:obj.nSubTrials
        obj.vepObj.storeTrial(vepDataStructs{ii});
    end

    % Store the cycleStopTimes
    obj.trialData(obj.pupilObj.trialIdx-1).cycleStopTimes = cycleStopTimes;

    % Play the finished tone
    audioObjs.finished.play;
    obj.waitUntil(tic() + 1e9);
    
end

% Finish the line of text output
if obj.verbose
    fprintf('\n');
end

end