function [intervalChoice, responseTimeSecs] = getSimulatedResponse(obj,FrequencyParams,ref1Interval)

% Get the simulated choice of ref1 or ref2
outcome = obj.questData.qpOutcomeF(FrequencyParams);

if outcome==ref1Interval
    intervalChoice = 1;
else
    intervalChoice = 2;
end

% The response is simulated, so make the responseTimeSecs nan
responseTimeSecs = nan;

end