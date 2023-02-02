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

    % then measure 
    obj.radiometerObj.measure();
    
    % and finally return results
    measurement = obj.radiometerObj.measurement.energy;
    S           = WlsToS((obj.radiometerObj.measurement.spectralAxis)');
end