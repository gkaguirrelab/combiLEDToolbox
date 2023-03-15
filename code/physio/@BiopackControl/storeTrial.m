function storeTrial(obj,vepDataStruct)

% Define the save location
dataOutFile = fullfile(obj.dataOutDir,sprintf([obj.filePrefix 'trial_%02d.mat'],obj.trialIdx));

% Save the data
save(dataOutFile,'vepDataStruct');

% Alert the user
if obj.verbose
    fprintf('done.\n');
end

% Update the trialData
obj.trialData(obj.trialIdx).startTime = vepDataStruct.startTime;

% Iterate the trial index
obj.trialIdx = obj.trialIdx+1;
