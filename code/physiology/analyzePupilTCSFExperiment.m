function analyzePupilTCSFExperiment(subjectID,modDirection,varargin)
%
%
%{
    subjectID = 'HERO_gka1';
    modDirection = 'LightFlux';
    analyzePupilTCSFExperiment(subjectID,modDirection);
%}


% Parse the parameters
p = inputParser; p.KeepUnmatched = false;
p.addParameter('dropBoxBaseDir',getpref('combiLEDToolbox','dropboxBaseDir'),@ischar);
p.addParameter('projectName','combiLED',@ischar);
p.addParameter('approachName','flickerPhysio',@ischar);
p.addParameter('stimContrastSet',[0,0.05,0.1,0.2,0.4,0.8],@isnumeric);
p.addParameter('stimFreqSetHz',[4,6,10,14,20,28,40],@isnumeric);
p.addParameter('nBoots',1000,@isnumeric);
p.addParameter('rmseThresh',0.5,@isnumeric);
p.addParameter('savePlots',true,@islogical);
p.parse(varargin{:})

% Set our experimentName
experimentName = 'ssVEPTCSF';

% Define the location of the raw data and the processed videos
dataDir = fullfile(...
    p.Results.dropBoxBaseDir,...
    'MELA_data',...
    p.Results.projectName,...
    p.Results.approachName,...
    subjectID,modDirection,experimentName);

analysisDir = fullfile(...
    p.Results.dropBoxBaseDir,...
    'MELA_analysis',...
    p.Results.projectName,...
    p.Results.approachName,...
    subjectID,modDirection,experimentName);

% Create the analysis directory for the subject
if ~isfolder(analysisDir) && p.Results.savePlots
    mkdir(analysisDir)
end

% Where the pupil video prep is taking place
processingDir = fullfile(...
    p.Results.dropBoxBaseDir,...
    'MELA_analysis',...
    'pilotLumFlickerPupil','rawPupilVideos');

% Get the stimulus values
stimFreqSetHz = p.Results.stimFreqSetHz;
stimContrastSet = p.Results.stimContrastSet;
nFreqs = length(stimFreqSetHz);
nContrasts = length(stimContrastSet);
Fs = 40;
sampleShift = 0;
stimDurSecs = 2;
nBoots = p.Results.nBoots;

% Load the measurementRecord
filename = fullfile(dataDir,'measurementRecord.mat');
load(filename,'measurementRecord');
nTrials = length(measurementRecord.trialData);

% Loop over the trials, concatenate the pupil response, and build the model
pupilVec = [];
X = sparse([]);
XbyTrial = {};
trialGroups = [];
stimFreqIdxVec = [];

for tt = 1:nTrials

    % Load the pupil file for this trial
    filelist = dir(fullfile(processingDir,sprintf('*trial_%02d_pupil.mat',tt)));
    filename = fullfile(filelist.folder,filelist.name);
    load(filename,'pupilData');

    % extract the time-series, convert to % change, mean center
    vec = pupilData.initial.ellipses.values(:,3);
    vec(pupilData.initial.ellipses.RMSE>p.Results.rmseThresh)=nan;
    meanVec = nanmean(vec);
    vec = (vec - meanVec)/meanVec;

    % remove low-frequency polynomials up to the repetition order of the
    % stimulus set
    f = constructpolynomialmatrix(length(vec),1:nContrasts)';
    nanIdx = ~isnan(vec);
    cleanVec = vec(nanIdx);
    f = f(:,nanIdx);
    b = cleanVec'/f;
    fitPoly = b*f;
    cleanVec = cleanVec - fitPoly';
    vec(nanIdx) = cleanVec;

    % Add this trial to the overall vector
    pupilVec = [pupilVec vec'];

    % Build the parameters
    stimFreqHz = measurementRecord.trialData(tt).stimFreqHz;
    stimFreqIndex = find(stimFreqSetHz==stimFreqHz);
    stimContrastOrder = measurementRecord.trialData(tt).stimContrastOrder;

    % Calculate how early the video recording started before the stimuli
    videoPreTimeSecs = 2.5 - measurementRecord.trialData(tt).vidDelaySecs;

    % Loop through the stimuli and construct the subX matrix
    subX = zeros(nContrasts+1,length(vec));
    for ss = 1:length(stimContrastOrder)
        cycleStopTimeSecs = measurementRecord.trialData(tt).cycleStopTimes(ss)/1e9;
        relativesStartTimeSecs = videoPreTimeSecs + cycleStopTimeSecs - 2;
        startTimeIdx = round(relativesStartTimeSecs*Fs) + sampleShift;
        rowIdx = stimContrastOrder(ss);
        if ss == 1
            rowIdx = size(subX,1);
        end
        subX(rowIdx,startTimeIdx:startTimeIdx+round(2*Fs)-1) = 1;
    end

    % trim subX to the length of vec
    subX = subX(:,1:length(vec));

    % mean center
    subX = subX - mean(subX,2);

    % Store this subX
    XbyTrial{tt} = subX;

    % Add subX to the overall X
    rowIdx = (stimFreqIndex-1)*(nContrasts+1)+1;
    newX = X;
    newX(rowIdx:rowIdx+nContrasts,size(X,2)+1:size(X,2)+size(subX,2)) = subX;
    X = newX;

    % Construct the trial groups
    trialGroups = [trialGroups repmat(tt,1,length(vec))];

    % Construct the stimFreqIdxVec and contrastIdxVec
    stimFreqIdxVec(tt) = stimFreqIndex;

end

% Search over gamma shape params to find the best fit
myObj = @(p) fitPupilVec(p,pupilVec,full(X),trialGroups,Fs);
gammaParam = fmincon(myObj,2);

% Report the fVal at the solution
[fVal,~,fitY] = fitPupilVec(gammaParam,pupilVec,full(X),trialGroups,Fs);
fprintf('Model fit R-squared = %2.3f \n',1/fVal);

% Plot the fit
f1=figure;
figuresize(800,200,'pt');
x = 0:1/Fs:length(pupilVec)*(1/Fs)-(1/Fs);
plot(x,pupilVec,'.','Color',[0.5 0.5 0.5]);
hold on
plot(x,fitY,'-r','LineWidth',1);
xlabel('time [secs]');
ylabel('pupil size [%% change]');

if p.Results.savePlots
    filename = [subjectID '_' modDirection '_' 'pupil-rawFit.pdf'];
    saveas(f1,fullfile(analysisDir,filename));
end

% For each frequency, boot-strap across the trials and get the mean and SD
% of the beta values by contrast
bootBetas = [];
for bb=1:nBoots
    bootX = [];
    bootVec = [];
    bootTrialGroups = [];
    startIdx = 0;
    for ff=1:nFreqs
        freqIdx = find(stimFreqIdxVec==ff);
        bootIdx = datasample(freqIdx,length(freqIdx));
        subX = cat(2,XbyTrial{bootIdx});

        rowIdx = (ff-1)*(nContrasts+1)+1;
        newBootX = bootX;
        newBootX(rowIdx:rowIdx+nContrasts,size(bootX,2)+1:size(bootX,2)+size(subX,2)) = subX;
        bootX = newBootX;

        vecCells=arrayfun(@(x) pupilVec(trialGroups==x),bootIdx,'UniformOutput',false);
        bootVec = [bootVec, cat(2,vecCells{:})];
        for ii = 1:length(bootIdx)
            bootTrialGroups = [bootTrialGroups repmat(startIdx+ii,1,sum(trialGroups==bootIdx(ii)))];
        end
        startIdx = max(bootTrialGroups);
    end
    [~,betas] = fitPupilVec(gammaParam,bootVec,bootX,bootTrialGroups,Fs);
    % Subtract the zero contrast condition
    bMat = reshape(betas,7,7);
    bMat = bMat-bMat(1,:);
    bVec = bMat(:);
    bootBetas(bb,:) = bVec;
end
b = mean(bootBetas);
semB = std(bootBetas);

bMat = reshape(b,7,7);
bMatSEM = reshape(semB,7,7);
% Get rid of the beta values for first stimulus of each trial, and for the
% zero contrast condition
bMat = bMat(2:end-1,:);
bMatSEM = bMatSEM(2:end-1,:);

f2=figure;
x = log10(stimFreqSetHz);
cmap = flipud(copper(nContrasts-1));
for ii = nContrasts-1:-1:1
    % Create a patch of the error area
    patch(...
        [x,fliplr(x)],...
        [-bMat(ii,:)+bMatSEM(ii,:),fliplr(-bMat(ii,:)-bMatSEM(ii,:))],...
        cmap(ii,:),'EdgeColor','none','FaceColor',cmap(ii,:),'FaceAlpha',0.1);
    hold on
    plot(x,-bMat(ii,:),'.-','Color',cmap(ii,:),'MarkerSize',15,'LineWidth',1);
end
tmp = diff(x);
xlim([min(x)-tmp(1), max(x)+tmp(end)]);
a=gca();
a.XTick=x;
a.XTickLabels = arrayfun(@(x) {num2str(x)},stimFreqSetHz);
xlabel('stimulus frequency [Hz]')
ylabel('pupil constriction [%%]')
cbh=colorbar;
cbh.Ticks = 0.1:0.2:0.9;
cbh.TickLabels = arrayfun(@(x) {num2str(x)},stimContrastSet(2:end));
cbh.Label.String = 'contrast';
colormap(cmap);

if p.Results.savePlots
    filename = [subjectID '_' modDirection '_' 'pupil-TTF.pdf'];
    saveas(f2,fullfile(analysisDir,filename));
end

end


%% LOCAL FUNCTIONS
function [fVal,b,fitY] = fitPupilVec(gammaParam,pupilVec,X,trialGroups,Fs)

% Create a 15 second time domain for the kernel
x = 0:1/Fs:15;

% Create the gamma pdf kernel
kernel = gampdf(x,gammaParam);
kernel = kernel ./ sum(kernel);

% Convolve the X matrix by the
Xconv = conv2run(X',kernel',trialGroups')';

% Remove the nan elements
nanIdx = isnan(pupilVec);
pupilVecClean = pupilVec(~nanIdx);
XconvClean = Xconv(:,~nanIdx);

% Regress
b=XconvClean/pupilVecClean;
fitYClean = XconvClean'*b;

% The fVal is the inverse of the variance explained
fVal = 1/(corr(fitYClean,pupilVecClean')^2);

% Re-introduce the nans
fitY = nan(size(pupilVec));
fitY(~nanIdx) = fitYClean;


end
