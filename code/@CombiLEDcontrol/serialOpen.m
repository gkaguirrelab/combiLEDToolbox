function serialOpen(obj)

% Get the list of available serial connections
portList = serialportlist("available");

% Look for the possible string patterns. This will vary by platform
if ispc
    arduinoPortIdx = find((contains(serialportlist("available"),'COM3')));
    arduinoPort = portList(arduinoPortIdx);
end
if ismac
    arduinoPortIdx = find((contains(serialportlist("available"),'tty.usbserial')));
    arduinoPort = portList(arduinoPortIdx);
    if isempty(arduinoPort)
        arduinoPortIdx = find((contains(serialportlist("available"),'tty.usbmodem')));
        arduinoPort = portList(arduinoPortIdx);
    end
end

% We can't find a port
if isempty(arduinoPort)
    error('Unable to find a connected and available arduino board');
end

% Take the first port in the list
arduinoPort = arduinoPort(1);

% Open the serial port
obj.serialObj = serialport(arduinoPort,obj.baudrate);

% Use CR and LF as a terminator
configureTerminator(obj.serialObj,"CR/LF");

% Set the initial device state
obj.deviceState = 'RUN';

% Extract and set the identifier string
splitPort = strsplit(arduinoPort(1), '-');
obj.identifierString = splitPort{2};

% Need to read and thus clear the first line of command output
readline(obj.serialObj);

% Announce it
if obj.verbose
    fprintf('Serial port open\n');
end


end