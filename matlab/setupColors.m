% Overlay colors
cmap = [
    255 000 000;...    % leader
    255 255 255;...    % stroke
    255 255 000;...    % channel
    000 255 255;...    % cloud
    000 000 255;...    % sky
    000 255 000;...    % ground
    ];

% Normalize between [0 1].
cmap = cmap ./ 255;
