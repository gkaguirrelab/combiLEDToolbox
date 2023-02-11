function setGamma(obj,gammaTable)

% Check that the gamma table matches the number of primaries
if size(gammaTable,2) ~= obj.nPrimaries
    warning('First dimension of settings must match number of primaries')
    return
end

% Check that we have an open connection
if isempty(obj.serialObj)
    warning('Serial connection not yet established');
    return
end

% Place the CombiLED in Config Mode
switch obj.deviceState
    case 'CONFIG'
    case {'RUN','DIRECT'}
        writeline(obj.serialObj,'CM');
        readline(obj.serialObj);
        obj.deviceState = 'CONFIG';
end

% Loop through the gamma table and calculate a 5th-degree polynomial fit
x = linspace(0,1,size(gammaTable,1)+1);
for ii=1:obj.nPrimaries
    y = [0; gammaTable(:,ii)];
    gammaParams(ii,:) = polyfit(x,y,obj.nGammaParams-1);
    % Check the quality of the fit
    fitErr = norm(y-fitY');
    if fitErr>obj.gammaFitTol
        warning('LED%d (index 0) has gamma fit error of %2.2f (thresh %2.2f)',ii-1,fitErr,obj.gammaFitTol);
    end
end

% Enter the settings send state
writeline(obj.serialObj,'GP');
readline(obj.serialObj);

% Loop over the primaries and send the settings
for ii = 1:obj.nPrimaries
    for jj= 1:obj.nGammaParams
        writeline(obj.serialObj,num2str(gammaParams(ii,jj)));
        readline(obj.serialObj);
    end
end

if obj.verbose
    fprintf('Gamma params sent\n');
end

end