function storeTrial(obj,vepDataStruct)

% Define the save location
dataOutFile = fullfile(obj.dataOutDir,sprintf([obj.filePrefix 'trial_%02d_%02d.mat'],obj.trialIdx,obj.subTrialIdx));

% Save the data
save(dataOutFile,'vepDataStruct');

% Alert the user
if obj.verbose
    fprintf('done.\n');
end

% Update the trialData
obj.trialData(obj.trialIdx).startTime = vepDataStruct.startTime;

% Iterate the trial index
obj.subTrialIdx = obj.subTrialIdx+1;
if obj.subTrialIdx > obj.nSubTrials
    obj.subTrialIdx = 1;
    obj.trialIdx = obj.trialIdx+1;
end