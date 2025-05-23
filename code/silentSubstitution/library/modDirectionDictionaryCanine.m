function [whichReceptorsToTargetVec,whichReceptorsToIgnoreVec,desiredContrast,lightFluxFlag] = ...
    modDirectionDictionaryCanine(whichDirection,photoreceptors)

lightFluxFlag = false;

switch whichDirection
    case 'LightFlux'
        whichReceptorsToTarget = {'canineS','canineMel','canineML'};
        whichReceptorsToSilence = {};
        whichReceptorsToIgnore = {'canineRod'};
        desiredContrast = [1 1 1];
        lightFluxFlag = true;
    case 'mel'
        whichReceptorsToTarget = {'canineMel'};
        whichReceptorsToSilence = {'canineS','canineML'};
        whichReceptorsToIgnore = {'canineRod'};
        desiredContrast = [1];
    case 'MLplusS'
        whichReceptorsToTarget = {'canineS','canineML','canineRod'};
        whichReceptorsToSilence = {'canineMel'};
        whichReceptorsToIgnore = {};
        desiredContrast = [1.0 1.1 0.05];
    case 'MLminusS'
        % We have to allow just a little bit of rod contrast to create a
        % modulation that has desired 25% contrast on the ML-S mechanism.
        % Additionally, there is some weird property of the search that
        % requires specification of an unequal contrast on the S and L, but
        % this results in a balanced modulation at the solution.
        whichReceptorsToTarget = {'canineS','canineML','canineRod'};
        whichReceptorsToSilence = {'canineMel'};
        whichReceptorsToIgnore = {};
        desiredContrast = [0.99 -1.1 -0.02];
    otherwise
        error('Not a defined modulation')
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