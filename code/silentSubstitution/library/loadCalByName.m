function cal = loadCalByName(calName,calIdx,calSubDir)

if nargin == 2
    calSubDir = [];
end

% Find the specified calibration within this project directory; load
% it.
calPath = fullfile(getpref('combiLEDToolbox','CalDataFolder'),calName);
load(calPath,calSubDir,'cals');

% If not otherwise specified, use the most recent calibration
if nargin>1
    if isempty(calIdx)
        cal = cals{end};
    else
        cal = cals{calIdx};
    end
else
    cal = cals{end};
end
end