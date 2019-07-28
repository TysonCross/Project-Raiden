% Overlay colors
cmap = [
    000 000 128;...    % leader
    128 128 128;...    % stroke
    128 128 000;...    % channel
    128 128 000;...    % cloud
    128 000 000 ;...   % sky
    000 128 000;...    % ground
    ];

% Normalize between [0 1].
cmap = cmap ./ 255;
