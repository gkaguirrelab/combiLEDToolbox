function contrastScale = contrastAttenuationByFreq(frequencies)
% Measurements made using the Klein ChromaSurf software by GKA
% on April 29, 2025. CombiLED C (A10L31XJ) was running the Arduino
% firmware committed to GitHub on this day. A 0.5 contrast, light
% flux sinusoidal modulation was presented at frequencies between
% 10 and 100 Hz. The "percent" amplitude of response as reported
% by the Klein software was recorded. The measurement at 10 Hz was
% 0.4840 contrast (reported by the Klein software as 96.8%). This
% small deviation from the 0.5 source could be due to ambient light
% intrusion in the measure. The set of amplitude responses across
% frequencies were scaled by this 10 Hz value to result in the 
% relative decrease in modulation depth as a function of modulation
% frequency.

frequencySupport = [
   0.1
   1.0000
   10.0000
   15.0000
   20.0000
   25.0000
   30.0000
   35.0000
   40.0000
   50.0000
   60.0000
   65.0000
   70.0000
   80.0000
   90.0000
  100.0000];

contrastRollOff = [
    1.0000
    1.0000
    1.0000
    1.0000
    0.9845
    0.9731
    0.9610
    0.9473
    0.9378
    0.9181
    0.9029
    0.8678
    0.8394
    0.7845
    0.7389
    0.6839];

% Sanity check the input. We can't extrapolate above highest measurement
mustBeInRange(frequencies,1e-6,max(frequencySupport));

% Interpolate from the data to the contrast values
contrastScale = interp1(log10(frequencySupport),contrastRollOff,log10(frequencies),'linear',1);

end