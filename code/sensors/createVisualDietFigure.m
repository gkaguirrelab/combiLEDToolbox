function createVisualDietFigure(subjectID,sessionDate,varargin)

%{
subjectID = 'HERO_gka1';
sessionDate = '28-03-2023';
createVisualDietFigure(subjectID,sessionDate);
%}

% Parse the parameters
p = inputParser; p.KeepUnmatched = false;
p.addParameter('dropBoxBaseDir',getpref('combiLEDToolbox','dropboxBaseDir'),@ischar);
p.addParameter('projectName','combiLED',@ischar);
p.addParameter('approachName','environmentalSampling',@ischar);
p.addParameter('fps',100,@isnumeric);
p.addParameter('windowDurSecs',100,@isnumeric);
p.addParameter('windowStepSecs',25,@isnumeric);
p.parse(varargin{:})

% Extract some variables
fps = p.Results.fps;
windowDurSecs = p.Results.windowDurSecs;
windowStepSecs = p.Results.windowStepSecs;

% Path to the data
dataDir = fullfile(p.Results.dropBoxBaseDir,...
    'MELA_data',...
    p.Results.projectName,...
    p.Results.approachName,...
    subjectID,sessionDate);

analysisDir = fullfile(p.Results.dropBoxBaseDir,...
    'MELA_analysis',...
    p.Results.projectName,...
    p.Results.approachName,...
    subjectID,sessionDate);

% Get the list of videos
videoDir = fullfile(dataDir,'videos');
videoList =dir(fullfile(videoDir,'*','*.avi'));

% Set up a cell array to hold all of the spectrograms
allSpectrograms = cell(1,length(videoList));

% Load the spectrograms
for cc = 1:3
    spectSet{cc} = [];
end
for vv = 1:length(videoList)
    resultFilename = fullfile(analysisDir,[videoList(vv).name '_spectrogram.mat']);

    load(resultFilename,'spectrogram','frq');

    % log-transform and smooth the spectrogram
    for cc=1:3
        k = log10(squeeze(spectrogram(cc,:,:)));
        s = size(k);
        k = reshape(smooth(k(:),10),s(1),s(2));
        spectSet{cc} = [spectSet{cc},k'];
    end

    % Tuck this in the cell array
    %    allSpectrograms{vv} = spectrogram;

end % Loop over the videos

% Get the irradiance
[xHours,totalIrradianceVec]=processActLumusRecording(subjectID,sessionDate);

figure
xFreq = frq(101:end);
subplot(4,1,1);
semilogy(xHours,totalIrradianceVec);
ylabel('log irradiance [W/m2]');
xlim([0 max(xHours)]);
    a = gca;
    a.TickDir = 'out';
    box off

for cc = 1:3
    subplot(4,1,cc+1);
    k = spectSet{cc};
    k = k(101:end,:);
    imagesc(k(101:end,:));
    a = gca;
    a.TickDir = 'out';
    a.YDir = 'normal';
    a.YTick = [1,901,1901:1000:length(xFreq)];
    a.YTickLabel = arrayfun(@(x) {num2str(x)},xFreq(a.YTick));
    ylim([1 length(xFreq)+1])
    a.XTick = 1:(60*60)/25:504*25;
    a.XTickLabel = arrayfun(@(x) {num2str(x)},[0 1 2 3]);
    ylabel('Freq [Hz]');
    xlabel('time [hours]')
    box off

end
colormap(turbo);

end % Function


