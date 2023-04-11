function [T_energyNormalized,T_energy,adjIndDiffParams] = returnHumanSpectralSensitivity(photoreceptorStruct,S)
% returnHumanSpectralSensitivity
%
% Get spectral sensitivities, expressed as energy (isomerizations-per-
% second as a function of radiance expressed in Watts), but then normalized
% to a max of 1.

% Optional key/value pairs:
%     'whichParameter' - Determines which parameter which should be varied.
%                        Possible options are (default, 'dlens'):
%                           'dlens' - lens density
%                           'dmac' - macular pigment density
%                           'dphotopigmentL' - L cone photopigment density
%                           'dphotopigmentM' - M cone photopigment density
%                           'dphotopigmentS' - S cone photopigment density
%                           'lambdaMaxShiftL' - L lambda-max shift
%                           'lambdaMaxShiftM' - M lambda-max shift
%                           'lambdaMaxShiftS' - S lambda-max shift
%                           'obsPupilDiameterMm' - observer's pupil diameter
%
%     'NTitrations' - The step sizes for each parameter variation, i.e. how
%                     many individual parameter values are calculated.
%                     (Default: 50)
%

% Extract fields from the photoreceptorStruct into variables
fieldSizeDegrees = photoreceptorStruct.fieldSizeDegrees;
observerAgeInYears = photoreceptorStruct.observerAgeInYears;
pupilDiameterMm = photoreceptorStruct.pupilDiameterMm;
returnPenumbralFlag = photoreceptorStruct.returnPenumbralFlag;

% Get the standard structure form of the individual difference params
indDiffParams = SSTDefaultIndDiffParams();

% Extract fields from the photoreceptorStruct for pre-receptoral individual
% differences
indDiffParams.shiftType = photoreceptorStruct.shiftType;
indDiffParams.dlens = photoreceptorStruct.dlens;
indDiffParams.dmac = photoreceptorStruct.dmac;

% Obtain the quantal isomerizations for the specified receptor class
switch photoreceptorStruct.whichReceptor
    case 'L'
        idx = 1;
        % Update the indDiffParams
        indDiffParams.dphotopigment(idx) = photoreceptorStruct.dphotopigment;
        indDiffParams.lambdaMaxShift(idx) = photoreceptorStruct.lambdaMaxShiftNm;
        % Call out to ComputeCIEConeFundamentals
        [~,~,T_quantalIsomerizations,adjIndDiffParams] = ...
            ComputeCIEConeFundamentals(S,fieldSizeDegrees,observerAgeInYears,pupilDiameterMm,[],[],[],[],[],[],indDiffParams);
    case 'M'
        idx = 2;
        % Update the indDiffParams
        indDiffParams.dphotopigment(idx) = photoreceptorStruct.dphotopigment;
        indDiffParams.lambdaMaxShift(idx) = photoreceptorStruct.lambdaMaxShiftNm;
        % Call out to ComputeCIEConeFundamentals
        [~,~,T_quantalIsomerizations,adjIndDiffParams] = ...
            ComputeCIEConeFundamentals(S,fieldSizeDegrees,observerAgeInYears,pupilDiameterMm,[],[],[],[],[],[],indDiffParams);
    case 'S'
        idx = 3;
        % Update the indDiffParams
        indDiffParams.dphotopigment(idx) = photoreceptorStruct.dphotopigment;
        indDiffParams.lambdaMaxShift(idx) = photoreceptorStruct.lambdaMaxShiftNm;
        % Call out to ComputeCIEConeFundamentals
        [~,~,T_quantalIsomerizations,adjIndDiffParams] = ...
            ComputeCIEConeFundamentals(S,fieldSizeDegrees,observerAgeInYears,pupilDiameterMm,[],[],[],[],[],[],indDiffParams);
    case 'Mel'
        idx = 1;
        indDiffParams.dphotopigment = photoreceptorStruct.dphotopigment;
        indDiffParams.lambdaMaxShift = photoreceptorStruct.lambdaMaxShiftNm;
        % Call out to ComputeCIEConeFundamentals
        [~,~,T_quantalIsomerizations,adjIndDiffParams] = ComputeCIEMelFundamental(S,fieldSizeDegrees,observerAgeInYears,pupilDiameterMm,indDiffParams);
    case 'Rod'
        idx = 1;
        indDiffParams.dphotopigment = photoreceptorStruct.dphotopigment;
        indDiffParams.lambdaMaxShift = photoreceptorStruct.lambdaMaxShiftNm;
        % Call out to ComputeCIEConeFundamentals
        [~,~,T_quantalIsomerizations,adjIndDiffParams] = ComputeCIERodFundamental(S,fieldSizeDegrees,observerAgeInYears,pupilDiameterMm,indDiffParams);
end

% Retain just the requested photoreceptor (the cone routine returns all 3)
T_quantalIsomerizations = T_quantalIsomerizations(idx,:);
adjIndDiffParams.absorbance = adjIndDiffParams.absorbance(idx,:);
adjIndDiffParams.absorptance = adjIndDiffParams.absorptance(idx,:);
adjIndDiffParams.dphotopigment = adjIndDiffParams.dphotopigment(idx);

% Calculate penumbral variant
if returnPenumbralFlag

    % We assume standard parameters here.
    source = 'Prahl';
    vesselOxyFraction = 0.85;
    vesselOverallThicknessUm = 5;
    trans_Hemoglobin = GetHemoglobinTransmittance(S, vesselOxyFraction, vesselOverallThicknessUm, source);

    T_quantalIsomerizations = T_quantalIsomerizations .* trans_Hemoglobin';
end

% Convert to energy fundamentals
T_energy = EnergyToQuanta(S,T_quantalIsomerizations')';

% And normalize the energy fundamentals
T_energyNormalized = bsxfun(@rdivide,T_energy,max(T_energy, [], 2));

end