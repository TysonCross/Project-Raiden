function imds = resizeImages(imds, imageSize, destinationPath, outerProgressBar, preProcess)
 % Resize images to [sz(1) sz(2)].

    if nargin == 4
        preProcess = false;
    elseif nargin == 3
        outerProgressBar = false;
        preProcess = false;
    end

    if ~exist(destinationPath,'dir')
        mkdir(destinationPath)
    end

    if preProcess
        destinationPath = strcat(destinationPath,'_processed');
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
        
        if ~exist(fullfile(destinationPath,strcat(filename,ext)), 'file')

            % Convert to 8-bit
%             I = uint8(Im16/256);
            Igpu = gpuArray(uint8(Im16/256));

            % Resize image.
            Igpu = imresize(Igpu,[y x]);
            
            if preProcess
               Igpu = imadjust(Igpu);
               Igpu = medfilt2(Igpu);
            end

            I = gather(Igpu);
%             figure, montage({Im16,I})

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