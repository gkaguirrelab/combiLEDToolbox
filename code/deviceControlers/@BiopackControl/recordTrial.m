function [dataStruct] = recordTrial(obj)

% Alert the user
if obj.verbose
    fprintf('starting trial %d...',obj.trialIdx)
end

% Initialize the vep Data Struct
dataStruct.startTime = datetime;

% Record the data. We place the recording in a try-catch block as
% mysterious errors can occur in LabJack land.
if ~obj.simulateResponse
    try
        % Acquire the data
        tic;
        obj.labjackOBJ.startDataStreamingForSpecifiedDuration(obj.trialDurationSecs);
        elapsedTimeSecs = toc;
        % Place the data in a response structure
        dataStruct.timebase = obj.labjackOBJ.timeAxis;
        dataStruct.response = obj.labjackOBJ.data';
        dataStruct.elapsedTimeSecs = elapsedTimeSecs;
    catch err
        % Close up shop
        labjackOBJ.shutdown();
        rethrow(err)
    end % try-catch
else
    nSamples = obj.recordingFreqHz*obj.trialDurationSecs;
    dataStruct.timebase = linspace(0,obj.trialDurationSecs,nSamples);
    dataStruct.response = rand(1,nSamples);
    dataStruct.elapsedTimeSecs = obj.trialDurationSecs;
    pause(obj.trialDurationSecs);
end


end