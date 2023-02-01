function serialClose(obj)

    clear obj.serialObj
    obj.serialObj = [];

    if obj.verbose
        fprintf('Serial port closed\n');
    end

end