% In these experiments we will work with this overall frequency set:
%   freq = [1, 2, 3, 4, 5, 6, 8, 10, 12, 14, 16, 20, 24, 28, 32, 40];
%
% For the L-M studies, we will operate in the low range. We will obtain
% CDTs for:
%   TestFreqSet = [1,3,5,8,12,16,24]
%
% and then perform discrimination judgements with:
%   TestFreqSet = [3,5,8,12,16]
%   RefFreqSet = [1, 2, 3, 4, 5, 6, 8, 10, 12, 14, 16, 20, 24];
%

subjectID = 'HERO_gka';
modDirection = 'LminusM_wide';
TestFreqSet = [1,3,5,8,12,16,24];
observerAgeInYears = 53;
pupilDiameterMm = 3;
runCDTExperiment(subjectID,modDirection,...
    observerAgeInYears,pupilDiameterMm,...
    'TestFreqSet',TestFreqSet);
