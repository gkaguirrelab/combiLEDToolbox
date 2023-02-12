function scaleSearch(resultSet)

myObj = @(p) localObjective(p,resultSet);

primaryScale = fmincon(myObj,ones(8,1),[],[],[],[],repmat(0.1,8,1),repmat(10,8,1));

end


%local function

function fVal = localObjective(p,resultSet)

resultSet.B_primary = resultSet.B_primary .* p';

resultSet = searchThisBackground(repmat(0.5,8,1),resultSet);

% Obtain the set of contrasts for the modulations
for ss=1:length(resultSet.whichDirectionsToScore)
    set = resultSet.whichDirectionsToScore(ss);
    whichDirection = resultSet.whichDirectionSet{set};
    whichReceptorsToTarget = resultSet.whichReceptorsToTargetSet{set};
    contrasts(ss) = resultSet.(whichDirection).positiveReceptorContrast(whichReceptorsToTarget(1));
end

fVal = 1/min(contrasts);

end