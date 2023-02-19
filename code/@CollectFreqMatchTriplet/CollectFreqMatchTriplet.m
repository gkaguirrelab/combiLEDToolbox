% Object to support conducting a two-interval psychophysical test in which
% a subject is presented with sequential modulations and selects one.
% Based upon their response, a parameter of the modulation is adjusted.

classdef CollectFreqMatchTriplet < handle

    properties (Constant)
    end

    % Private properties
    properties (GetAccess=private)
    end

    % Calling function can see, but not modify
    properties (SetAccess=private)
        CombiLEDObj
        questData
        simulatePsiParams
        simulateResponse
        simulateStimuli
        psiParamsDomainList
        randomizePhase = true;
        TestContrast
        TestFrequency
        ReferenceContrast
        ReferenceFrequencySet
        stimulusDurationSecs = 1;
        responseDurSecs = 3;
        interStimulusIntervalSecs = 0.75;
    end

    % These may be modified after object creation
    properties (SetAccess=public)
        % Verbosity
        verbose = true;
    end

    methods

        % Constructor
        function obj = CollectFreqMatchTriplet(CombiLEDObj,TestContrast,TestFrequency,ReferenceContrast,varargin)

            % input parser
            p = inputParser; p.KeepUnmatched = false;
            p.addParameter('randomizePhase',true,@islogical);            
            p.addParameter('simulateResponse',true,@islogical);            
            p.addParameter('simulateStimuli',true,@islogical);            
            p.addParameter('ReferenceFrequencySet',logspace(log10(2),log10(24),15),@isnumeric);
            p.addParameter('simulatePsiParams',[0.15, 0.05, -0.05],@isnumeric);
            p.addParameter('psiParamsDomainList',{0:0.01:0.75, 0:0.01:0.75, -0.15:0.025:0.15},@isnumeric);
            p.addParameter('verbose',true,@islogical);
            p.parse(varargin{:})

            % Place various inputs and options into object properties            
            obj.CombiLEDObj = CombiLEDObj;
            obj.TestContrast = TestContrast;
            obj.TestFrequency = TestFrequency;
            obj.ReferenceContrast = ReferenceContrast;
            obj.randomizePhase = p.Results.randomizePhase;
            obj.simulateResponse = p.Results.simulateResponse;
            obj.simulateStimuli = p.Results.simulateStimuli;
            obj.ReferenceFrequencySet = p.Results.ReferenceFrequencySet;
            obj.simulatePsiParams = p.Results.simulatePsiParams;
            obj.psiParamsDomainList = p.Results.psiParamsDomainList;
            obj.verbose = p.Results.verbose;

            % Initialize Quest+
            obj.qpInitialize;

            % Ensure that the CombiLED is configured to present our stimuli
            % properly (if we are not simulating the stimuli)
            if ~obj.simulateStimuli
                obj.CombiLEDObj.setDuration(obj.stimulusDurationSecs);
                obj.CombiLEDObj.setWaveformIndex(1); % sinusoidal flicker
                %            obj.CombiLEDObj.setAMIndex(2); % half-cosine ramp
                %            obj.CombiLEDObj.setAMFrequency(0.5); % half-cosine ramp
                %            obj.CombiLEDObj.setAMValues([0.1,0]); % half-cosine duration
            end

        end

        % Required methds
        qpInitialize(obj);
        presentTrial(obj);
        [intervalChoice, responseTimeSecs] = getResponse(obj);
        [intervalChoice, responseTimeSecs] = getSimulatedResponse(obj,FrequencyParams,ref1Interval);
        waitUntil(obj,stopTimeMicroSeconds)
        [psiParamsQuest, psiParamsFit] = reportParams(obj)
        plotOutcome(obj)
        values = forwardTransformVals(obj,refValues,testValue)
        values = inverseTransVals(obj,refValues,testValue)
    end
end