function [frq, amp, phase] = simpleFFT( signal, ScanRate)
% Return the single-sided output of an FFT
%
% Syntax:
%   [frq, amp, phase] = simpleFFT( signal, ScanRate)
%
% Description:
%   Perform an FFT of a real-valued input signal and then derive the single
%   sided output, in amplitude and phase, scaled to the same units as the
%   input.
%
% Inputs:
%   signal                - Numeric vector
%   ScanRate              - Scalar. The sampling frequency in Hz.
%
% Outputs:
%   none
%   frq                   - a vector of frequency points (in Hertz)
%   amp                   - Numeric vector. Amplitudes (same units as the
%                           input signal)
%   phase                 - Numeric vector. Phases (in radians)
%

n = length(signal);
Y_fft = fft(signal, n); %do the actual work

% Generate the vector of frequencies
halfn = floor(n / 2)+1;
deltaf = 1 / ( n / ScanRate);
frq = (0:(halfn-1)) * deltaf;

% Calculate scaled two-sided amplitude spectrum
P2_amplitude = abs(Y_fft / n);

% Calculate single-sided amplitude spectrum (magnitudes)
P1_magnitude = P2_amplitude(1:floor(n/2)+1);

% Adjust amplitudes for single-sided spectrum
% The DC component (index 1) is P1_magnitude(1) which is abs(Y_fft(1))/N.
% This is correct. For other frequencies, multiply by 2.
if n > 1 % If more than one point
    amp = P1_magnitude; % Initialize with magnitudes
    amp(2:end) = 2 * amp(2:end);

    % If N is even, the Nyquist frequency (end of P1_amplitude_final)
    % should not be doubled from its original abs(Y_fft(n/2+1))/n value.
    % The line above doubled it, so we divide by 2 to correct it.
    if mod(n, 2) == 0
        amp(end) = amp(end) / 2;
    end
else
    amp = P1_magnitude; % Only DC component
end

% Obtain the phase
phase = angle(Y_fft(1:halfn));

end