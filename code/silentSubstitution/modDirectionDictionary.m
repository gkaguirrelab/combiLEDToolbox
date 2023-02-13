function [whichReceptorsToTarget,whichReceptorsToIgnore,desiredContrast,...
    x0Background, matchConstraint] = modDirectionDictionary(whichDirection)

%% Define the receptor sets to isolate
% I consider the following modulations:
%   LMS -   Equal contrast on the peripheral cones, silencing Mel, as
%           this modulation would mostly be used in conjunction with
%           light flux and mel stimuli
%   LminusM - An L-M modulation that has equal contrast with eccentricity.
%           Ignore mel.
%   S -     An S modulation that has equal contrast with eccentricity.
%           Ignore mel.
%   Mel -   Mel directed, silencing peripheral but not central cones. It is
%           very hard to get any contrast on Mel while silencing both
%           central and peripheral cones. This stimulus would be used in
%           concert with occlusion of the macular region of the stimulus.
%   SnoMel- S modulation in the periphery that silences melanopsin.

x0Background = repmat(0.5,8,1);
matchConstraint = 0;

switch whichDirection
    case 'LminusM_wide'
        whichReceptorsToTarget = [1 2 4 5];
        whichReceptorsToIgnore = 7;
        desiredContrast = [1 -1 1 -1];
        x0Background = [ 0.8418    0.1812    0.0923    0.0017    0.0541    0.1092    0.2757    0.5380 ]';
    case 'LminusM_foveal'
        whichReceptorsToTarget = [1 2];
        whichReceptorsToIgnore = [4 5 6 7];
        desiredContrast = [1 -1];
        matchConstraint = -5;
    case 'L_wide'
        whichReceptorsToTarget = [1 4];
        whichReceptorsToIgnore = [7];
        desiredContrast = [1 1];
    case 'L_foveal'
        whichReceptorsToTarget = [1];
        whichReceptorsToIgnore = [4 5 6 7];
        desiredContrast = [1];
    case 'M_wide'
        whichReceptorsToTarget = [2 5];
        whichReceptorsToIgnore = [7];
        desiredContrast = [1 1];
    case 'S_wide'
        whichReceptorsToTarget = [3 6];
        whichReceptorsToIgnore = [7];
        desiredContrast = [1 1];
    case 'S_foveal'
        whichReceptorsToTarget = [3];
        whichReceptorsToIgnore = [6 7];
        desiredContrast = [1];
    case 'LightFlux'
        whichReceptorsToTarget = [4 5 6 7];
        whichReceptorsToIgnore = [1 2 3];
        desiredContrast = [1 1 1 1];
        x0Background = [ 0.5000    0.5000    0.5000    0.5000    0.5000    0.5000    0.5000    0.5000 ]';
    case 'LMSnoMel'
        whichReceptorsToTarget = [4 5 6];
        whichReceptorsToIgnore = [1 2 3];
        desiredContrast = [1 1 1];
        x0Background = [ 0.4939    0.4804    0.1059    0.4419    0.3873    0.3524    0.8411    0.6647 ]';
        matchConstraint = 1;
    case 'Mel'
        whichReceptorsToTarget = 7;
        whichReceptorsToIgnore = [1 2 3];
        desiredContrast = 1;
        x0Background = [ 0.4990    0.2744    0.2796    0.4404    0.1324    0.5010    0.1173    0.4995 ]';
    case 'SnoMel'
        whichReceptorsToTarget = [6];
        whichReceptorsToIgnore = [1 2 3];
        desiredContrast = 1;        
        x0Background = [ 0.4864    0.2112         0    0.0981    0.0059    0.5038    0.2816    0.4377 ]';
end

end