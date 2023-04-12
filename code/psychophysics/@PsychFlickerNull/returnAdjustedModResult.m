function modResult = returnAdjustedModResult(obj,adjustWeight)

% Extract the settings
settingsHigh = obj.modResult.settingsHigh;
settingsLow = obj.modResult.settingsLow;
settingsBackground = obj.modResult.settingsBackground;

% Scale the settings to create headroom for the adjustment
settingsHigh = (settingsHigh - settingsBackground) * (1-abs(adjustWeight)) + settingsBackground;
settingsLow = (settingsLow - settingsBackground) * (1-abs(adjustWeight)) + settingsBackground;

% Adjust the high or low settings
if obj.adjustHighSettings
    settingsHigh = settingsHigh + ...
        adjustWeight * obj.adjustSettingsVec;
else
    settingsLow = settingsLow + ...
        adjustWeight * obj.adjustSettingsVec;
end

% Re-center the modulation
adj = obj.modResult.settingsBackground - (settingsHigh+settingsLow)/2;
settingsHigh = settingsHigh + adj;
settingsLow = settingsLow + adj;

% Expand to full settings gamut
adj = max(abs([settingsLow; settingsHigh]));
settingsHigh = settingsHigh/adj;
settingsLow = settingsLow/adj;

% Numerical imprecision can lead to the settings being slightly outside of
% range. Fix this.
settingsLow(settingsLow>1)=1;
settingsLow(settingsLow<0)=0;
settingsHigh(settingsHigh>1)=1;
settingsHigh(settingsHigh<0)=0;

% Store and return the adjusted modulation
modResult = obj.modResult;
modResult.settingsHigh = settingsHigh;
modResult.settingsLow = settingsLow;

end