function T_energyNormalized = returnCanineSpectralSensitivity(photoreceptorStruct,S)
% Provides the spectral sensitivity function for a specified photoreceptor
%
% Syntax:
%  T_energyNormalized = returncanineSpectralSensitivity(photoreceptorStruct,S)
%
% Description:
%   Provides the spectral sensitivity of a specified canine photoreceptors
%   at the wavelengths specified by S. The sensitivity is expressed as
%   energy (isomerizations-per-second as a function of radiance expressed
%   in Watts), normalized to a max of 1. The spectral sensitivity is
%   expressed relative to light arriving at the cornea.
%
%   The values used are derived from the Lucas lab (see README.txt file in
%   the data directory). Additionally, we generate a human L cone class and
%   subject it to canine pre-receptoral filtering .
%
%   The properties of the photoreceptor are specified in the passed
%   photoreceptorStruct. The required fields are:
%       whichReceptor     - Char vector with one of these values:
%                               {'sc','mel','rh','mc','L'}
%
% Inputs:
%   photoreceptorStruct   - Structure. Contents described above.
%   S                     - 1x3 vector, specifiying the wavelengths at
%                           which to return the spectal sensitivity.
%
% Outputs:
%   T_energyNormalized
%   T_energy
%   adjIndDiffParams
%


%% Canine lens tranmittance
% A measurement of the spectral transmission of the canine crystaline lens
% was take from Supplementary figure 3D of:
%
%   Douglas, R. H., and G. Jeffery. "The spectral transmission of ocular
%   media suggests ultraviolet sensitivity is widespread among mammals."
%   Proceedings of the Royal Society of London B: Biological Sciences
%   281.1780 (2014): 20132995.
%
% It was possible to download the Word Document supplement, which contained
% an embedded Excel chart. I extracted the values from this chart, which
% are expressed as % transmission.

% Source canine lens values
sourceWavelenths = 301:700;
sourceLensTransmittance = [7.0860, 4.8683, 6.6820, 7.6340, 6.3445, 4.9310, 3.7590, 2.1141, 3.2555, 2.3681, 2.1341, 6.0070, 9.6535, 13.9250, 18.9300, 23.5850, 27.9900, 32.8450, 36.1100, 37.5850, 39.5750, 42.8450, 44.8600, 45.4700, 45.2800, 45.8250, 48.1300, 49.3200, 48.2200, 47.1200, 48.1800, 48.2150, 48.0700, 49.0950, 50.0250, 49.3400, 49.2550, 50.5900, 51.3950, 52.9250, 52.4400, 52.7000, 53.6550, 54.6750, 55.6900, 54.9750, 55.6650, 57.0600, 57.6250, 57.9750, 58.3900, 58.2550, 58.5450, 59.3300, 59.2750, 59.8100, 61.5950, 62.5550, 62.9600, 63.5700, 64.3550, 64.9200, 64.7300, 64.1450, 64.9100, 66.4500, 67.3350, 67.1150, 66.9050, 67.1150, 68.2250, 70.0550, 70.9000, 70.8150, 70.8200, 71.8050, 72.2000, 71.5000, 72.3850, 73.8850, 74.3500, 74.7050, 74.9850, 74.8550, 75.5650, 76.6150, 77.1600, 77.0750, 76.4900, 77.0700, 77.9050, 78.6300, 78.8350, 78.7550, 79.1150, 79.4100, 80.3650, 81.3800, 81.4000, 80.8250, 80.5350, 80.6250, 80.9000, 81.3050, 80.9950, 80.8200, 81.3000, 82.0450, 82.1100, 81.7750, 82.1250, 82.5600, 82.3700, 82.4200, 82.8900, 83.0300, 83.1200, 83.1900, 83.1700, 83.3950, 84.5550, 85.0650, 84.9200, 84.8550, 85.0550, 85.7150, 86.2250, 86.4650, 86.0250, 86.4650, 87.2050, 87.1650, 87.1500, 86.7950, 87.3000, 87.6700, 87.3550, 87.7050, 88.1200, 88.2900, 88.7650, 89.0050, 88.9600, 88.8500, 88.5800, 88.7900, 88.6950, 88.7050, 89.0100, 88.9500, 89.0350, 89.3550, 89.5100, 89.7200, 89.9100, 89.8950, 90.0200, 90.0700, 89.8400, 89.9700, 90.3100, 90.6000, 90.8800, 91.0700, 91.2850, 91.1450, 91.2550, 91.4150, 91.1550, 91.3500, 91.1750, 90.9900, 91.2400, 91.4350, 91.5250, 91.5450, 91.6350, 91.8650, 91.9600, 91.9450, 92.5550, 92.7600, 92.5200, 92.5700, 92.3050, 92.1550, 92.1950, 92.2750, 92.5950, 92.7600, 92.8700, 92.8300, 92.5100, 92.3000, 92.7350, 92.9950, 92.6800, 92.9450, 93.0650, 92.8050, 92.6550, 92.4950, 92.8750, 93.2850, 92.9700, 92.8300, 92.7350, 92.7600, 93.1650, 93.2850, 92.9550, 93.0150, 93.0950, 92.7550, 92.6100, 92.7150, 93.0350, 92.9250, 92.8650, 92.7800, 92.7250, 92.9700, 93.4250, 93.5050, 93.6100, 93.8150, 93.5400, 93.5850, 93.4250, 93.1350, 93.0600, 93.2200, 93.7300, 93.8250, 93.4150, 93.4150, 93.5750, 93.4200, 93.4450, 93.4250, 93.5000, 93.5600, 93.6650, 94.0650, 93.9150, 93.6250, 93.8450, 94.0600, 93.9300, 93.8500, 93.9650, 93.8350, 93.8550, 94.0400, 94.1000, 94.0650, 93.9750, 93.8250, 93.9700, 94.2250, 94.1150, 94.1150, 94.4600, 94.3650, 94.0000, 94.2450, 94.5250, 94.3900, 94.2650, 94.4300, 94.1050, 93.8050, 94.1850, 94.2750, 94.2050, 94.4550, 94.5100, 94.2600, 94.3400, 94.6650, 95.0200, 94.9700, 95.0600, 95.3150, 95.2100, 95.2300, 95.2300, 95.2650, 95.4600, 95.4600, 95.3400, 95.6100, 95.5800, 95.2000, 95.0800, 95.2400, 95.4300, 95.4150, 95.5850, 95.6850, 95.6950, 95.6600, 95.6450, 95.4900, 95.4400, 95.6150, 95.7400, 95.9400, 96.2750, 96.3900, 96.2950, 96.2700, 95.9700, 95.9300, 96.1850, 96.2500, 96.1800, 96.2150, 96.2100, 96.1900, 96.2850, 96.4050, 96.4700, 96.5600, 96.4650, 96.7050, 97.0300, 96.6250, 96.5300, 96.4650, 96.2700, 96.6050, 96.8050, 96.7350, 96.6900, 96.8350, 96.8300, 96.7850, 96.7400, 96.7600, 97.0500, 97.0450, 96.9200, 96.8050, 96.9800, 97.2650, 97.2450, 97.1450, 97.1950, 97.6750, 97.9800, 97.8600, 97.7150, 97.3950, 97.2450, 97.4600, 97.8050, 97.7850, 97.8650, 97.8600, 97.7450, 97.8050, 97.9800, 98.1050, 98.0850, 98.3700, 98.5600, 98.4600, 98.2750, 98.2550, 98.5700, 98.8250, 98.6150, 98.8350, 98.9900, 98.6150, 98.3100, 98.3750, 98.5150, 98.4650, 98.4650, 98.7500, 99.0550, 99.0150, 99.3850, 99.5000, 99.0300, 98.8450, 99.1050, 98.9500, 98.7950, 98.9350, 99.1300, 99.3950, 99.1600, 99.0350, 99.4350, 99.6450, 99.2700, 99.0000];

% Convert S to wls
wls = SToWls(S);
deltaWls = wls(2)-wls(1);

% Obtain the spline fitted transmittance values at wls
minWl = floor(min(sourceWavelenths)/deltaWls)*deltaWls;
maxWl = ceil(max(sourceWavelenths)/deltaWls)*deltaWls;
if minWl<wls(1)
    minWl=wls(1);
end
if maxWl>wls(end)
    maxWl=wls(end);
end
transmitPortion = spline(sourceWavelenths,sourceLensTransmittance,minWl:deltaWls:maxWl);
transmittance = zeros(size(wls));
idx1 = find(wls==minWl);
if isempty(idx1)
    idx1=1;
end
idx2 = find(wls==maxWl);
transmittance(idx1:idx2) = transmitPortion;
transmittance(idx2:end) = transmitPortion(end);
transmittance = (transmittance/100)';

% Put in the lens
photoreceptors.lensDensity.transmittance = transmittance;

% Set a few values that aren't used, but are needed for code execution
ageInYears = 32;
pupilDiameterMm = 3;
fieldSizeDegrees = 20;

% Obtain the quantal isomerizations for the specified receptor class
switch photoreceptorStruct.whichReceptor
    case 'sc'
        photoreceptors = DefaultPhotoreceptors('LivingDog');
        photoreceptors.types = {'SCone'};
        photoreceptors.nomogram.S = S;
        photoreceptors.pupilDiameter.value = [];
        photoreceptors.nomogram.lambdaMax = 429;
        photoreceptors.fieldSizeDegrees = fieldSizeDegrees;
        photoreceptors.ageInYears = ageInYears;
        photoreceptors.pupilDiameter.value = pupilDiameterMm;

    case 'mel'
        photoreceptors.types = {'Melanopsin'};
        photoreceptors.nomogram.S = S;
        photoreceptors.axialDensity.source = 'Value provided directly';
        photoreceptors.axialDensity.value = 0.015;
        photoreceptors.nomogram.source = 'Govardovskii';
        photoreceptors.nomogram.lambdaMax = 480;
        photoreceptors.pupilDiameter.source = 'PennDog';
        photoreceptors.pupilDiameter.value = [];
        photoreceptors.quantalEfficiency.source = 'Generic';
        photoreceptors.macularPigmentDensity.source = 'None';
        photoreceptors.species = 'Canine';

    case 'rh'
        photoreceptors = DefaultPhotoreceptors('LivingDog');
        photoreceptors.types = {'Rod'};
        photoreceptors.nomogram.S = S;
        photoreceptors.pupilDiameter.value = [];
        photoreceptors.nomogram.lambdaMax = 506;
        photoreceptors.fieldSizeDegrees = fieldSizeDegrees;
        photoreceptors.ageInYears = ageInYears;
        photoreceptors.pupilDiameter.value = pupilDiameterMm;

    case 'mc'
        photoreceptors = DefaultPhotoreceptors('LivingDog');
        photoreceptors.types = {'LCone'};
        photoreceptors.nomogram.S = S;
        photoreceptors.pupilDiameter.value = [];
        photoreceptors.nomogram.lambdaMax = 555;
        photoreceptors.fieldSizeDegrees = fieldSizeDegrees;
        photoreceptors.ageInYears = ageInYears;
        photoreceptors.pupilDiameter.value = pupilDiameterMm;
end

% Fill in the values
photoreceptors = FillInPhotoreceptors(photoreceptors);

% Pull out the isomerization expression of sensitivity
T_quantalIsomerizations = photoreceptors.quantalFundamentals;

% Handle a passed extra filter. This may be the transmittance of a
% spectacle or contact lens worn by the observer
if isfield(photoreceptorStruct,'ef')
    % Pull the values out of the photoreceptorStruct
    efS = photoreceptorStruct.ef.S;
    efTrans = photoreceptorStruct.ef.trans;
    % Extend the filter if necessary to cover the range of S

    % Fit a spline to the extra filter transmittance spectrum
    efTransSpline = spline(SToWls(efS),efTrans,SToWls(S));
    % Apply the filter
    T_quantalIsomerizations = T_quantalIsomerizations .* efTransSpline';
end

% Convert to energy fundamentals
T_energy = EnergyToQuanta(S,photoreceptors.quantalFundamentals')';

% And normalize the energy fundamentals
T_energyNormalized = bsxfun(@rdivide,T_energy,max(T_energy, [], 2));


end