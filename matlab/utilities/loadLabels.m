% Label enum class required
% setupColors uses labelIds to display the label colors.

labelIDs = [... 
    255 000 000;...    % leader
    255 255 255;...    % stroke
    000 000 255;...    % sky
    000 255 255;...    % cloud
    000 255 000;...    % ground
    255 255 000;...    % other
    ];

labelIDs_scalar = [... 
    double(Label.leader) ...    % leader (1)
    double(Label.stroke) ...    % stroke (2)
    double(Label.sky)    ...    % sky    (3)
    double(Label.cloud)  ...    % cloud  (4)
    double(Label.ground) ...    % ground (5)
    double(Label.other)  ...    % other  (6)
    ];

labelNames = [
    "leader" , ...
    "stroke"    , ...
    "sky"       , ...
    "cloud"     , ...
    "ground"    , ...
    "other"
    ];
