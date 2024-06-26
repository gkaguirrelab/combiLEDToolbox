function contrastScale = contrastAttenuationByFreq(frequencies)

% Make these persistent so we don't need to keep re-loading the file
persistent contrastRollOff frequencySupport

% Load the frequency roll of empirical measurements
if isempty(contrastRollOff)
    dataFileName = fullfile(fileparts(mfilename("fullpath")),'freqRollOffMeasure.mat');
    load(dataFileName,'contrastRollOff','frequencySupport');
end

% Sanity check the input. We can't extrapolate above highest measurement
mustBeInRange(frequencies,1e-6,max(frequencySupport));

% Interpolate from the data to the contrast values
contrastScale = interp1(log10(frequencySupport),contrastRollOff,log10(frequencies),'spline',1);

end