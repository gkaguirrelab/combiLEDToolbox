% Object to support setting the LED levels directly of the Prizmatix
% CombiLED 8-channel light engine. This routine presumes that the
% prizModulationFirmware is installed on the device.

classdef CombiLEDcontrol < handle

    properties (Constant)

        nPrimaries = 8;
        baudrate = 57600;
        nGammaParams = 6;
    end

    % Private properties
    properties (GetAccess=private)

    end

    % Calling function can see, but not modify
    properties (SetAccess=private)

        serialObj
        deviceState
        settingsHigh = [1,1,1,1,1,1,1,1]
        settingsLow = [0,0,0,0,0,0,0,0]
        identifierString % String returned by Arduino that uniquely identifies a given CombiLED

    end

    % These may be modified after object creation
    properties (SetAccess=public)

        % Verbosity
        verbose = false;

        % The polynomial fit to the gamma table data for each primary must
        % explain 99% of the root sum squared data.
        gammaFitTol = 0.01;

    end

    methods

        % Constructor
        function obj = CombiLEDcontrol(varargin)

            % input parser
            p = inputParser; p.KeepUnmatched = false;
            p.addParameter('verbose',false,@islogical);
            p.parse(varargin{:})

            % Store the verbosity
            obj.verbose = p.Results.verbose;

            % Open the serial port
            obj.serialOpen;

            % Send the default gammaTable
            gammaTableFileName = fullfile(fileparts(mfilename('fullpath')),'defaultGammaTable.mat');
            load(gammaTableFileName,'gammaTable');
            obj.setGamma(gammaTable);

        end

        % Required methds
        serialOpen(obj)
        serialClose(obj)
        setPrimaries(obj,settings)
        startModulation(obj)
        stopModulation(ob)
        updateFrequency(obj,frequency)
        updateContrast(obj,contrast)
        goDark(ob)
        setFrequency(obj,frequency)
        setContrast(obj,contrast)
        setPhaseOffset(obj,phaseOffset)
        setDuration(obj,modulationDurSecs)
        setSettings(obj,modResult)
        setUnimodal(obj)
        setBimodal(obj)
        setAMIndex(obj,amplitudeIndex)
        setAMFrequency(obj,amplitudeFrequency)
        setAMValues(obj,amplitudeVals)
        setCompoundModulation(obj,compoundHarmonics,compoundAmplitudes,compoundPhases)
        setWaveformIndex(obj,waveformIndex)
        setBlinkDuration(obj,blinkDurSecs)
        setGamma(obj,gammaTable)
        setDirectModeGamma(obj,boolGammaCorrect)
        setLEDUpdateOrder(obj,ledUpdateOrder)
        quantErrorFlagByPrimary = checkForQuantizationError(obj,contrast,bitDepth)
        clockAdjustFactor = calcClockAdjustFactor(obj)

    end
end