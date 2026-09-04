% measureUncontrolledSourceSpectrum
%
% A simple script to record and save a single spectrum from an uncontrolled
% device.
%

% Ask how many averages are to obtained
nAverage = GetWithDefault('How many measurement averages to obtain',5);

% Offer a recommendation regarding connecting devices
fprintf('Connect and start the PR670. Press return when ready.\n')
pause

% Open the spectroradiometer and create a radiometer object
OpenSpectroradiometer('measurementOption',false);
radiometerOBJ = openSpectroRadiometerObj('PR-670');

% Alert the user that we are about to measure
fprintf('\n\nPress return to start the measurement.\n')
pause

% Measure
for ii = 1:nAverage
    fprintf('Measure %d of %d\n',ii,nAverage);
    radiometerOBJ.measure();
    measurement(ii,:) = radiometerOBJ.measurement.energy;
end
spectralAxis = radiometerOBJ.measurement.spectralAxis;
if size(spectralAxis,1) > 1
    S = WlsToS(spectralAxis);
else
    S = WlsToS(spectralAxis');
end
fprintf('Done measurements\n');

% Shutdown spectroradiometer.
CloseSpectroradiometer;
fprintf('Press and hold the power off button on the PR670.\n')

% Create a plot
plot(spectralAxis,mean(measurement,1),'-k');
xlabel('wavelength [nm]')
ylabel('W/m2/sr/wavelength band')

% Save the data
filter = '*.mat'; 
dialogTitle = 'Destination to Save Spectral Measurement';
[file, path] = uiputfile(filter, dialogTitle);
if isequal(file, 0) || isequal(path, 0)
    disp('User canceled the save operation.');
else
    fullSavePath = fullfile(path, file);
    save(fullSavePath, 'measurement','S');
end
