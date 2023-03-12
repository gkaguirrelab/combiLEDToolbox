function recordTrial(obj)

% Define the video recording command
vidOutFile = fullfile(obj.dataOutDir,sprintf('trial_%02d.mp4',obj.trialIdx));
vidCommand = obj.recordCommand;
vidCommand = strrep(vidCommand,'trialDurationSecs',num2str(obj.trialDurationSecs));
vidCommand = strrep(vidCommand,'videoFileOut.mp4',vidOutFile);

% Store this trial data
obj.trialData(trialIdx).startTime = datetime;
obj.trialData(trialIdx).vidOutFile = vidOutFile;

% Alert the user
if obj.verbose
    fprintf('starting trial %d...',obj.trialIdx)
end

% Start the recording
system(vidCommand);

% Alert the user
if obj.verbose
    fprintf('done.\n');
end

% Iterate the trial index
obj.trialIdx = obj.trialIdx+1;

end