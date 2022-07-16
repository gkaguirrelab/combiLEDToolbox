
function modulationPrimary = modPrimarySearch(B_primary,backgroundPrimary,x0Primary,ambientSpd,T_receptors,whichReceptorsToTarget, whichReceptorsToIgnore, whichReceptorsToMinimize,whichPrimariesToPin,primaryHeadRoom, maxPowerDiff, desiredContrast,minAcceptableContrast,minAcceptableContrastDiff,verbose,stepSizeDiffContrastSearch,shrinkFactorThresh)


% Obtain the isomerization rate for the receptors by the background
backgroundReceptors = T_receptors*(B_primary*backgroundPrimary + ambientSpd);

% Obtain the primary settings for the isolating modulation. Perform
% this search in a loop to steadily scale down targeted contrast
% until differential absolute contrast amongst the targeted
% photoreceptors is below criterion
stillSearching = true;
shrinkFactor = 1;
thisContrastTarget = desiredContrast;

while stillSearching

    % Perform the search for the modulation
    modulationPrimary = ReceptorIsolate(T_receptors,whichReceptorsToTarget, whichReceptorsToIgnore, whichReceptorsToMinimize, ...
        B_primary, backgroundPrimary, x0Primary, whichPrimariesToPin,...
        primaryHeadRoom, maxPowerDiff, thisContrastTarget, ambientSpd);

    % Calculate the positive receptor contrast and the differences
    % between the targeted receptor sets
    modulationReceptors = T_receptors*B_primary*(modulationPrimary - backgroundPrimary);
    contrastReceptors = modulationReceptors ./ backgroundReceptors;
    contrastDiffs = cellfun(@(x) range(abs(contrastReceptors(whichReceptorsToTarget(x)))),minAcceptableContrast);

    % Check if we are done
    if all(contrastDiffs < minAcceptableContrastDiff)
        break
    end

    % We failed to find a good solution. Adjust the goal.
    if shrinkFactor < shrinkFactorThresh
        % We have failed to find a good solution. Return a vector of
        % zeros for the modulation primary
        modulationPrimary = backgroundPrimary;
        stillSearching = false;
    else
        shrinkFactor = shrinkFactor - stepSizeDiffContrastSearch;
        thisContrastTarget = desiredContrast.*shrinkFactor;
    end

end

end