function [whichReceptorsToTarget,whichReceptorsToIgnore,desiredContrast,x0Background] = ...
    modDirectionDictionary(whichDirection)

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

switch whichDirection
    case 'LminusM_wide'
        whichReceptorsToTarget = [1 2 4 5];
        whichReceptorsToIgnore = 7;
        desiredContrast = [1 -1 1 -1];
    case 'LminusM_foveal'
        whichReceptorsToTarget = [1 2];
        whichReceptorsToIgnore = [4 5 7];
        desiredContrast = [1 -1];
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
        x0Background = [ 0.2500    0.4998    0.5000    0.5000    0.5000    0.5000    0.5000    0.5000 ]';
    case 'LMSnoMel'
        whichReceptorsToTarget = [4 5 6];
        whichReceptorsToIgnore = [1 2 3];
        desiredContrast = [1 1 1];
        x0Background = [ 0.3682    0.2689    0.0823    0.2973    0.2550    0.4806    0.1355    0.3459 ]';
    case 'Mel'
        whichReceptorsToTarget = 7;
        whichReceptorsToIgnore = [1 2 3];
        desiredContrast = 1;
        x0Background = [ 0.4991    0    0.4543    0.4996    0.1784    0.4361    0.5116    0.0176 ]';
    case 'SnoMel'
        whichReceptorsToTarget = [6];
        whichReceptorsToIgnore = [1 2 3];
        desiredContrast = 1;        
        x0Background = [ 0.4755    0.3667    0.0001    0.2094    0.4131    0.2544    0.0000    0.4493 ]';
end

end