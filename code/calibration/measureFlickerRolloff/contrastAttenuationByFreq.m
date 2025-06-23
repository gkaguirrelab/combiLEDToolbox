function contrastScale = contrastAttenuationByFreq(frequencies)
% The expected contrast roll-off of the combiLED as a function of frequency
%
% Syntax:
%   contrastScale = contrastAttenuationByFreq(frequencies)
%
% Description:
%   On June 23, 2025, we (GKA and Sophia Miarabal) made measurements of the
%   sinusoidal flicker output of the CombiLED-A device. The light from the
%   combiLED was passed to an integrating sphere, and measured using the
%   Flicker-BT device from labSphere. We measured 2 second increments at
%   5000 Hz across a range of frequencies. We fit the time series data for
%   each source frequency using a Fourier regression model and extracted
%   the amplitude of response. The resulting temporal transfer function was
%   then modeled as the output of an ideal light source with a fixed,
%   discrete refresh rate. We found that an ideal device with a refresh
%   rate of 209.88 Hz provided an excellent description of the data.
%
%   This routine models the contrast attentuation by frequency by making
%   use of the idealDiscreteSampleFilter function
%
% Inputs:
%  frequencies            - Vector of frequencies in Hz.
%
% Optional key/value pairs:
%   none
%
% Outputs:
%   contrastScale         - Scalar. The contast attenuation for the
%                           specified frequencies.


% The observed sampling rate of combiLED-A
discreteT = 1/209.88;

% The contrast for a discretely sampled source
contrastScale = idealDiscreteSampleFilter(frequencies,discreteT);

end