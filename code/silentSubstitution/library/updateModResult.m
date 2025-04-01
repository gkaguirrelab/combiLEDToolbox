function modResult = updateModResult(modResult)
% Update the contrast and SPDs of a modResult with altered settings
%
% Syntax:
%   modResult = updateModResult(modResult)
%
% Description:
%   There are circumstances in which we wish to alter the primary settings
%   of a previously derived modulation result. For example, when performing
%   heterochromatic flicker photometry to null a luminance component. Given
%   a modResult input, this function will re-calculate photoreceptor
%   contrast and re-derive the SPDs implied by the primary settings. These
%   updated values are then placed in the modResult structure and returned.
%


% Extract some information from the modResult
backgroundPrimary = modResult.settingsBackground;
modulationPrimary = modResult.settingsHigh;
T_receptors = modResult.meta.T_receptors;
B_primary = modResult.meta.B_primary; 
ambientSpd = modResult.ambientSpd;

% Get the contrast results
contrastReceptorsBipolar = calcBipolarContrastReceptors(modulationPrimary,backgroundPrimary,T_receptors,B_primary,ambientSpd);
contrastReceptorsUnipolar = calcUnipolarContrastReceptors(modulationPrimary,backgroundPrimary,T_receptors,B_primary,ambientSpd);

% Obtain the SPDs and wavelength support
positiveModulationSPD = B_primary*modulationPrimary;
negativeModulationSPD = B_primary*(backgroundPrimary-(modulationPrimary - backgroundPrimary));

% Update modResult
modResult.contrastReceptorsBipolar = contrastReceptorsBipolar;
modResult.contrastReceptorsUnipolar = contrastReceptorsUnipolar;
modResult.positiveModulationSPD = positiveModulationSPD;
modResult.negativeModulationSPD = negativeModulationSPD;

end




