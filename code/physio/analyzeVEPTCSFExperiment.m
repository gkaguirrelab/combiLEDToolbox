function analyzeVEPTCSFExperiment(subjectID,modDirection,varargin)
%
%
%{
    subjectID = 'HERO_gka1';
    modDirection = 'LightFlux';
    analyzeVEPTCSFExperiment(subjectID,modDirection);
%}


% Parse the parameters
p = inputParser; p.KeepUnmatched = false;
p.addParameter('dropBoxBaseDir',getpref('combiLEDToolbox','dropboxBaseDir'),@ischar);
p.addParameter('projectName','combiLED',@ischar);
p.addParameter('approachName','flickerPhysio',@ischar);
p.addParameter('stimContrastSet',[0,0.05,0.1,0.2,0.4,0.8],@isnumeric);
p.addParameter('stimFreqSetHz',[4,6,10,14,20,28,40],@isnumeric);
p.parse(varargin{:})

% Set our experimentName
experimentName = 'ssVEPTCSF';

% Define a location to save data
modDir = fullfile(...
    p.Results.dropBoxBaseDir,...
    p.Results.projectName,...
    p.Results.approachName,...
    subjectID,modDirection);

dataDir = fullfile(modDir,experimentName);

% Get the stimulus values
stimFreqSetHz = p.Results.stimFreqSetHz;
stimContrastSet = p.Results.stimContrastSet;

Fs = 2000;
testFreqHz = 20;
sampleShift = -150;
stimDurSecs = 2;

% Load the measurementRecord
filename = fullfile(dataDir,'measurementRecord.mat');
load(filename,'measurementRecord');
nTrials = length(measurementRecord.trialData);

% Loop through the stimuli
data = cell(length(stimFreqSetHz),length(stimContrastSet));
for ff = 1:length(stimFreqSetHz)
    for cc = 1:length(stimContrastSet)
        for tt = 1:nTrials
            if measurementRecord.trialData(tt).stimFreqHz == stimFreqSetHz(ff)
                stimContrastOrder = measurementRecord.trialData(tt).stimContrastOrder;
                stimIdx = find(stimContrastOrder == cc);
                stimIdx = stimIdx(stimIdx~=1);
                for ss=1:length(stimIdx)
                    filename = sprintf('freq_%2.1f_trial_%02d_contrast_%2.1f_stim_%02d.mat',...
                        stimFreqSetHz(ff),...
                        tt,...
                        stimContrastSet(cc),...
                        stimIdx(ss) );
                    load(fullfile(dataDir,'rawEEGData',filename),'vepDataStruct');

                    % Multiple by 100 to set as microvolt units
                    signal = circshift(vepDataStruct.response*100,sampleShift);
                    signal = signal-mean(signal);

                    % Add to the data
                    if isempty(data{ff,cc})
                        data{ff,cc} = signal;
                    else
                        signalMat = data{ff,cc};
                        signalMat(end+1,:) = signal;
                        data{ff,cc} = signalMat;
                    end
                end
            end
        end
    end
end

% Save a timebase
x = vepDataStruct.timebase;

% Create the half-cosine ramp
ramp = ones(size(x));
rampDur = 0.1;
ramp(1:rampDur*Fs)=(cos(pi+pi*(1:rampDur*Fs)/(rampDur*Fs))+1)/2;
ramp(length(ramp)-rampDur*Fs+1:end)=(cos(pi*(1:rampDur*Fs)/(rampDur*Fs))+1)/2;

% Loop through frequencies and contrasts and obtain the amplitude of the
% evoked response
figure
t = tiledlayout(length(stimFreqSetHz),length(stimContrastSet));
t.TileSpacing = 'compact';
t.Padding = 'compact';

ampResp = [];
for ff = 1:length(stimFreqSetHz)
    for cc = 1:length(stimContrastSet)
        % Get this signal matrix
        signalMat = data{ff,cc};

        % Create the X regression matrix
        X(:,1) = ramp.*sin(stimDurSecs*2*pi*(x./max(x))*stimFreqSetHz(ff));
        X(:,2) = ramp.*cos(stimDurSecs*2*pi*(x./max(x))*stimFreqSetHz(ff));

        % Get the Fourier regression fit to the mean response 
        meanData = mean(signalMat)';
        b=X\meanData;
        fitY = X*b;

        ampResp(ff,cc)=norm(b);

        % Plot the mean response and fit
        nexttile

        plot(x,meanData,'-','Color',[0.75 0.75 0.75],'LineWidth',1.25);
        hold on
        plot(x,fitY,'-','Color','r','LineWidth',1.25);

    end
end

figure
logX = log10(stimFreqSetHz);
logX(1) = 0.4;
    for cc = 1:length(stimContrastSet)
        vec = ampResp(:,cc);
        cVal = 0.6 - (cc/10);
        color = [cVal cVal cVal];
        plot(logX,vec,'-','Color',color)
        hold on
    end

end
