function recordTrial(obj)

% Define the video recording command
vidOutFile = fullfile(obj.dataOutDir,sprintf([obj.filePrefix 'trial_%02d.mp4'],obj.trialIdx));
vidCommand = obj.recordCommand;
vidCommand = strrep(vidCommand,'cameraIdx',num2str(obj.cameraIdx));
vidCommand = strrep(vidCommand,'trialDurationSecs',num2str(obj.trialDurationSecs));
vidCommand = strrep(vidCommand,'videoFileOut.mp4',vidOutFile);

% Store this trial data
obj.trialData(obj.trialIdx).startTime = datetime;
obj.trialData(obj.trialIdx).vidOutFile = vidOutFile;
obj.trialData(obj.trialIdx).backgroundRecording = obj.backgroundRecording;

% Alert the user
if obj.verbose
    fprintf('starting trial %d...',obj.trialIdx)
end

% Determine if we are recording in the background
if obj.backgroundRecording
    vidCommand = [vidCommand ' &'];
end

% Start the recording
tic;
[~,~] = system(vidCommand);
elapsedTimeSecs = toc;

% Record the finish time
obj.trialData(obj.trialIdx).elapsedTimeSecs = elapsedTimeSecs;

% Alert the user
if obj.verbose
    fprintf('done.\n');
end

% Iterate the trial index
obj.trialIdx = obj.trialIdx+1;

end