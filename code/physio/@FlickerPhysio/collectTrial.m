function collectTrial(obj)

% Determine if we are simulating the stimuli
simulateStimuli = obj.simulateStimuli;

% Pull out the stimulus frequency and contrast
stimFreqHz = obj.stimFreqHz;

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
    fprintf('Freq [%2.2f Hz]...', obj.stimFreqHz);
end

% Present the stimuli
if ~simulateStimuli

    % Set the video recording in motion.
    stopTime = tic() + 1e9 * obj.pupilVidStartDelaySec;
    obj.pupilObj.recordTrial;

    % Alert the subject the trial is about to start
    audioObjs.ready.play;

    % configure the CombiLED overall
    obj.CombiLEDObj.setFrequency(stimFreqHz);
    obj.CombiLEDObj.setAMIndex(2); % half-cosine ramped
    obj.CombiLEDObj.setAMFrequency(obj.amFreqHz);
    obj.CombiLEDObj.setAMPhase(pi);
    obj.CombiLEDObj.setAMValues([obj.halfCosineRampDurSecs, 0]);
    obj.CombiLEDObj.setDuration(obj.cycleDurationSecs)

    % Finish waiting for pupil recording to have started
    obj.waitUntil(stopTime);

    % Loop over the elements of stimContrastOrder
    vepDataStructs={};
    cycleStopTimes = [];
    modulationStartTime = tic();
    for ii=1:length(obj.stimContrastOrder)

        % Update the contrast for the stimulus
        contrastIdx = obj.stimContrastOrder(ii);
        obj.CombiLEDObj.setContrast(obj.stimContrastSetAdjusted(contrastIdx));

        % Handle verbosity
        if obj.verbose
            fprintf('contrast %2.2f...', obj.stimContrastSet(contrastIdx));
        end

        % Start the stimulus
        stopTime = tic() + obj.cycleDurationSecs*1e9;
        obj.CombiLEDObj.startModulation;

        % Set the ssVEP recording in motion
        vepDataStructs{ii} = obj.vepObj.recordTrial;

        % Wait for the trial duration
        obj.waitUntil(stopTime);

        % Calculate and store the cycle overage, so we can adjust for the
        % actual modulation frequency in the pupil analysis
        cycleStopTimes(ii)=tic()-modulationStartTime;
    end

    % Store the ssVEP data
    for ii=1:length(obj.stimContrastOrder)
        contrastIdx = obj.stimContrastOrder(ii);
        contrastLabel = sprintf('contrast_%2.1f_',obj.stimContrastSet(contrastIdx));
        obj.vepObj.storeTrial(vepDataStructs{ii},contrastLabel);
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