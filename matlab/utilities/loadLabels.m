labelIDs = [... 
    255 000 000;...    % leader
    255 255 255;...    % stroke
    000 000 255;...    % sky
    000 255 255;...    % cloud
    000 255 000;...    % ground
    ];

labelIDs_scalar = [... 
    1 ...    % leader
    2 ...    % stroke
    3 ...    % sky
    4 ...    % cloud
    5 ...    % ground
    ];

labelNames = [
    "lightning" , ...
    "stroke"    , ...
    "sky"       , ...
    "cloud"     , ...
    "ground"
    ];

% old ordering:
% labelID_scalar = [... 
%     1;...    % leader
%     2;...    % stroke
%     4;...    % cloud
%     3;...    % sky
%     5;...    % ground
%     ];



