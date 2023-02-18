function predictedProportions = qpPFJoganStocker(stimParams,psiParams)
% qpPFJorganStocker  The Jorgan & Stocker JoV 2014 psychometric function
%
% Usage:
%     predictedProportions = qpPFJorganStocker(stimParams,psiParams)
%
% Description:
%   The probability, derived from signal detection theory, that an observer
%   will select reference stimulus 2 over reference stimulus 1 given the
%   input properties. This is based upon code written by M Jogan and
%   described in:
%
%       "A new two-alternative forced choice method for the unbiased 
%       characterization of perceptual bias and discriminability"
%       M Jogan and A. Stocker 
%       Journal of Vision, March 13, 2014, vol. 14 no.3
%
%  The parameters are:
%   r1Val, r2Val            - Scalar. The value of a stimulus parameter 
%                             that varies between the reference stimuli
%   tVal                    - Scalar. The value of a stimulus parameter for
%                             the test
%   rSigma, tSigma          - Noise parameters for the reference and the
%                             test
%   bias                    - Scalar. Difference between perceived value 
%                             and true value of test (in units of rVal,
%                             tVal)
%
% Inputs:
%     stimParams    nx3 matrix. Each row contains the stimulus parameters:
%                       ref1Val, ref2Val, testVal
%     psiParams     nx3 matrix. Each row has the psychometric parameters:
%                       rSigma, tSigma, tVal
%
% Output:
%     predictedProportions  nx2 matrrix, where each row is a vector of 
%                   predicted proportions for each outcome:
%                       no (i.e., probSelectRef1), yes, (probSelectRef2)
%
% Optional key/value pairs
%     None


%% Here is the Matlab version
if (size(psiParams,2) ~= 3)
    error('Three psi parameters required');
end
if (size(psiParams,1) ~= 1)
    error('Should be a vector');
end
if (size(stimParams,2) ~= 3)
    error('Three stim parameters');
end


%% Grab params
r1Val = stimParams(:,1);
r2Val = stimParams(:,2);
tVal = stimParams(:,3);
rSigma = psiParams(:,1);
tSigma = psiParams(:,2);
bias = psiParams(:,3);

nStim = size(stimParams,1);
predictedProportions = zeros(nStim,2);

%% Compute
u = r1Val - r2Val; 
v = r1Val + r2Val - (2 .* tVal);

uSigma = sqrt( 2 * rSigma.^2 );
vSigma = sqrt( 2 * rSigma.^2 + 4 * tSigma.^2);

uMean = 0;
vMean = 2 .* bias;

uCdf = normcdf(u, uMean, uSigma);
vCdf = normcdf(v, vMean, vSigma);

pChooseR2 = uCdf .* vCdf + (1-uCdf) .* (1-vCdf);

predictedProportions(:,1) = 1-pChooseR2; % Probability of not choosing R2
predictedProportions(:,2) = pChooseR2; % Probability of choosing R2

end


