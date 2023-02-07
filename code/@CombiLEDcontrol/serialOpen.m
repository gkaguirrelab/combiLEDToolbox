function serialOpen(obj)

% Get the list of available serial connections
portList = serialportlist("available");

% Look for the two possible string patterns
arduinoPortIdx = find((contains(serialportlist("available"),'tty.usbserial')));
arduinoPort = portList(arduinoPortIdx);
if isempty(arduinoPort)
    arduinoPortIdx = find((contains(serialportlist("available"),'tty.usbmodem2101')));
    arduinoPort = portList(arduinoPortIdx);
end

if isempty(arduinoPort)
    error('Unable to find a connected and available arduino board');
end

obj.serialObj = serialport(arduinoPort,obj.baudrate);

if obj.verbose
    fprintf('Serial port open\n');
end


end