function plotModResult(modResult)

% Extract some elements
whichDirection = modResult.meta.whichDirection;
wavelengthsNm = modResult.wavelengthsNm;
positiveModulationSPD = modResult.positiveModulationSPD;
negativeModulationSPD = modResult.negativeModulationSPD;
backgroundSPD = modResult.backgroundSPD;
contrastReceptorsBipolar = modResult.contrastReceptorsBipolar;
whichReceptorsToTarget = modResult.meta.whichReceptorsToTarget;
whichReceptorsToIgnore = modResult.meta.whichReceptorsToIgnore;
settingsLow = modResult.settingsLow;
settingsHigh = modResult.settingsHigh;
settingsBackground = modResult.settingsBackground;
photoreceptorClassNames = modResult.meta.photoreceptorClassNames;
nPrimaries = length(settingsBackground);
nPhotoClasses = length(photoreceptorClassNames);

% Create a figure with an appropriate title
figure('Name',sprintf([whichDirection ': contrast = %2.2f'],contrastReceptorsBipolar(whichReceptorsToTarget(1))));
figuresize(800, 200,'pt');

% Modulation spectra
subplot(1,4,1)
hold on
plot(wavelengthsNm,positiveModulationSPD,'k','LineWidth',2);
plot(wavelengthsNm,negativeModulationSPD,'r','LineWidth',2);
plot(wavelengthsNm,backgroundSPD,'Color',[0.5 0.5 0.5],'LineWidth',2);
title('Modulation spectra');
xlim([300 800]);
xlabel('Wavelength');
ylabel('Power');

% Primaries
subplot(1,4,2)
c = 0:nPrimaries-1;
hold on
plot(c,settingsHigh,'*k');
plot(c,settingsLow,'*r');
plot(c,settingsBackground,'-*','Color',[0.5 0.5 0.5]);
set(gca,'TickLabelInterpreter','none');
title('Primaries');
ylim([0 1]);
xlabel('Primary');
ylabel('Setting');

% Contrasts
subplot(1,4,3)
c = 1:nPhotoClasses;
barVec = zeros(1,nPhotoClasses);
thisBar = barVec;
thisBar(whichReceptorsToTarget) = contrastReceptorsBipolar(whichReceptorsToTarget);
bar(c,thisBar,'FaceColor',[0.5 0.5 0.5],'EdgeColor','none');
hold on
thisBar = barVec;
thisBar(whichReceptorsToIgnore) = contrastReceptorsBipolar(whichReceptorsToIgnore);
bar(c,thisBar,'FaceColor','w','EdgeColor','k');
thisBar = contrastReceptorsBipolar;
thisBar(whichReceptorsToTarget) = nan;
thisBar(whichReceptorsToIgnore) = nan;
bar(c,thisBar,'FaceColor','none','EdgeColor','r');
set(gca,'TickLabelInterpreter','none');
a = gca;
a.XTick=1:nPhotoClasses;
a.XTickLabel = photoreceptorClassNames;
xlim([0.5 nPhotoClasses+0.5]);
title('Contrast');
ylabel('Contrast');


%% Chromaticity
subplot(1,4,4)

% Load the XYZ fundamentals
load('T_xyz1931.mat','T_xyz1931','S_xyz1931');
S = WlsToS(wavelengthsNm);
T_xyz = SplineCmf(S_xyz1931,683*T_xyz1931,S);
xyYLocus = XYZToxyY(T_xyz);

% Calculate the luminance and the chromaticities
bg_photopicLuminanceCdM2_Y = T_xyz(2,:)*backgroundSPD;
bg_chromaticity_xy = (T_xyz(1:2,:)*backgroundSPD/sum(T_xyz*backgroundSPD));
modPos_chromaticity_xy = (T_xyz(1:2,:)*positiveModulationSPD/sum(T_xyz*positiveModulationSPD));
modNeg_chromaticity_xy = (T_xyz(1:2,:)*negativeModulationSPD/sum(T_xyz*negativeModulationSPD));

% Plot the loci for each of the spectra
plot(bg_chromaticity_xy(1), bg_chromaticity_xy(2), 'o', 'MarkerFaceColor', [0.5 0.5 0.5], 'MarkerSize', 10);
hold on
plot(modPos_chromaticity_xy(1), modPos_chromaticity_xy(2), 'o', 'MarkerFaceColor', 'k', 'MarkerSize', 10);
plot(modNeg_chromaticity_xy(1), modNeg_chromaticity_xy(2), 'o', 'MarkerFaceColor', 'r', 'MarkerSize', 10);

% Plot the boundary of the color space
plot(xyYLocus(1,:)',xyYLocus(2,:)','k');

% Add a legend and some labels
hleg = legend({'background','positive','negative'});
xlabel('x chromaticity');
ylabel('y chromaticity');
title(sprintf('Luminance %2.1f cd/m2',bg_photopicLuminanceCdM2_Y))

end