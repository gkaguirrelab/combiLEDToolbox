function response = getResponse(obj)

% Set the response interval
responseDurMicroSecs = obj.responseDurSecs * 1e9;

% Determine the identities of the responses
KbName('UnifyKeynames');
numpad1 = KbName('1');
numpad2 = KbName('2');
KbResponse = [];

% Silence echoing key presses to Matlab console
ListenChar(2);

% Enter a while loop
waitingForKey = true;
intervalStart = tic();
while waitingForKey

    % Check keyboard:
    [isdown, ~, keycode]=KbCheck(-1);
    if isdown
        KbResponse = find(keycode);
        if KbResponse==numpad1 || KbResponse==numpad2
            waitingForKey = false;
        end
    end

    % Check if we have run out of time
    if (tic()-intervalStart) > responseDurMicroSecs
        waitingForKey = false;
    end

end

% Interpret the response
switch KbResponse
    case numpad1
        response = 1;
    case numpad2
        response = 2;
    otherwise
        response = [];
end

% Restore echoing key presses to Matlab console
ListenChar(0);


end