function quantErrorFlagByPrimary = checkForQuantizationError(obj,contrast)
% Identify primaries for which the requested contrast level could produce a
% quantization error. We operationalize this as requiring that a given
% primary should have available 3-bit resolution over the modulation range.
% This is only a rough check; the actual process of converting the floating
% point settings into the final, 12-bit primary values is complicated,
% including casting the initial float into an integer in the range 0-1e4,
% converting back into a float, gamma correcting, and then casting as a
% 12-bit value. We don't attempt to capture the gamma correction step here.

% Get the modulation settings
settingsLow = obj.settingsLow;
settingsHigh = obj.settingsHigh;

% These settings values are transmitted to the combiLED as integers in the
% range 0 - 1e4, and subsequently turned back into floats.
settingsHigh = double(round(settingsHigh * 1e4));
settingsLow = double(round(settingsLow * 1e4));

% The settingsDepth is the difference between the high and low settings,
% scaled by the contrast
settingsDepth = contrast * (settingsHigh - settingsLow);

% These settings are then cast into a 12 bit integer for defining LED
% voltage levels. We will take absolute value of the settingsDepth and
% convert to 12 bits to obtain the depth of these values.
valsDepth = round(abs(settingsDepth/1e4)*2^12);

% We will set an error flag for any primary that has a valsDepth of less
% than 3 bits.
quantErrorFlagByPrimary = valsDepth < 2^3;

end