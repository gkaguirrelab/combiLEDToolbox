function deriveVideoSpectrograms(subjectID,sessionDate,varargin)
% The actual duration of each video is 53 minutes and ~20 seconds (or 3200
% seconds), as opposed to the nominal 60 minutes. Consequently, the frame
% rate is 112.5 fps, as opposed to the nominal 100 fps.
%{
subjectID = 'HERO_gka1';
sessionDate = '29-03-2023';
deriveVideoSpectrograms(subjectID,sessionDate);
%}

% Parse the parameters
p = inputParser; p.KeepUnmatched = false;
p.addParameter('dropBoxBaseDir',getpref('combiLEDToolbox','dropboxBaseDir'),@ischar);
p.addParameter('projectName','combiLED',@ischar);
p.addParameter('approachName','environmentalSampling',@ischar);
p.addParameter('fps',112.5,@isnumeric);
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

% Set up a cell array to hold all of the spectrograms
allSpectrograms = cell(1,length(videoList));

% Loop through the videos
for vv = 1:length(videoList)

    % Open the video object
    vidFilename = fullfile(videoList(vv).folder,videoList(vv).name);
    resultFilename = fullfile(analysisDir,[videoList(vv).name '_spectrogram.mat']);
    vObj = VideoReader(vidFilename);

    % Set the read length to be the closest even multiple of 4
    windowLengthFrames = round(fps*windowDurSecs);
    windowLengthFrames = windowLengthFrames + mod(windowLengthFrames,4);
    windowStepFrames = windowLengthFrames/4;

    % Define the properties of the Fourier transform
    framePoints = 1:windowStepFrames:vObj.NumFrames-windowLengthFrames;
    nSamples = length(framePoints);
    vecLength = windowLengthFrames/2+1;

    % Set up some variables
    spectrogram=zeros(3,nSamples,vecLength);
    luminanceVec = [];

    % Loop over the time samples.
    for ii=1:nSamples
        startFrame = framePoints(ii);
        % Check if we can use a portion of the last loaded video snippet
        if ii<4
            video = read(vObj,[startFrame,startFrame+windowLengthFrames-1]);
            % Trim the top 10 frames that have the time code
            % and get the average
            video = video(11:end,:,:,:);
        else
            lastStart = framePoints(ii-1);
            lastEnd = lastStart+windowLengthFrames-1;
            video(:,:,:,1:windowLengthFrames-windowStepFrames) = video(:,:,:,1+windowStepFrames:end);
            newVidSeg = read(vObj,[lastEnd+1,lastEnd+windowStepFrames]);
            video(:,:,:,windowLengthFrames-windowStepFrames+1:end) = newVidSeg(11:end,:,:,:);
        end

        % Get the dimensions of the video
        xDim = size(video,1);
        yDim = size(video,2);
        cDim = size(video,3);
        tDim = size(video,4);

        % Linearize the video and convert it from RGB to cone space
        videoVec = reshape(permute(video,[1 2 4 3]),xDim*yDim,tDim,cDim);

        % Loop through the pixels and convert the values to relative cone
        % excitations
        for pp=1:length(xDim*yDim)
            videoVec(pp,:,:) = cameraToCones(double(squeeze(videoVec(pp,:,:))));
        end

        % Loop through the post-receptoral directions and obtain the FFT
        for ff=1:3
            switch ff
                case 1
                    signal = mean(mean(videoVec,3),1);
                    luminanceVec = [luminanceVec,signal];
                case 2
                    signal = mean(videoVec(:,:,1)-videoVec(:,:,2),1);
                case 3
                    signal = mean(videoVec(:,:,3)-0.5*(videoVec(:,:,1)+videoVec(:,:,2)),1);
            end
            % Mean center the signal and convert to % change
            m = mean(signal);
            signal = (signal - m)/m;
            [frq,amp] = simpleFFT(signal,fps);
            spectrogram(ff,ii,:) = amp;
        end

    end % Loop over the time samples

    % Save this spectrogram
    save(resultFilename,'spectrogram','luminanceVec','frq');

end % Loop over the videos


end % Function
