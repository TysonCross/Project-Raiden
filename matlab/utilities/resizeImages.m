function imds = resizeImages(imds, imageSize, destinationPath, ...
    forceConvert, outerProgressBar)
 % Resize images to [sz(1) sz(2)].

    if nargin == 4
        outerProgressBar = false;
    elseif nargin == 3
        forceConvert = false;
        outerProgressBar = false;
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
        [~, filename] = fileparts(info.Filename);
        ext = '.png';   % converted images should be png
        fullFile = fullfile(destinationPath,strcat(filename, ext));
        
        if (~exist(fullFile, 'file') || forceConvert)
            resizeWriteImage(Im16, imageSize, destinationPath, filename, ext);
        end
        
        imageList(r) = fullFile;
        
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