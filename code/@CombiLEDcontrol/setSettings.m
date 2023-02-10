function setSettings(obj,settings)

% Check that the settings match the number of primaries
if size(settings,1) ~= obj.nPrimaries
    warning('First dimension of settings must match number of primaries')
    return
end

if size(settings,1) ~= obj.nDiscreteLevels
    warning('Second dimension of settings must match number of discrete levels')
    return
end

% Check that the settings is an integer vector
if any(floor(settings(:))~=settings(:))
    warning('The settings must be integers')
    return
end

% Sanity check the settings range
if any(settings(:)>4095) || any(settings(:)<0)
    warning('The settings must be 0-4095')
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


% Loop over the primaries and send the settings
for ii = 1:obj.nPrimaries
    str = sprintf('L%d',ii-1);
    writeline(obj.serialObj,str);
    readline(obj.serialObj);
    for ll= 1:obj.nDiscreteLevels
        writeline(obj.serialObj,num2str(settings(ii,ll)));
        readline(obj.serialObj);
    end
end

if obj.verbose
    fprintf('Settings matrix sent\n');
end

end