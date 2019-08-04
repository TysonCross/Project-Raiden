classNames = [
    "lightning" , ...
    "stroke"    , ...
    "cloud"     , ...
    "sky"       , ...
    "ground"
    ];


labelIDs = {... 
    
    % Lightning
    [ 
    255 000 000;...    % leader
    255 255 000;...    % channel
    ]

    [255 255 255;]   	% stroke
    [000 255 255;]    	% cloud
    [000 000 255;]   	% sky
    [000 255 000;]      % ground
    };