% Overlay colors
cmap = labelIDs;

% Normalize between [0 1], to one s.f.
cmap = round(cmap ./ 255, 1);
