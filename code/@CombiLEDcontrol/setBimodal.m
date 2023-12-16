function setBimodal(obj)
% Tell the combiLED to use a bi-modal modulation against a background
% defined by the mid point of the high and low settings


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
writeline(obj.serialObj,'BM');
msg = readline(obj.serialObj);

% Say
if obj.verbose
    fprintf([char(msg) '\n']);
end



end