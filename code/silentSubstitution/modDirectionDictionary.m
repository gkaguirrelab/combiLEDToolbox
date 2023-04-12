function [whichReceptorsToTargetVec,whichReceptorsToIgnoreVec,desiredContrast,...
    x0Background, matchConstraint, searchBackground] = modDirectionDictionary(whichDirection,photoreceptors)
%
%
%
%
% matchConstraint                 - Scalar. The difference in contrast on
%                                   photoreceptors is multiplied by the log
%                                   of this value

x0Background = repmat(0.5,8,1);
matchConstraint = 5;
searchBackground = false;

switch whichDirection
    case 'LminusM_foveal'
        whichReceptorsToTarget = {'L_2deg','M_2deg'};
        whichReceptorsToSilence = {'S_2deg','S_10deg'};
        whichReceptorsToIgnore = {'L_10deg','M_10deg','Mel','Rod'};
        desiredContrast = [1 -1];
        matchConstraint = 3;
    case 'LminusM_wide'
        whichReceptorsToTarget = {'L_2deg','M_2deg','L_10deg','M_10deg'};
        whichReceptorsToSilence = {'S_2deg','S_10deg'};
        whichReceptorsToIgnore = {'Mel','Rod'};
        desiredContrast = [1 -1 0.8 -0.8];
        matchConstraint = 3;
    case 'LplusM_wide'
        whichReceptorsToTarget = {'L_2deg','M_2deg','L_10deg','M_10deg'};
        whichReceptorsToSilence = {'S_2deg','S_10deg'};
        whichReceptorsToIgnore = {'Mel','Rod'};
        desiredContrast = [1 1 1 1];
        matchConstraint = 10;
    case 'S_wide'
        whichReceptorsToTarget = {'S_2deg','S_10deg'};
        whichReceptorsToSilence = {'L_2deg','M_2deg','L_10deg','M_10deg',};
        whichReceptorsToIgnore = {'Mel','Rod'};
        desiredContrast = [1 1];
    case 'LightFlux'
        whichReceptorsToTarget = {'L_2deg','M_2deg','S_2deg','L_10deg','M_10deg','S_10deg','Mel','Rod'};
        whichReceptorsToSilence = {};
        whichReceptorsToIgnore = {};
        desiredContrast = ones(1,8);
        matchConstraint = 3;
    case 'Mel'
        whichReceptorsToTarget = {'Mel'};
        whichReceptorsToSilence = {'L_10deg','M_10deg','S_10deg'};
        whichReceptorsToIgnore = {'L_2deg','M_2deg','S_2deg','Rod'};
        desiredContrast = 1;
        x0Background = [ 0.0823    0.0000    0.0000    0.0655    0.0007    0.3248    0.5499    0.4275 ]';
        searchBackground = false;
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

% Ensure that every photoreceptor in the passed list of photoreceptors
% appears somewhere as a target, silence, or ignored item.
if ~all(cellfun(@(x) any(strcmp(x,[whichReceptorsToTarget whichReceptorsToSilence whichReceptorsToIgnore])),photoreceptorNames))
    error('The modulation direction considers a target that is not in the photoreceptors structure')
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