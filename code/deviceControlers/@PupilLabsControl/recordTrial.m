function recordTrial(obj)

% Record the start time
obj.trialData(obj.trialIdx).recordCommandStartTime = datetime();

% Define the video recording command
vidOutFile = fullfile(obj.dataOutDir,sprintf([obj.filePrefix 'trial_%02d.mov'],obj.trialIdx));
vidCommand = obj.recordCommand;
vidCommand = strrep(vidCommand,'trialDurationSecs',num2str(obj.trialDurationSecs));
vidCommand = strrep(vidCommand,'videoFileOut',escapeFileCharacters(vidOutFile));

% Determine if we are recording in the background
if obj.backgroundRecording
    vidCommand = strcat(vidCommand," &");
end

% Alert the user
if obj.verbose
    fprintf('starting trial %d...',obj.trialIdx)
end

% Start the recording
[~,~] = system(vidCommand);

% Store other trial data
obj.trialData(obj.trialIdx).vidOutFile = vidOutFile;
obj.trialData(obj.trialIdx).backgroundRecording = obj.backgroundRecording;

% Alert the user
if obj.verbose
    fprintf('done.\n');
end

% Iterate the trial index
obj.trialIdx = obj.trialIdx+1;

end