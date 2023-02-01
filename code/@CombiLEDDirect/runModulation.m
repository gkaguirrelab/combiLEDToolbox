function runModulation(obj)

% Check that we have an open connection
if isempty(obj.serialObj)
    warning('Serial connection not yet established');
end

% Place the CombiLED in Run Mode
writeline(obj.serialObj,'RM');

% Go
writeline(obj.serialObj,'GO');

% Say
if obj.verbose
    fprintf('Running modulation\n');
end

end