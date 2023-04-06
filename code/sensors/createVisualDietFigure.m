function createVisualDietFigure(subjectID,sessionDate,varargin)

%{
subjectID = 'HERO_gka1';
sessionDate = '29-03-2023';
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
p.addParameter('savePlots',true,@islogical);
p.parse(varargin{:})

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
for cc = 1:3; spectSet{cc} = []; end
for vv = 1:length(videoList)
    resultFilename = fullfile(analysisDir,[videoList(vv).name '_spectrogram.mat']);

    load(resultFilename,'spectrogram','frq');
    [~,OneHzIdx] = min(abs(frq-1));

    % log-transform and smooth the spectrogram
    %    figure
    plotColors = {'k','r','b'};
    for cc=1:3
        k = log10(squeeze(spectrogram(cc,:,:)));
        s = size(k);
        k = reshape(smooth(k(:),10),s(1),s(2))';
        spectSet{cc} = [spectSet{cc},k,nan(size(k,1),4)];
        %        loglog(frq(OneHzIdx:end),mean(squeeze(spectrogram(cc,:,OneHzIdx:end)),1),['-' plotColors{cc}]); hold on;
    end

end % Loop over the videos

% Get the irradiance and activity
[xHours,totalIrradianceVec,activityVec]=processActLumusRecording(subjectID,sessionDate);

% Code the activity; 1 = walking, 2 = sitting, 3 = driving
indoorMinuteIdx = {1:55,74:123,148:156,160:162,167:172,195:241};
activityIdx = {1:7,8:41,42:64,65:72,73:77,78:121,122:127,128:146,147:172,173:191,192:200,201:241};
activityCode = {1,2,1,2,1,2,1,3,1,3,1,2};
activityColor = {'b','w','r'};

f1 = figure;
figuresize(400,800,'pt');

t = tiledlayout(9,1);
t.TileSpacing = 'compact';
t.Padding = 'compact';

[~,xLimIdx] = min(abs(xHours*60-(3200*4)));

% Irradiance and indoor/outdoor status
nexttile;

% Patches to indicate inside / outside
a = gca();
a.YScale = 'log';
for pp = 1:length(indoorMinuteIdx)
    idx1 = min(indoorMinuteIdx{pp}) / 60;
    idx2 = max(indoorMinuteIdx{pp}) / 60;
    patch( ...
        [idx1,idx1,idx2,idx2], ...
        [10^0 10^5 10^5 10^0],'k','EdgeColor','none','FaceColor','k','FaceAlpha',0.1);
    hold on
end

% The irradiance vector
semilogy(xHours,smooth(totalIrradianceVec,25),'-','Color',[0.25 0.25 0.25],'LineWidth',1.5);
ylabel({'log irradiance','[W/m2]'});
xlim([0 xHours(xLimIdx)]);
ylim([10^0 10^5])
a = gca;
a.TickDir = 'out';
a.XTick = [];
box off

nexttile;

for pp = 1:length(activityIdx)
    idx1 = min(activityIdx{pp}) / 60;
    idx2 = max(activityIdx{pp}) / 60;
    patch( ...
        [idx1,idx1,idx2,idx2], ...
        [0 20 20 0],activityColor{activityCode{pp}},'EdgeColor','none','FaceColor',activityColor{activityCode{pp}},'FaceAlpha',0.1);
    hold on
end

% The activity vector
plot(xHours,smooth(activityVec,25),'-','Color',[0.25 0.25 0.25],'LineWidth',1.5);
ylabel({'activity'});
xlim([0 xHours(xLimIdx)]);
a = gca;
a.TickDir = 'out';
a.XTick = [];
box off

% The three spectrograms
xFreq = frq(OneHzIdx:end);
directions = {'LMS','L–M','S'};
for cc = 1:3
    nexttile([2 1]);
    k = spectSet{cc};
    k = k(OneHzIdx:end,:);
    imagesc(k);
    a = gca;
    a.TickDir = 'out';
    a.YDir = 'normal';
    a.YTick = [1,901,1901:1000:length(xFreq)];
    a.YTickLabel = arrayfun(@(x) {num2str(x)},round(xFreq(a.YTick)));
    ylim([1 length(xFreq)+1])
    thirtyMins = (30*60)/windowStepSecs;
    a.XTick = 1:thirtyMins:thirtyMins*ceil((size(k,2)/thirtyMins));
    a.XTickLabel = arrayfun(@(x) {num2str(x)},0:0.5:(1+length(a.XTick))*0.5);
    ylabel('Freq [Hz]');
    xlabel('time [hours]')
    if cc ~= 1
        a.YTick = [];
        ylabel('')
    end
    if cc ~= 3
        a.XTick = [];
        xlabel('')
    end
    title(directions{cc});
end

nexttile;
hCB = colorbar('north','AxisLocation','in');
hCB.Label.String = 'relative power';
set(gca,'Visible',false)
colormap(turbo);

if p.Results.savePlots
    filename = [subjectID '_' sessionDate '_' 'visualDiet.pdf'];
    saveas(f1,fullfile(analysisDir,filename));
end

end % Function


