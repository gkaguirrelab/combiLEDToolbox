function filterProfile = idealDiscreteSampleFilter(sourceFreqsHz,discreteT)
% Amplitude of a sinusoid measured or produced by discrete device
%
% Syntax:
%   filterProfile = idealDiscreteSampleFilter(sourceFreqsHz,dTsignal)
%
% Description:
%   The ability of a device to measure (or produce) a sinusoidal modulation
%   as a function of temporal frequency is influenced by the refresh rate
%   of the device. This routine creates a model of such a device and
%   measures the attenuation in the measured (or produced) modulation as a
%   function of temporal frequency and device refresh rate. It is almost
%   certainly the case that there is a a better, formal description of this
%   phenomenon in the digital signal processing literature.
%
% Inputs:
%   sourceFreqsHz         - Vector of frequencies in Hz.
%   discreteT             - Scalar. The time (in seconds) between discrete
%                           samples of the sensor or source
%
% Optional key/value pairs:
%   none
%
% Outputs:
%   filterProfile         - The observed amplitude of modulations at the
%                           sourceFreqsHz for the device operating with
%                           discreteT sampling.
%


% Fixed values of the simulation
nCycles = 100;
dTsource = 0.0001;

for ii = 1:length(sourceFreqsHz)
    % Define the signal length
    sourceDurSecs = nCycles/sourceFreqsHz(ii);
    sourceTime = 0:dTsource:sourceDurSecs-dTsource;
    % Create a source modulation
    source = sin(sourceTime/(1/sourceFreqsHz(ii))*2*pi);
    % Downsample the source to create the signal
    signalTime = 0:discreteT:sourceDurSecs-discreteT;
    signal = interp1(sourceTime,source,signalTime,'linear');
    % Set up the regression matrix
    X = [];
    X(:,1) = sin(  sourceTime./(1/sourceFreqsHz(ii)).*2*pi );
    X(:,2) = cos(  sourceTime./(1/sourceFreqsHz(ii)).*2*pi );
    % Perform the fit
    y = interp1(signalTime,signal,sourceTime,'nearest','extrap')';
    b = X\y;
    filterProfile(ii)  = norm(b);
end

end