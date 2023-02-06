% Method to update the stimulus and conduct a single radiometric measurement by
% calling the corresponding method of the attached @Radiometer object.
function [measurement, S] = updateStimulusAndMeasure(obj, ~, targetSettings, ~)
%
if (obj.options.verbosity > 1)
    fprintf('        Target settings    : %2.3f %2.3f %2.3f %2.3f %2.3f %2.3f %2.3f %2.3f\n\n', targetSettings);
end

% Map the 0-1 range of settings to the 0-4095 range of the device
deviceSettings = round(targetSettings*4095);

% Get the displayObj
displayObj = obj.displayObj;

% Update the primaries
displayObj.setPrimaries(deviceSettings);

% Get the radiometer object
radiometerObj = obj.radiometerObj;

% If the radiometer object is empty, assume we are simulating a
% radiometer and return the simulated response for the CombiLED
% then measure
if isempty(radiometerObj)
    load(fullfile(fileparts(mfilename('fullpath')),'resultSet.mat'),'resultSet');
    measurement = resultSet.B_primary*targetSettings;
    S = resultSet.Svals;
    foo = 1;
else
    obj.radiometerObj.measure();
    measurement = obj.radiometerObj.measurement.energy;
    S = WlsToS((obj.radiometerObj.measurement.spectralAxis)');
end

end