% Object to control the collection of ssVEP and pupillometry data for a
% particular amplitude modulated flicker

classdef FlickerPhysio < handle

    properties (Constant)
    end

    % Private properties
    properties (GetAccess=private)
    end

    % Calling function can see, but not modify
    properties (SetAccess=private)
        pupilObj
        vepObj
        dataOutDir
        pupilVidStartDelaySec
        simulateStimuli

        % Some stimulus properties
        stimFreqHz
        stimContrastSet
        stimContrastSetAdjusted
        stimContrastOrder
        amFreqHz
        halfCosineRampDurSecs
        trialDurationSecs
        trialData
        preTrialJitterRangeSecs
        cycleDurationSecs
    end

    % These may be modified after object creation
    properties (SetAccess=public)

        % The display object. This is modifiable so that we can re-load
        % a CollectFreqMatchTriplet, update this handle, and then continue
        % to collect data
        CombiLEDObj

        % A prefix to be added to the data files
        filePrefix

        % Verbosity
        verbose;

    end

    methods

        % Constructor
        function obj = FlickerPhysio(CombiLEDObj,subjectID,modDirection,experimentName,varargin)

            % input parser
            p = inputParser; p.KeepUnmatched = false;
            p.addParameter('blockIdx',1,@isnumeric);
            p.addParameter('pupilVidStartDelaySec',2.5,@isnumeric);
            p.addParameter('stimFreqHz',20,@isnumeric);
            p.addParameter('stimContrastSet',[0,0.05,0.1,0.2,0.4,0.8],@isnumeric);
            p.addParameter('stimContrastOrder',[1,1,2,3,4,5,6,6,4,3,2,1,5,5,3,1,6,2,4,4,1,3,6,5,2,2,5,1,4,6,3,3,5,4,2,6,1],@isnumeric);
            p.addParameter('amFreqHz',0.25,@isnumeric);
            p.addParameter('halfCosineRampDurSecs',0.1,@isnumeric);
            p.addParameter('simulateStimuli',false,@islogical);
            p.addParameter('dropBoxBaseDir',getpref('combiLEDToolbox','dropboxBaseDir'),@ischar);
            p.addParameter('projectName','combiLED',@ischar);
            p.addParameter('approachName','flickerPhysio',@ischar);
            p.addParameter('verbose',true,@islogical);
            p.parse(varargin{:})

            % Place various inputs and options into object properties
            obj.CombiLEDObj = CombiLEDObj;
            obj.pupilVidStartDelaySec = p.Results.pupilVidStartDelaySec;
            obj.stimFreqHz = p.Results.stimFreqHz;
            obj.stimContrastSet = p.Results.stimContrastSet;
            obj.stimContrastOrder = p.Results.stimContrastOrder;            
            obj.amFreqHz = p.Results.amFreqHz;
            obj.halfCosineRampDurSecs = p.Results.halfCosineRampDurSecs;
            obj.simulateStimuli = p.Results.simulateStimuli;
            obj.verbose = p.Results.verbose;

            % Figure out the cycleDurationSecs and the number of subtrials
            obj.cycleDurationSecs = 1/obj.amFreqHz;

            % Define the dir in which to save the trial
            obj.dataOutDir = fullfile(...
                p.Results.dropBoxBaseDir,...
                p.Results.projectName,...
                p.Results.approachName,...
                subjectID,modDirection,experimentName);

            % Create the directory if it isn't there
            if ~isfolder(obj.dataOutDir)
                mkdir(obj.dataOutDir)
            end

            % There is a roll-off (attenuation) of the amplitude of
            % modulations with frequency. We can adjust for this property,
            % and detect those cases which are outside of our ability to
            % correct
            obj.stimContrastSetAdjusted = obj.stimContrastSet ./ ...
                contrastAttentionByFreq(obj.stimFreqHz);

            % Check that the adjusted contrast does not exceed unity
            mustBeInRange(obj.stimContrastSetAdjusted,0,1);

            % Create a file prefix for the raw data from the stimulus
            % properties
            filePrefix = sprintf('freq_%2.1f_block_%02d_',obj.stimFreqHz,p.Results.blockIdx);

            % Calculate the length of pupil recording needed. We add a
            % second at the end to account for each cycle being slightly
            % longer than the specified cycle duration
            pupilRecordingTime = ...
                length(obj.stimContrastOrder)*obj.cycleDurationSecs + ...
                obj.pupilVidStartDelaySec + 1;            

            % Initialize the pupil recording object.
            obj.pupilObj = PupilLabsControl(subjectID,modDirection,experimentName,...
                'filePrefix',filePrefix,...
                'trialDurationSecs',pupilRecordingTime,...
                'approachName',p.Results.approachName,...
                'backgroundRecording',true);

            % Initialize the ssVEP recording object
            obj.vepObj = BiopackControl(subjectID,modDirection,experimentName,...
                'filePrefix',filePrefix,...
                'trialDurationSecs',obj.cycleDurationSecs,...
                'approachName',p.Results.approachName);

        end

        % Required methods
        collectTrial(obj)
        waitUntil(obj,stopTimeMicroSeconds)
    end
end