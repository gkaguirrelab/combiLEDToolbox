obj = CombiLEDcontrol('verbose',false);

% Get observer properties
observerAgeInYears = str2double(GetWithDefault('Age in years','30'));
pupilDiameterMm = str2double(GetWithDefault('Pupil diameter in mm','3'));
modResult = designModulation('LightFlux','observerAgeInYears',observerAgeInYears,'pupilDiameterMm',pupilDiameterMm);
obj.setSettings(modResult);
obj.setBackground(modResult.settingsBackground);
obj.setWaveformIndex(1);
obj.setAMIndex(2);
obj.setAMValues([0.5,0.25]);
obj.setDuration(2);

cRefSet = [0.05, 0.4];
fRefSet = logspace(log10(3),log10(48),5);

cTestSet = logspace(log10(0.0125),log10(0.8),7);
fTestSet = logspace(log10(3)-0.100343331887994*2,log10(48)+0.100343331887994*2,17);

cRef=cRefSet(2); % reference
fRef=fRefSet(3); % reference
cTest=cTestSet(6); % test

fTestIndex = 1;
Fs = 14400;                                     % Sampling Frequency
dur = 0.1;
t  = linspace(0, dur, round(Fs*dur));                        %  Time Vector
intOneSound = sin(2*pi*500*t);                                   % Create Tone
intTwoSound = sin(2*pi*1000*t);                                   % Create Tone
nTrials = 40;

figHandle = figure;
figuresize(10,5);
text(0.25,0.5,'Collecting trials')
axis off
box off


stillTesting = true;
trialIndex = 1;
while stillTesting
    fTest = fTestSet(fTestIndex);
    flip = round(rand());
    if flip==0
        % Reference goes first
        intOneParams = [cRef,fRef];
        intTwoParams = [cTest,fTest];
    else
        intOneParams = [cTest,fTest];
        intTwoParams = [cRef,fRef];
    end
    % Present the stimuli
    sound(intOneSound, Fs);
    obj.setContrast(intOneParams(1));
    obj.setFrequency(intOneParams(2));
    obj.startModulation;
    pause(1.5);
    % Present the stimuli
    sound(intTwoSound, Fs);
    obj.setContrast(intTwoParams(1));
    obj.setFrequency(intTwoParams(2));
    obj.startModulation;
    pause(0.5);
    waitforbuttonpress;
    keyPress = figHandle.CurrentCharacter;
    pause(0.5);

    switch keyPress
        case 'q'
            stillTesting=false;
            continue
        case '1'
            if flip==0
                % The reference came first. I said the first interval (ref)
                % was faster, so make the test faster
                fTestIndex = fTestIndex+1;
            else
                % The reference came second. I said that the first interval
                % (test) was faster, so make the test slower
                fTestIndex = fTestIndex-1;
            end
        case '2'
            if flip==0
                % The reference came first. I said the second interval (test)
                % was faster, so make the test slower
                fTestIndex = fTestIndex-1;
            else
                % The reference came first. I said the first interval (ref)
                % was faster, so make the test faster
                fTestIndex = fTestIndex+1;
            end
        otherwise
            % Subject failed to produce a valid response in time. Repeat
            % the trial
            continue            
    end

    % Iterate the trialIndex
    trialIndex = trialIndex+1;
    if trialIndex > nTrials
        stillTesting=false;
    end

    % Keep the fTestIndex in bounds
    if fTestIndex < 1
        fTestIndex = 1;
    end
    if fTestIndex > length(fTestSet)
        fTestIndex = length(fTestSet);
    end
end
close(figHandle);
