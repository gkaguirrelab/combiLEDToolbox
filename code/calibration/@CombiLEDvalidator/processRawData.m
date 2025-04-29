function obj = processRawData(obj)
    % reset processData property
    obj.processedData = [];

    % Get some things from the object
    rawData = obj.rawData;
    nMeas = size(rawData.gammaCurveSortIndices,3);
    
    % Loop over the settings levels and create the modulation spectra
    % across phase
    obj.processedData.phaseVals = linspace(0,1,nMeas+1)*2*pi;
    ambient = rawData.ambientMeasurements;
    modSPDsByPhase(1,:) = ambient;     
    for pp = 1:nMeas
        repeatMeas = squeeze(rawData.gammaCurveMeasurements(:,1,pp,:));
        modSPDsByPhase(pp+1,:) = ambient + mean(repeatMeas,1);
    end

    % Store these in the object
    obj.processedData.modSPDsByPhase = modSPDsByPhase;
    
end
