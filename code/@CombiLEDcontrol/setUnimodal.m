function setUnimodal(obj)
% Tell the combiLED to use a uni-modal modulation against a background
% defined by the vector of low setting values


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

% Set the modulation state
writeline(obj.serialObj,'UM');
msg = readline(obj.serialObj);

% Say
if obj.verbose
    fprintf([char(msg) '\n']);
end



end