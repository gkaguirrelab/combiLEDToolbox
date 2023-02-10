% Object to support setting the LED levels directly of the Prizmatix
% CombiLED 8-channel light engine. This routine presumes that the
% prizModulationFirmware is installed on the device.

classdef CombiLEDcontrol < handle

    properties (Constant)

        nPrimaries = 8;
        nDiscreteLevels = 45;
        baudrate = 57600;
        refreshRate = 10; % Hz
    end

    % Private properties
    properties (GetAccess=private)

    end

    % Calling function can see, but not modify
    properties (SetAccess=private)

        serialObj
        deviceState

    end

    % These may be modified after object creation
    properties (SetAccess=public)

        % Verbosity
        verbose

    end

    methods

        % Constructor
        function obj = CombiLEDcontrol(varargin)

            % input parser
            p = inputParser; p.KeepUnmatched = false;
            p.addParameter('verbose',true,@islogical);
            p.parse(varargin{:})

            % Do some stuff here
            obj.verbose = p.Results.verbose;

        end

        % Required methds
        serialOpen(obj)
        serialClose(obj)
        setPrimaries(obj,settings)
        runModulation(obj)
        stopModulation(ob)
        setFrequency(obj,frequency)
        setSettings(obj,settings)
        setBackground(obj,background)
        setAMIndex(obj,amplitudeIndex)
        setAMValues(obj,amplitudeVals)
        setCompoundModulation(obj,compoundHarmonics,compoundAmplitudes,compoundPhases)

    end
end