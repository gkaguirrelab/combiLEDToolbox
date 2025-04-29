function obj = processRawData(obj)
    % reset processData property
    obj.processedData = [];
    
    % if obj.cal.describe.nMeas > 1
    % 
    %     % Fitting a linear model to the raw data
    %     fprintf('Computing linear model.\n');
    %     obj.fitLinearModel();
    % 
    %     % Fitting a curve through the raw data
    %     fprintf('Fitting raw gamma data.\n');
    %     obj.fitRawGamma(2^12);
    % 
    % end
    % 
    % % Process the ambient data
    % obj.addAmbientData();
end
