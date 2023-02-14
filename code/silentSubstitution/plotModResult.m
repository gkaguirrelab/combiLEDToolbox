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

% Modulation spectra
subplot(1,3,1)
hold on
plot(wavelengthsNm,positiveModulationSPD,'k','LineWidth',2);
plot(wavelengthsNm,negativeModulationSPD,'r','LineWidth',2);
plot(wavelengthsNm,backgroundSPD,'Color',[0.5 0.5 0.5],'LineWidth',2);
title(sprintf('Modulation spectra [%2.2f]',contrastReceptorsBipolar(whichReceptorsToTarget(1))));
xlim([300 800]);
xlabel('Wavelength');
ylabel('Power');
legend({'Positive', 'Negative', 'Background'},'Location','NorthEast');

% Primaries
subplot(1,3,2)
c = 0:nPrimaries-1;
hold on
plot(c,settingsHigh,'*k');
plot(c,settingsLow,'*r');
plot(c,settingsBackground,'-*','Color',[0.5 0.5 0.5]);
set(gca,'TickLabelInterpreter','none');
title('Primary settings');
ylim([0 1]);
xlabel('Primary');
ylabel('Setting');

% Contrasts
subplot(1,3,3)
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

end