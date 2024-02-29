function [whichReceptorsToTargetVec,whichReceptorsToIgnoreVec,desiredContrast] = ...
    modDirectionDictionaryHuman(whichDirection,photoreceptors)

switch whichDirection
    case 'LminusM_foveal'
        whichReceptorsToTarget = {'L_2deg','M_2deg'};
        whichReceptorsToSilence = {'S_2deg','S_10deg'};
        whichReceptorsToIgnore = {'L_10deg','M_10deg','Mel','Rod'};
        desiredContrast = [1 -1];
    case 'LminusM_wide'
        % Attempt to achieve equivalent differential contrast on the L and
        % M cones in the center and the periphery. Need to also try and
        % equate the differential contrast on the penumbral variants of
        % these, otherwise we get Purkinje tree entopic effects in the
        % rapid flicker. After some fussing around, setting the desired
        % contrast of the peripheral field to be slightly lower than the
        % fovea result in a better search outcome.
        whichReceptorsToTarget = {'L_2deg','M_2deg','L_10deg','M_10deg','L_penum10','M_penum10'};
        whichReceptorsToSilence = {'S_2deg','S_10deg'};
        whichReceptorsToIgnore = {'Mel','Rod'};
        desiredContrast = [1 -1 0.9 -0.9 1 -1];
    case 'LplusM_wide'
        whichReceptorsToTarget = {'L_2deg','M_2deg','L_10deg','M_10deg'};
        whichReceptorsToSilence = {'S_2deg','S_10deg'};
        whichReceptorsToIgnore = {'Mel','Rod'};
        desiredContrast = [1 1 1 1];
    case 'S_wide'
        % Attempt to achieve equivalent contrast on the S cones in the
        % center and the periphery. Need to also silence the penumbral L
        % and Mo cones, otherwise we get Purkinje tree entopic effects in
        % the rapid flicker. If we list the penumbral cones as targets to
        % be silenced, the linear constraint on the search is too strict,
        % and we are unable to find a good solution. Instead, we list the
        % penumbral cones as modulation targets, but set their desired
        % contrast to zero.
        whichReceptorsToTarget = {'S_2deg','S_10deg','L_penum10','M_penum10'};
        whichReceptorsToSilence = {'L_2deg','M_2deg','L_10deg','M_10deg'};
        whichReceptorsToIgnore = {'Mel','Rod'};
        desiredContrast = [1 1 0 0];
    case 'LightFlux'
        whichReceptorsToTarget = {'L_2deg','M_2deg','S_2deg','L_10deg','M_10deg','S_10deg','Mel','Rod'};
        whichReceptorsToSilence = {};
        whichReceptorsToIgnore = {};
        desiredContrast = ones(1,8);
    case 'LMS'
        whichReceptorsToTarget = {'L_10deg','M_10deg','S_10deg'};
        whichReceptorsToSilence = {'Mel'};
        whichReceptorsToIgnore = {'L_2deg','M_2deg','S_2deg','Rod'};
        desiredContrast = [1 1 1];
    case 'Mel'
        whichReceptorsToTarget = {'Mel'};
        whichReceptorsToSilence = {'L_10deg','M_10deg','S_10deg'};
        whichReceptorsToIgnore = {'L_2deg','M_2deg','S_2deg','Rod'};
        desiredContrast = 1;
    case 'SnoMel'
        % Wide-field S modulation while silencing Mel
        whichReceptorsToTarget = {'S_2deg','S_10deg'};
        whichReceptorsToSilence = {'L_2deg','M_2deg','L_10deg','M_10deg','Mel'};
        whichReceptorsToIgnore = {'Rod','L_penum10','M_penum10'};
        desiredContrast = [1 1];
    case 'LplusMnoMel'
        whichReceptorsToTarget = {'L_2deg','M_2deg','L_10deg','M_10deg'};
        whichReceptorsToSilence = {'S_2deg','S_10deg','Mel',};
        whichReceptorsToIgnore = {'Rod'};
        desiredContrast = [1 1 1 1];        
    case 'SminusMel'
        whichReceptorsToTarget = {'S_10deg','Mel'};
        whichReceptorsToSilence = {'L_2deg','M_2deg','L_10deg','M_10deg'};
        whichReceptorsToIgnore = {'S_2deg','Rod'};
        desiredContrast = [1,-1];
    otherwise
        error('Not a recognized human modulation direction')
end

% Check that no receptor is listed more than once in the target, silence,
% or ignore lists
if any(cellfun(@(x) any(strcmp(x,whichReceptorsToIgnore)),whichReceptorsToSilence)) || ...
        any(cellfun(@(x) any(strcmp(x,whichReceptorsToSilence)),whichReceptorsToIgnore)) || ...
        any(cellfun(@(x) any(strcmp(x,whichReceptorsToIgnore)),whichReceptorsToTarget)) || ...
        any(cellfun(@(x) any(strcmp(x,whichReceptorsToSilence)),whichReceptorsToTarget))
    error('receptor types may only appear once in the list of target, silence, or ignore')
end

% Ensure that every targeted photoreceptor appears in the passed list of
% photoreceptors
photoreceptorNames = {photoreceptors(:).name};
if ~all(cellfun(@(x) any(strcmp(x,photoreceptorNames)),[whichReceptorsToTarget whichReceptorsToSilence whichReceptorsToIgnore]))
    error('The modulation direction considers a target that is not in the photoreceptors structure')
end

% If an entry in the photoreceptors structure is not listed in Target,
% Silence, or Ignore, then add it to Ignore.
if ~all(cellfun(@(x) any(strcmp(x,[whichReceptorsToTarget whichReceptorsToSilence whichReceptorsToIgnore])),photoreceptorNames))
    idxToAdd = ~cellfun(@(x) any(strcmp(x,[whichReceptorsToTarget whichReceptorsToSilence whichReceptorsToIgnore])),photoreceptorNames);
    whichReceptorsToIgnore = [whichReceptorsToIgnore photoreceptorNames(idxToAdd)];
end

% Ensure that the desiredContrast and whichReceptorsToTarget vectors are
% the same length.
if length(desiredContrast) ~= length(whichReceptorsToTarget)
    error('The desiredContrast and whichReceptorsToTarget vectors are not the same length')
end

% Assemble the vectors for targeting and ignoring
whichReceptorsToTargetVec = [];
for ii = 1:length(whichReceptorsToTarget)
    idx = find(strcmp(whichReceptorsToTarget{ii},photoreceptorNames));
    whichReceptorsToTargetVec(ii) = idx;
end

whichReceptorsToIgnoreVec = [];
for ii = 1:length(whichReceptorsToIgnore)
    idx = find(strcmp(whichReceptorsToIgnore{ii},photoreceptorNames));
    whichReceptorsToIgnoreVec(ii) = idx;
end


end