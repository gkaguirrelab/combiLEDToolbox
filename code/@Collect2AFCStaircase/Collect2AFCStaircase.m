% Object to support conducting a two-interval psychophysical test in which
% a subject is presented with sequential modulations and selects one.
% Based upon their response, a parameter of the modulation is adjusted.

classdef Collect2AFCStaircase < handle

    properties (Constant)
    end

    % Private properties
    properties (GetAccess=private)
    end

    % Calling function can see, but not modify
    properties (SetAccess=private)
        CombiLEDObj;
        startHigh;
        nTrials = 40;
        nUp = 1;
        nDown = 1;
        ReferenceFrequency
        ReferenceContrast
        TestContrast
        TestFrequencySet
        trialHistory
        trialIdx = 1;
        currentTestFreqIdx = 1
        responseDurSecs = 3;
        randomizePhase = true;
        stimulusDurationSecs = 3;
        interStimulusIntervalSecs = 0.5;
    end

    % These may be modified after object creation
    properties (SetAccess=public)
        % Verbosity
        verbose = false;
    end

    methods

        % Constructor
        function obj = Collect2AFCStaircase(CombiLEDObj,ReferenceContrast,ReferenceFrequency,TestContrast,varargin)

            % input parser
            p = inputParser; p.KeepUnmatched = false;
            p.addParameter('startHigh',false,@islogical);
            p.addParameter('randomizePhase',true,@islogical);
            p.addParameter('TestFrequencySet',logspace(log10(2),log10(48),15),@islogical);
            p.addParameter('verbose',true,@islogical);
            p.parse(varargin{:})

            % Place various inputs and options into object properties            
            obj.CombiLEDObj = CombiLEDObj;
            obj.ReferenceContrast = ReferenceContrast;
            obj.ReferenceFrequency = ReferenceFrequency;
            obj.TestContrast = TestContrast;
            obj.startHigh = p.Results.startHigh;
            obj.randomizePhase = p.Results.randomizePhase;
            obj.TestFrequencySet = p.Results.TestFrequencySet;
            obj.verbose = p.Results.verbose;

            % Set the first trial stimulus level
            if obj.startHigh
                obj.currentTestFreqIdx = length(obj.TestFrequencySet);
            else
                obj.currentTestFreqIdx = 1;
            end

        end

        % Required methds
        presentTrial(obj);
        response = getResponse(obj);
        waitUntil(obj,stopTimeMicroSeconds)
        plotPsycFunc(obj)
    end
end