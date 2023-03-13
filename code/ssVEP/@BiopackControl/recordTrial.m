function recordTrial(obj)

% Define the save location
dataOutFile = fullfile(obj.dataOutDir,sprintf('trial_%02d.mp4',obj.trialIdx));

% Store this trial data
obj.trialData(obj.trialIdx).startTime = datetime;
obj.trialData(obj.trialIdx).dataOutFile = dataOutFile;

% Alert the user
if obj.verbose
    fprintf('starting trial %d...',obj.trialIdx)
end

% Record the EEG. We place the recording in a try-catch block as mysterious
% errors can occur in LabJack land.
try
    % Acquire the data
    tic;
    labjackOBJ.startDataStreamingForSpecifiedDuration(p.Results.recordingDurationSecs);
    elapsedTimeSecs = toc;
    % Place the data in a response structure
    vepDataStruct.timebase = labjackOBJ.timeAxis;
    vepDataStruct.response = labjackOBJ.data';
    vepDataStruct.elapsedTimeSecs = elapsedTimeSecs;
    % Close-up shop
    labjackOBJ.shutdown();
catch err
    % Close up shop
    labjackOBJ.shutdown();
    rethrow(err)
end % try-catch

% Record the finish time
obj.trialData(obj.trialIdx).elapsedTimeSecs = elapsedTimeSecs;

% Save the data
save(dataOutFile,'vepDataStruct');

% Alert the user
if obj.verbose
    fprintf('done.\n');
end

% Iterate the trial index
obj.trialIdx = obj.trialIdx+1;

end