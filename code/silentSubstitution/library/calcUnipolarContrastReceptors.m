
function contrastReceptors = calcUnipolarContrastReceptors(modulationPrimary,backgroundPrimary,T_receptors,B_primary,ambientSpd)

% Obtain the isomerization rate for the receptors by the background
backgroundReceptors = T_receptors*(B_primary*backgroundPrimary + ambientSpd);

% Calculate the positive receptor contrast and the differences
% between the targeted receptor sets. This is the bipolar contrast
modulationReceptors = T_receptors*B_primary*(modulationPrimary - backgroundPrimary);
contrastReceptors = modulationReceptors ./ backgroundReceptors;

% If c is the bipolar contrast, a we use the negative arm as the background, the unipolar contrast is
% given as 2*c / (1-c);
contrastReceptors = 2.*contrastReceptors ./ (1-contrastReceptors);

end