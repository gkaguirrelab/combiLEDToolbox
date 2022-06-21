
function modulationPrimary = modPrimarySearch(B_primary,backgroundPrimary,ambientSpd,T_receptors,whichReceptorsToTarget, whichReceptorsToIgnore, whichReceptorsToMinimize,whichPrimariesToPin,primaryHeadRoom, maxPowerDiff, desiredContrast,minAcceptableContrast,minAcceptableContrastDiff,verbose,stepSizeDiffContrastSearch)

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
        B_primary, backgroundPrimary, backgroundPrimary, whichPrimariesToPin,...
        primaryHeadRoom, maxPowerDiff, thisContrastTarget, ambientSpd);

    % Calculate the positive receptor contrast and the differences
    % between the targeted receptor sets
    modulationReceptors = T_receptors*B_primary*(modulationPrimary - backgroundPrimary);
    contrastReceptors = modulationReceptors ./ backgroundReceptors;
    contrastVal = contrastReceptors(whichReceptorsToTarget(1));
    contrastDiffs = cellfun(@(x) range(abs(contrastReceptors(whichReceptorsToTarget(x)))),minAcceptableContrast);

    % Report the results of this iteration
    if verbose
        fprintf('shrink %2.1f, contrast %2.2f, diff %2.2f, criterion %2.2f \n',shrinkFactor,contrastVal,max(contrastDiffs),minAcceptableContrastDiff)
    end

    % Check if we are done
    if all(contrastDiffs < minAcceptableContrastDiff)
        stillSearching = false;
    else
        if shrinkFactor < 0.8
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

end