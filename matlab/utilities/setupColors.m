%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        SETUPCOLORS.M
%
% Export the labels and labelIDs, then normalise the colormap
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Overlay colors
loadLabels;
cmap = labelIDs;

% Normalize between [0 1], to one s.f.
cmap = round(cmap ./ 255, 1);
