function analyzeEnvironmentalSampling(subjectID,sessionDate,varargin)

%{
subjectID = 'HERO_gka1';
sessionDate = '28-03-2023';
analyzeEnvironmentalSampling(subjectID,sessionDate);
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

% If the analysisDir does not exist, create it
if ~isfolder(analysisDir)
    mkdir(analysisDir);
end

% Get the list of videos
videoDir = fullfile(dataDir,'videos');
videoList =dir(fullfile(videoDir,'*','*.avi'));

% Loop through the videos
for vv = 1:length(videoList)
    filename = fullfile(videoList(vv).folder,videoList(vv).name);

    vObj = VideoReader(filename);
    timePointSecs = 0:windowStepSecs:vObj.Duration-windowDurSecs;
    nSamples = length(timePointSecs);
    vecLength = (windowDurSecs * fps)/2+1;

    spectrogram=zeros(nSamples,vecLength);
    for ii=1:nSamples
        ii
        startFrame = timePointSecs(ii)*fps+1;
        % Check if we can use a portion of the last loaded video snippet
        if ii<4
            video = read(vObj,[startFrame,startFrame+fps*windowDurSecs-1]);
        else
            lastStart = timePointSecs(ii-1)*fps+1;
            lastEnd = lastStart+fps*windowDurSecs-1;
            video(:,:,:,1:fps*(windowDurSecs-windowStepSecs)) = video(:,:,:,1+fps*windowStepSecs:end);
            video(:,:,:,fps*(windowDurSecs-windowStepSecs)+1:end) = read(vObj,[lastEnd+1,lastEnd+fps*windowStepSecs]);
        end
        % Trim the top 10 frames that have the time code and get the average
        % across the 3 channels to extract luminance
        vLum = squeeze(sum(video(11:end,:,:,:),3));

        % Get the average across the image for the zero spatial frequency
        vLumM = squeeze(mean(mean(vLum)));

        % Obtain the FFT
        [frq,amp] = simpleFFT(vLumM,fps);
        %    for xx=1:size(vLum,1); for yy=1:size(vLum,2)
        %            [frq,amp(xx,yy,:)]=simpleFFT(squeeze(vLum(xx,yy,:)),fps);
        %    end; end

        % Save the amplitude vector
        spectrogram(ii,:) = amp;
    end % Loop over the time samples

    % Save this spectrogram
    filename = fullfile(analysisDir,[videoList(vv).name '_spectrogram.mat']);
    save(filename,'spectrogram','frq');

end % Loop over the videos

end % Function

% collapse across x & y dimensions

% x = mean(ampspec,1);
% xx = mean(x,2);
% xxx = squeeze(xx);
% xxx(1)=nan;
