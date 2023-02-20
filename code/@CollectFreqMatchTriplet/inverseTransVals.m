function values = inverseTransVals(obj,refValues,testValue)

% The raw reference stimulus values (in frequency) undergo a transformation
% to be in log units, and in some cases relative to the test frequency
if isempty(testValue)
    values = 10.^refValues;
else
    values = 10.^(refValues + log10(testValue));
end

end