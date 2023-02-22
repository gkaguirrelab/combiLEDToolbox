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
        startTime
        simulatePsiParams
        simulateResponse
        simulateStimuli
        giveFeedback
        psiParamsDomainList
        randomizePhase = true;
        TestContrast
        TestContrastAdjusted
        TestFrequency
        ReferenceContrast
        ReferenceContrastAdjustedByFreq
        ReferenceFrequencySet
        stimulusDurationSecs = 1;
        responseDurSecs = 3;
        interFlickerIntervalSecs = 0.2;
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
            p.addParameter('simulateResponse',false,@islogical);
            p.addParameter('simulateStimuli',false,@islogical);
            p.addParameter('giveFeedback',true,@islogical);
            p.addParameter('ReferenceFrequencySet',[3, 4, 6, 8, 10, 12, 14, 16, 20, 24, 28, 32, 40],@isnumeric);
            p.addParameter('simulatePsiParams',[0.15, 0.05, -0.15],@isnumeric);
            p.addParameter('psiParamsDomainList',{linspace(0,0.5,51), ...
                linspace(0,0.5,51),...
                linspace(-0.25,0.25,51)},@isnumeric);
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
            obj.giveFeedback = p.Results.giveFeedback;
            obj.ReferenceFrequencySet = p.Results.ReferenceFrequencySet;
            obj.simulatePsiParams = p.Results.simulatePsiParams;
            obj.psiParamsDomainList = p.Results.psiParamsDomainList;
            obj.verbose = p.Results.verbose;

            % Detect incompatible simulate settings
            if obj.simulateStimuli && ~obj.simulateResponse
                fprintf('Forcing simulateResponse to true, as one cannot respond to a simulated stimulus\n')
                obj.simulateResponse = true;
            end

            % Initialize Quest+
            obj.qpInitialize;

            % Store the start time
            obj.startTime = datetime();

            % Ensure that the CombiLED is configured to present our stimuli
            % properly (if we are not simulating the stimuli)
            if ~obj.simulateStimuli
                obj.CombiLEDObj.setDuration(obj.stimulusDurationSecs);
                obj.CombiLEDObj.setWaveformIndex(1); % sinusoidal flicker
                obj.CombiLEDObj.setAMIndex(2); % half-cosine ramp
                obj.CombiLEDObj.setAMFrequency(0.5/obj.stimulusDurationSecs); % half-cosine ramp
                obj.CombiLEDObj.setAMValues([obj.stimulusDurationSecs/20,0]); % half-cosine duration
            end

            % There is a roll-off (attenuation) of the amplitude of
            % modulations with frequency. We can adjust for this property,
            % and detect those cases which are outside of our ability to
            % correct
            obj.ReferenceContrastAdjustedByFreq = obj.ReferenceContrast ./ ...
                contrastAttentionByFreq(obj.ReferenceFrequencySet);

            % Check that the adjusted contrast does not exceed unity
            mustBeInRange(obj.ReferenceContrastAdjustedByFreq,0,1);

            % Now adjust the test contrast
            obj.TestContrastAdjusted = obj.TestContrast / ...
                contrastAttentionByFreq(obj.TestFrequency);

            % Check that the adjusted contrast does not exceed unity
            mustBeInRange(obj.TestContrastAdjusted,0,1);

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