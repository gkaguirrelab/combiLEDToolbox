% Method to update the stimulus and conduct a single radiometric measurement by
% calling the corresponding method of the attached @Radiometer object.
function [measurement, S] = updateStimulusAndMeasure(obj, ~, targetSettings, ~)
%
if (obj.options.verbosity > 1)
    fprintf('        Target settings    : %2.3f %2.3f %2.3f %2.3f %2.3f %2.3f %2.3f %2.3f\n\n', targetSettings);
end

% Get the displayObj
displayObj = obj.displayObj;

% Update the primaries
if isscalar(targetSettings)   
    displayObj.setPrimaries(repmat(targetSettings,1,8));
else
    displayObj.setPrimaries(targetSettings);
end

% Measure
obj.radiometerObj.measure();
measurement = obj.radiometerObj.measurement.energy;
spectralAxis = obj.radiometerObj.measurement.spectralAxis;
if size(spectralAxis,1) > 1
    S = WlsToS((obj.radiometerObj.measurement.spectralAxis));
else
    S = WlsToS((obj.radiometerObj.measurement.spectralAxis)');
end

end