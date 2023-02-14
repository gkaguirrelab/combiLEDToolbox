function [whichReceptorsToTarget,whichReceptorsToIgnore,desiredContrast,...
    x0Background, matchConstraint, searchBackground] = modDirectionDictionary(whichDirection)
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
    case 'LminusM_wide'
        whichReceptorsToTarget = [1 2 4 5];
        whichReceptorsToIgnore = 7;
        desiredContrast = [1 -1 1 -1];
    case 'LminusM_foveal'
        whichReceptorsToTarget = [1 2];
        whichReceptorsToIgnore = [4 5 6 7];
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
        matchConstraint = 2;
    case 'M_foveal'
        whichReceptorsToTarget = [2];
        whichReceptorsToIgnore = [4 5 6 7];
        desiredContrast = [1];
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
        matchConstraint = 3;
    case 'LMSnoMel'
        % 63% contrast on the peripheral LMS cones with ~1% difference
        % between the cone classes
        whichReceptorsToTarget = [4 5 6];
        whichReceptorsToIgnore = [1 2 3];
        desiredContrast = [1 1 1];
        x0Background = [ 0.2996    0.0487    0.0003    0.1741    0.1328    0.4950    0.4996    0.5863 ]';
        matchConstraint = 5;
        searchBackground = true;
    case 'Mel'
        % 63% contrast on Mel
        whichReceptorsToTarget = 7;
        whichReceptorsToIgnore = [1 2 3];
        desiredContrast = 1;
        x0Background = [ 0.4553    0.0000    0.0269    0.3823    0.0735    0.5012    0.1829    0.4890 ]';
        searchBackground = true;
    case 'SnoMel'
        % 91% contrast on peripheral S-cones
        whichReceptorsToTarget = [6];
        whichReceptorsToIgnore = [1 2 3];
        desiredContrast = 1;
        x0Background = [ 0.4897    0.2113         0    0.0974    0.0066    0.5031    0.1569    0.4859 ]';
        searchBackground = true;
end

end