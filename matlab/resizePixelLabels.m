function pxds = resizePixelLabels(pxds, sz, imagePath)
% Resize pixel label data to [sz(1) sz(2)].

    y = sz(1);
    x = sz(2);
    rez = strcat(string(x),'x',string(y));
    imagePath = fullfile(imagePath,'resized',rez,'label');
    
    if ~exist(imagePath,'dir')
        mkdir(imagePath)
    end

    reset(pxds)
    N = length(pxds.Files);
    r = 1;
    imageList = string(zeros(1,N));
    
    str = char(strcat('Resizing labels to ',{' '},rez));
    progressbar(str)
    
    while hasdata(pxds)
        [C,info] = read(pxds);
        [~, filename, ext] = fileparts(info.Filename);
        
        str = 'mask';
        maskIdx = strfind(filename, str);
        filename = strcat(filename(1:maskIdx-1),"label",filename(maskIdx+length(str):end));
        
        if ~exist(fullfile(imagePath,strcat(filename,ext)), 'file') 
            % Convert from categorical to uint8.
            % (RGB-class label association -> per-pixel integer value)
            L = uint8(C);

            % Resize the data using 'nearest' interpolation to preserve labelIDs.
            L = imresize(L,[y x],'nearest');

            % Write the data to disk.
            imwrite(L,fullfile(imagePath,strcat(filename,ext)));
            
        end
        
        imageList(r) = fullfile(imagePath,strcat(filename,ext));
        progressbar(r/N);
        r = r + 1;
    end

    progressbar(1);
    ClassNames = pxds.ClassNames;
    labelIDs_Scalar = 1:numel(ClassNames);
    pxds = pixelLabelDatastore(imageList,ClassNames,labelIDs_Scalar);
end