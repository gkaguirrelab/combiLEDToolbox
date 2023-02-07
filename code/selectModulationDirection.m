function [whichReceptorsToTarget,whichReceptorsToIgnore,whichReceptorsToMinimize,desiredContrast] = ...
    selectModulationDirection(whichDirection)

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

switch whichDirection
    case 'LMS'
        whichReceptorsToTarget = [4 5 6];
        whichReceptorsToIgnore = [1 2 3];
        whichReceptorsToMinimize = []; % This can be left empty. Any receptor that is neither targeted nor ignored will be silenced
        desiredContrast = [0.35 0.35 0.35];
    case 'LminusM'
        whichReceptorsToTarget = [1 2 4 5];
        whichReceptorsToIgnore = 7;
        whichReceptorsToMinimize = []; % This can be left empty. Any receptor that is neither targeted nor ignored will be silenced
        desiredContrast = [0.10 -0.10 0.10 -0.10];
    case 'L'
        whichReceptorsToTarget = [1 4];
        whichReceptorsToIgnore = 7;
        whichReceptorsToMinimize = []; % This can be left empty. Any receptor that is neither targeted nor ignored will be silenced
        desiredContrast = [0.15 0.15];
    case 'M'
        whichReceptorsToTarget = [2 5];
        whichReceptorsToIgnore = 7;
        whichReceptorsToMinimize = []; % This can be left empty. Any receptor that is neither targeted nor ignored will be silenced
        desiredContrast = [0.15 0.15];
    case 'S'
        whichReceptorsToTarget = [3 6];
        whichReceptorsToIgnore = [7];
        whichReceptorsToMinimize = []; % This can be left empty. Any receptor that is neither targeted nor ignored will be silenced
        desiredContrast = [0.75 0.75];
    case 'Mel'
        whichReceptorsToTarget = 7;
        whichReceptorsToIgnore = [1 2 3];
        whichReceptorsToMinimize = []; % This can be left empty. Any receptor that is neither targeted nor ignored will be silenced
        desiredContrast = 0.5;
    case 'SnoMel'
        whichReceptorsToTarget = 6;
        whichReceptorsToIgnore = [1 2 3];
        whichReceptorsToMinimize = []; % This can be left empty. Any receptor that is neither targeted nor ignored will be silenced
        desiredContrast = 0.60;
end

end