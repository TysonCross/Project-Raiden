function pxds = resizePixelLabels(pxds, imageSize, destinationPath)
% Resize pixel label data to [sz(1) sz(2)].

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
    
%     rez = strcat(string(x),'x',string(y));
%     str = char(strcat('Converting labels to ',{' '},rez));
%     progressbar('',str)
    
    while hasdata(pxds)
        [C, info] = read(pxds);
        [~, filename, ext] = fileparts(info.Filename);
        
        str = 'mask';
        maskIdx = strfind(filename, str);
        filename = strcat(filename(1:maskIdx-1),"label",filename(maskIdx+length(str):end));
        if (filename~='label.tif') % bug fix
            if ~exist(fullfile(destinationPath,strcat(filename,ext)), 'file') 

                % Convert from categorical to uint8.
                % (RGB-class label association -> per-pixel integer value)
                L = uint8(C);

                % Resize the data using 'nearest' interpolation to preserve labelIDs.
                L = imresize(L,[y x],'nearest');

                % Write the data to disk.
                imwrite(L,fullfile(destinationPath,strcat(filename,ext)));
            end
        end
        
        imageList(r) = fullfile(destinationPath,strcat(filename,ext));
        progressbar([],r/N);
        r = r + 1;
    end

    progressbar([],1);
    pxds = pixelLabelDatastore(imageList,labelNames,labelIDs_scalar);
end