function [spectroRadiometerOBJ,S,nAverage,theMeterTypeID] = openSpectroRadiometerObj(meterType)
% Open a radiometer object for performing calibrations.
%
% This is a modified version of code originally created to calibrate the
% OneLight.

% Use try/catch so that we crash as gracefully as possible if we cannot
% open the radiometer.
try
    switch (meterType)
        case 'PR-650'
            theMeterTypeID = 1;
            S = [380 4 101];
            nAverage = 1;

            % Instantiate a PR650 object
            spectroRadiometerOBJ  = PR650dev(...
                'verbosity',        1, ...       % 1 -> minimum verbosity
                'devicePortString', [] ...       % empty -> automatic port detection)
                );
            spectroRadiometerOBJ.setOptions('syncMode', 'OFF');

        case 'PR-670'
            theMeterTypeID = 5;
            S = [380 2 201];
            nAverage = 1;

            % Instantiate a PR670 object
            spectroRadiometerOBJ  = PR670dev(...
                'verbosity',        1, ...       % 1 -> minimum verbosity
                'devicePortString', [] ...       % empty -> automatic port detection)
                );

            % Set options Options available for PR670:
            spectroRadiometerOBJ.setOptions(...
                'verbosity',        1, ...
                'syncMode',         'OFF', ...      % choose from 'OFF', 'AUTO', [20 400];
                'cyclesToAverage',  1, ...          % choose any integer in range [1 99]
                'sensitivityMode',  'STANDARD', ... % choose between 'STANDARD' and 'EXTENDED'.  'STANDARD': (exposure range: 6 - 6,000 msec, 'EXTENDED': exposure range: 6 - 30,000 msec
                'exposureTime',     'ADAPTIVE', ... % choose between 'ADAPTIVE' (for adaptive exposure), or a value in the range [6 6000] for 'STANDARD' sensitivity mode, or a value in the range [6 30000] for the 'EXTENDED' sensitivity mode
                'apertureSize',     '1 DEG' ...     % choose between '1 DEG', '1/2 DEG', '1/4 DEG', '1/8 DEG'
                );

        case 'CR-250'
            spectroRadiometerOBJ = CR250dev(...
                'verbosity',        1, ...        % 1 -> minimum verbosity
                'devicePortString', [] ...       % empty -> automatic port detection)
                );

            % Set the sync mode to None
            syncMode = 'None';
            manualSyncFrequency = [];

            % Or set it to manual mode with a sync Frequency of 120 Hz;
            %syncMode = 'Manual';
            %manualSyncFrequency = 60.0;

            % Specify extra properties
            spectroRadiometerOBJ.setOptions(...
                    'syncMode',  syncMode, ...                % choose from 'None', 'Manual', 'NTSC', 'PAL', 'CINEMA'
                    'manualSyncFrequency',manualSyncFrequency, ...
                    'speedMode', 'Normal', ...                % choose from 'Slow','Normal','Fast', '2x Fast'
                    'exposureMode', 'Auto' ...                % Choose between 'Auto', and 'Fixed'
            );

        otherwise
            error('Unknown meter type');
    end

catch err
    if (exist('spectroRadiometerOBJ','var') && ~isempty(spectroRadiometerOBJ))
        spectroRadiometerOBJ.shutDown();
    end

    rethrow(err);
end
end