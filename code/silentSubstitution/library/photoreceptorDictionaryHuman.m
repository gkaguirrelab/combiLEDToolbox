function photoreceptors = photoreceptorDictionaryHuman(varargin)

p = inputParser;
p.addParameter('observerAgeInYears',25,@isscalar)
p.addParameter('pupilDiameterMm',2,@isscalar)
p.parse(varargin{:});

% The set of photoreceptor classes
photoreceptorClassNames = {'L_2deg','M_2deg','S_2deg','L_10deg','M_10deg','S_10deg','Mel','Rod_2deg','Rod_10deg','L_penum10','M_penum10'};

for ii = 1:length(photoreceptorClassNames)

    photoreceptors(ii).name = photoreceptorClassNames{ii};

    % The youngest age defined for the lens transmitance is 20 years old
    photoreceptors(ii).observerAgeInYears = max([20, p.Results.observerAgeInYears]);
    photoreceptors(ii).pupilDiameterMm = p.Results.pupilDiameterMm;
    photoreceptors(ii).dlens = 0;
    photoreceptors(ii).dmac = 0;
    photoreceptors(ii).dphotopigment = 0;
    photoreceptors(ii).lambdaMaxShiftNm = 0;
    photoreceptors(ii).shiftType = 'log';
    photoreceptors(ii).returnPenumbralFlag = false;
    photoreceptors(ii).species = 'human';

    switch photoreceptors(ii).name
        case 'L_2deg'
            photoreceptors(ii).whichReceptor = 'L';
            photoreceptors(ii).fieldSizeDegrees = 2;
            photoreceptors(ii).plotColor = SSTDefaultReceptorColors('LCone');
        case 'M_2deg'
            photoreceptors(ii).whichReceptor = 'M';
            photoreceptors(ii).fieldSizeDegrees = 2;
            photoreceptors(ii).plotColor = SSTDefaultReceptorColors('MCone');
        case 'S_2deg'
            photoreceptors(ii).whichReceptor = 'S';
            photoreceptors(ii).fieldSizeDegrees = 2;
            photoreceptors(ii).plotColor = SSTDefaultReceptorColors('SCone');
        case 'L_10deg'
            photoreceptors(ii).whichReceptor = 'L';
            photoreceptors(ii).fieldSizeDegrees = 10;
            photoreceptors(ii).plotColor = SSTDefaultReceptorColors('LCone');
        case 'M_10deg'
            photoreceptors(ii).whichReceptor = 'M';
            photoreceptors(ii).fieldSizeDegrees = 10;
            photoreceptors(ii).plotColor = SSTDefaultReceptorColors('MCone');
        case 'S_10deg'
            photoreceptors(ii).whichReceptor = 'S';
            photoreceptors(ii).fieldSizeDegrees = 10;
            photoreceptors(ii).plotColor = SSTDefaultReceptorColors('SCone');
        case 'Mel'
            photoreceptors(ii).whichReceptor = 'Mel';
            photoreceptors(ii).fieldSizeDegrees = 10;
            photoreceptors(ii).plotColor = SSTDefaultReceptorColors('Mel');
        case 'Rod_2deg'
            photoreceptors(ii).whichReceptor = 'Rod';
            photoreceptors(ii).fieldSizeDegrees = 2;
            photoreceptors(ii).lambdaMax = 493;
            photoreceptors(ii).plotColor = SSTDefaultReceptorColors('Rod');
        case 'Rod_10deg'
            photoreceptors(ii).whichReceptor = 'Rod';
            photoreceptors(ii).fieldSizeDegrees = 10;
            photoreceptors(ii).lambdaMax = 493;
            photoreceptors(ii).plotColor = SSTDefaultReceptorColors('Rod');
        case 'L_penum10'
            photoreceptors(ii).whichReceptor = 'L';
            photoreceptors(ii).fieldSizeDegrees = 10;
            photoreceptors(ii).returnPenumbralFlag = true;
            photoreceptors(ii).plotColor = SSTDefaultReceptorColors('LConePenumbral');
        case 'M_penum10'
            photoreceptors(ii).whichReceptor = 'M';
            photoreceptors(ii).fieldSizeDegrees = 10;
            photoreceptors(ii).returnPenumbralFlag = true;
            photoreceptors(ii).plotColor = SSTDefaultReceptorColors('MConePenumbral');
    end

end


end