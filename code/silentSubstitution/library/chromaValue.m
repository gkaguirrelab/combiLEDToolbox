function xy = chromaValue(spd,wavelengthsNm)

% Load the XYZ fundamentals
load('T_xyz1931.mat','T_xyz1931','S_xyz1931');
S = WlsToS(wavelengthsNm);
T_xyz = SplineCmf(S_xyz1931,683*T_xyz1931,S);

% Calculate the chromaticities
for ii = 1:size(spd,2)
    xy(1:2,ii) = (T_xyz(1:2,:)*spd(:,ii)/sum(T_xyz*spd(:,ii)));
end

end