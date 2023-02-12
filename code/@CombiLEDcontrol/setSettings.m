function setSettings(obj,settings)

% Check that the settings match the number of primaries
if size(settings,1) ~= obj.nPrimaries
    warning('First dimension of settings must match number of primaries')
    return
end

% And that we have levels equal to the number ofo discrete levels
if size(settings,2) ~= obj.nDiscreteLevels
    warning('Second dimension of settings must match number of discrete levels')
    return
end

% Sanity check the settings range
mustBeInRange(settings,0,1);

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

% Enter the settings send state
writeline(obj.serialObj,'ST');
readline(obj.serialObj);

% Loop over the primaries and send the settings
for ii = 1:obj.nPrimaries
    for jj= 1:obj.nDiscreteLevels
        % Each setting is sent as an integer, in the range of 0 to 1e4.
        % This is a specification of the fractional settings with a
        % precision to the fourth decimal place
        valToSend = round(settings(ii,jj) * 1e4);
        writeline(obj.serialObj,num2str(valToSend));
        readline(obj.serialObj);
    end
end

if obj.verbose
    fprintf('Settings matrix sent\n');
end

end