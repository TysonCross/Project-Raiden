function imds = resizeImages(imds, imageSize, destinationPath, ...
    forceConvert, outerProgressBar, preProcess)
 % Resize images to [sz(1) sz(2)].

    if nargin == 5
        preProcess = false;
    elseif nargin == 4
        outerProgressBar = false;
        preProcess = false;
    elseif nargin == 3
        forceConvert = false;
        outerProgressBar = false;
        preProcess = false;
    end

    if ~exist(destinationPath,'dir')
        mkdir(destinationPath)
    end
    
    y = imageSize(1);
    x = imageSize(2);
    
    reset(imds)
    N = length(imds.Files);
    r = 1;
    imageList = string(zeros(1,N));
    
    if ~outerProgressBar
        rez = strcat(string(x),'x',string(y));
        str = char(strcat('Resizing images to ',{' '},rez));
        progressbar(str)
    end

    while hasdata(imds)
        [Im16,info] = read(imds);
        [~, filename, ext] = fileparts(info.Filename);
        
        if (~exist(fullfile(destinationPath,strcat(filename,ext)), 'file') ...
                || forceConvert)

            % Reduce Noise, improve contrast
            if preProcess
                Im16 = improve_contrast(Im16);
                Im16 = noise_removal(Im16, 2);  
            end
            
            % convert to 8-bit
            I = uint8(Im16/255);
            
            % Resize image.
            I = imresize(I,[y x]);

            % Write to disk.
            imwrite(I,fullfile(destinationPath,strcat(filename,ext)));
        end
        
        imageList(r) = fullfile(destinationPath,strcat(filename,ext));
        
        if outerProgressBar
            progressbar([],r/N);
        else
            progressbar(r/N);
        end
        r = r + 1;
    end

    if outerProgressBar
        progressbar([],1);
    else
        progressbar(1);
    end
    imds = imageDatastore(imageList);
end