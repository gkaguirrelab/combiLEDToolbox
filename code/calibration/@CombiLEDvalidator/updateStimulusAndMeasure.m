% Method to update the stimulus and conduct a single radiometric
% measurement by calling the corresponding method of the attached
% @Radiometer object.
function [measurement, S] = updateStimulusAndMeasure(obj, ~, targetSettings, ~)
%
if (obj.options.verbosity >= 1)
    fprintf('        Modulation phase: %2.3f\n\n', targetSettings*2*pi);
end

% Get the displayObj
displayObj = obj.displayObj;

% For the validation operation, we interpret that target settings as
% corresponding to the phase of a modulation. We set the modulation to be
% at that phase, and make a measurement of the spectrum
displayObj.setPhaseOffset(targetSettings*2*pi);

% Pause for a moment
pause(0.5)

% Start the modulation
displayObj.startModulation

% Measure
obj.radiometerObj.measure();
measurement = obj.radiometerObj.measurement.energy;
spectralAxis = obj.radiometerObj.measurement.spectralAxis;
if size(spectralAxis,1) > 1
    S = WlsToS((obj.radiometerObj.measurement.spectralAxis));
else
    S = WlsToS((obj.radiometerObj.measurement.spectralAxis)');
end

% Stop the modulation
displayObj.stopModulation

% Pause for a moment
pause(0.5)

end