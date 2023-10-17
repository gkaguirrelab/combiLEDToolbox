function cal = loadCalByName(calName,calIdx)

% Find the specified calibration within this project directory; load
% it.
calPath = fullfile(tbLocateProjectSilent('combiLEDToolbox'),'cal',calName);
load(calPath,'cals');

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