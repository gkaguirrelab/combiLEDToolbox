function [frq, pwr] = simplePSD( signal, ScanRate)
% Return the single-sided power spectrum of a signal
%
% Syntax:
%   [frq, pwr, phase] = simplePSD( signal, ScanRate)
%
% Description:
%   Perform an FFT of a real-valued input signal and then derive the single
%   sided output, in in units of power / Hz.
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
xdft = fft(signal, n); %do the actual work

% Generate the vector of frequencies
halfn = floor(n / 2)+1;
deltaf = 1 / ( n / ScanRate);
frq = (0:(halfn-1)) * deltaf;

% Calculate scaled two-sided amplitude spectrum
pwr = (1/(ScanRate*n))*abs(xdft).^2;

% Take the single-sided spectrum
pwr = pwr(1:halfn);

% Adjust the power for single-sided spectrum. The DC component (index 1) is
% correct. For other frequencies, multiply by 2.
if n > 1 % If more than one point
    pwr(2:end) = 2 * pwr(2:end);

    % If N is even, the Nyquist frequency (end of pwr) should not be
    % doubled from its original value. The line above doubled it, so we
    % divide by 2 to correct it.
    if mod(n, 2) == 0
        pwr(end) = pwr(end) / 2;
    end
end

end