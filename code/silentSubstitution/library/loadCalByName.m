function cal = loadCalByName(calName,calSubDir,calIdx)

if nargin == 1
    calSubDir = [];
end

if nargin == 2
    calIdx = [];
end

% Find the specified calibration within this project directory; load
% it.
calPath = fullfile(getpref('combiLEDToolbox','CalDataFolder'),calSubDir,calName);
load(calPath,'cals');

% If not otherwise specified, use the most recent calibration
if isempty(calIdx)
    cal = cals{end};
else
    cal = cals{calIdx};
end
end