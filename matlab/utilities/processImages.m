function imds = processImages(imds, imageSize, destinationPath, ...
    forceConvert, preProcess, outerProgressBar)
% Preprocess requires that the input sequences are sorted, and made up of
% sequential images, with all images in the datastore from a single sequence

    if nargin == 5
        outerProgressBar = false;
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
    
    reset(imds)
    N = length(imds.Files);
    imageList = string(zeros(1,N));
    
    x = imageSize(1);
    y = imageSize(2);
    
    if ~outerProgressBar
        rez = strcat(string(x),'x',string(y));
        str = char(strcat('Resizing images to ',{' '},rez));
        progressbar(str)
    end
    
 
    
    if preProcess
        frameBlendNum = 2; % how many previous frames to blend
        noiseThreshold =  0.01;
    
        if N > frameBlendNum + 1
            info = imds.Files(1);
            folder = fileparts(info{1});
            currentSequence = split(folder,filesep);
            if ~("tif"==currentSequence{end} || ...
                    "png"==currentSequence{end})
                error('Input directory structure incorrect')
            end
        else
            error('Error: Time denoising requires a minimum of %d images', frameBlendNum +1)
        end
    else
        frameBlendNum = 0;
    end
    
    for r=1:N
        info = imds.Files(r);
        [~, filename] = fileparts(info{1});
        ext = '.png';   % converted images should be png
        fullFile = fullfile(destinationPath,strcat(filename, ext));
        
        if (~exist(fullFile, 'file') || forceConvert)
            if r >  frameBlendNum  && preProcess
                for ii = frameBlendNum:-1:0
                    im = imds.readimage(r - ii);
                    p{frameBlendNum-ii+1} = im2single(im(:,:,1));
                end
                
                % Images are single precison
                % Images are processed as 1 channel until after processing

                % make frame buffer matrix
                buffer = cat(frameBlendNum+1, p{:});
                
                % mask to remove sub-threshold values, in the old frames
                a = ones(size(buffer));
                a(buffer(:,:,(1:frameBlendNum))<noiseThreshold)=0;
                
                % Rebuild frame(s) w/o the past frames brightness:
                % Zero out bright values below threshold in past frames
                % and replace with the current frame pixel values.
                % This is a binary compositing operation
                % which replaces removed "background" with the
                % current "foreground" pixel values. This mitigates strokes
                % and leaders from the past appearing in the current frame.
                bg = buffer .* a;
                fg = repmat(buffer(:,:,end), ...
                    [ones(1,frameBlendNum) frameBlendNum+1]) .* (1-a);
                buffer = bg + fg;
                
                % Combine buffers, preserving current frame max brightness:
                Im16 = max(mean(buffer,frameBlendNum+1), ...
                    buffer(:,:,end));
                
                % combine into RGB image
                Im16 = cat(3,Im16,Im16,Im16);
                
            else
                Im16 = imds.readimage(r);
            end
           resizeWriteImage(Im16, imageSize, destinationPath, filename, ext);
        end
        
        imageList(r) = fullFile;
        
        if outerProgressBar
            progressbar([],r/N);
        else
            progressbar(r/N);
        end
    end

    if outerProgressBar
        progressbar([],1);
    else
        progressbar(1);
    end
    
    imds = imageDatastore(imageList);
    
end