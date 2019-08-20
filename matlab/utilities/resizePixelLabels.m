function pxds = resizePixelLabels(pxds, imageSize, destinationPath, forceConvert, outerProgressBar)
% Resize pixel label data to [sz(1) sz(2)].

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
    loadLabels;
    
    reset(pxds)
    N = length(pxds.Files);
    r = 1;
    imageList = strings(1,N);
    
    if ~outerProgressBar
        rez = strcat(string(x),'x',string(y));
        str = char(strcat('Converting labels to ',{' '},rez));
        progressbar(str)
    end
    
    while hasdata(pxds)
        [C, info] = read(pxds);
        [~, filename, ext] = fileparts(info.Filename);
        ext = ('.png');
        
        str = 'mask';
        maskIdx = strfind(filename, str);
        filename = strcat(filename(1:maskIdx-1),"label",filename(maskIdx+length(str):end));
        if (filename~='label.tif') % bug fix
            if (~exist(fullfile(destinationPath,strcat(filename,ext)), 'file')  ...
                || forceConvert)

                % Convert from categorical to uint8.
                % (RGB-class label association -> per-pixel integer value)
                L = uint8(C);

                % Resize the data using 'nearest' interpolation to preserve labelIDs.
                L = imresize(L,[y x],'nearest');
                
                %Create empty border
                I(1,:,:) = 0;
                I(end,:,:) = 0;
                I(:,1,:) = 0;
                I(:,end,:) = 0;
                
                % Write the data to disk.
                imwrite(L,fullfile(destinationPath,strcat(filename,ext)));
            end
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
    pxds = pixelLabelDatastore(imageList,labelNames,labelIDs_scalar);
end