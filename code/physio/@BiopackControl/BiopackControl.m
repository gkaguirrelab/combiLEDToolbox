% Object to stream EEG data from a biopack unit via a LabJack connection

classdef BiopackControl < handle

    properties (Constant)
    end

    % Private properties
    properties (GetAccess=private)
        labjackOBJ
    end

    % Calling function can see, but not modify
    properties (SetAccess=private)
        recordingFreqHz = 2000;
        channelIdx = 1;
        dataOutDir
        trialIdx = 1;
        trialData = [];
    end

    % These may be modified after object creation
    properties (SetAccess=public)

        % A prefix to be added to the data files
        filePrefix

        % How long to record
        trialDurationSecs

        % Verbosity
        verbose
        
    end

    methods

        % Constructor
        function obj = BiopackControl(subjectID,modDirection,experimentName,varargin)

            % input parser
            p = inputParser; p.KeepUnmatched = false;
            p.addParameter('filePrefix','',@ischar);
            p.addParameter('trialDurationSecs',4,@isnumeric);
            p.addParameter('dropBoxBaseDir',getpref('combiLEDToolbox','dropboxBaseDir'),@ischar);
            p.addParameter('projectName','combiLED',@ischar);
            p.addParameter('approachName','ssVEP',@ischar);
            p.addParameter('verbose',true,@islogical);
            p.parse(varargin{:})

            % Place various inputs and options into object properties
            obj.filePrefix = p.Results.filePrefix;
            obj.trialDurationSecs = p.Results.trialDurationSecs;            
            obj.verbose = p.Results.verbose;

            % Define the dir in which to save EEG data
            obj.dataOutDir = fullfile(...
                p.Results.dropBoxBaseDir,...
                p.Results.projectName,...
                p.Results.approachName,...
                subjectID,modDirection,experimentName,'rawEEGData');

            % Create the directory if it isn't there
            if ~isfolder(obj.dataOutDir)
                mkdir(obj.dataOutDir)
            end

            % Open a labjack connection
            obj.labjackOBJ = LabJackU6('verbosity', double(p.Results.verbose));

            % Configure analog input sampling
            obj.labjackOBJ.configureAnalogDataStream(obj.channelIdx,obj.recordingFreqHz);

        end

        % Required methds
        collectTrial(obj)
    end
end