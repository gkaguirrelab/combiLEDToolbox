function resultSet = searchThisBackground(backgroundPrimary,resultSet)

% Loop over the set of directions for which we will generate
% modulations
parfor ss = 1:length(resultSet.whichDirectionSet)

    % Extract values from the cell arrays
    whichDirection = resultSet.whichDirectionSet{ss};
    whichReceptorsToTarget = resultSet.whichReceptorsToTargetSet{ss};
    whichReceptorsToIgnore = resultSet.whichReceptorsToIgnoreSet{ss};
    whichReceptorsToMinimize = resultSet.whichReceptorsToMinimizeSet{ss};
    minAcceptableContrast = resultSet.minAcceptableContrastSets{ss};
    minAcceptableContrastDiff = resultSet.minAcceptableContrastDiffSet(ss);
    desiredContrast = resultSet.desiredContrastSet{ss};
    Svals = resultSet.Svals;
    B_primary = resultSet.B_primary;
    ambientSpd = resultSet.ambientSpd;
    T_receptors = resultSet.T_receptors;
    primaryHeadRoom = resultSet.p.Results.primaryHeadRoom;
    verbose = resultSet.p.Results.verbose;
    stepSizeDiffContrastSearch = resultSet.p.Results.stepSizeDiffContrastSearch;
    shrinkFactorThresh = resultSet.p.Results.shrinkFactorThresh;
    x0Primary = backgroundPrimary;

    % No smoothness constraint enforced for the LED primaries
    maxPowerDiff = 10000; 
    % Don't pin any primaries.
    whichPrimariesToPin = [];

    % Anonymous function that perfoms a modPrimarySearch for a
    % particular background defined by backgroundPrimary and x0
    myModPrimary = @(xBackPrimary) modPrimarySearch(...
        B_primary,backgroundPrimary,x0Primary,ambientSpd,T_receptors,...
        whichReceptorsToTarget,whichReceptorsToIgnore,...
        whichReceptorsToMinimize,whichPrimariesToPin,...
        primaryHeadRoom,maxPowerDiff,desiredContrast,...
        minAcceptableContrast,minAcceptableContrastDiff,...
        verbose,stepSizeDiffContrastSearch,...
        shrinkFactorThresh);

    % Obtain the modulationPrimary for this background
    modulationPrimary = myModPrimary(backgroundPrimary);

    % Obtain the isomerization rate for the receptors by the background
    backgroundReceptors = T_receptors*(B_primary*backgroundPrimary + ambientSpd);

    % Store the background properties
    loopVar{ss}.(whichDirection).background.primary = backgroundPrimary;
    loopVar{ss}.(whichDirection).background.spd = B_primary*backgroundPrimary;
    loopVar{ss}.(whichDirection).background.wavelengthsNm = SToWls(Svals);

    % Store the modulation primaries
    loopVar{ss}.(whichDirection).modulationPrimary = modulationPrimary;

    % Calculate and store the positive and negative receptor contrast
    modulationReceptors = T_receptors*B_primary*(modulationPrimary - backgroundPrimary);
    contrastReceptors = modulationReceptors ./ backgroundReceptors;
    loopVar{ss}.(whichDirection).positiveReceptorContrast = contrastReceptors;

    modulationReceptors = T_receptors*B_primary*(-(modulationPrimary - backgroundPrimary));
    contrastReceptors = modulationReceptors ./ backgroundReceptors;
    loopVar{ss}.(whichDirection).negativeReceptorContrast = contrastReceptors;

    % Calculate and store the spectra
    loopVar{ss}.(whichDirection).positiveModulationSPD = B_primary*modulationPrimary;
    loopVar{ss}.(whichDirection).negativeModulationSPD = B_primary*(backgroundPrimary-(modulationPrimary - backgroundPrimary));
    loopVar{ss}.(whichDirection).wavelengthsNm = SToWls(Svals);

end

% Transfer the loop variables into the result variable
for ss = 1:length(resultSet.whichDirectionSet)
    whichDirection = resultSet.whichDirectionSet{ss};
    resultSet.(whichDirection) = loopVar{ss}.(whichDirection);
end

end