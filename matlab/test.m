sz = imageSize;

y = sz(1);
x = sz(2);

    rez = strcat(string(x),'x',string(y));
    imagePath = fullfile(imagePath,'resized',rez,'label');
    
    reset(pxdsTrain)
    N = length(pxdsTrain.Files);
    r = 1;
    imageList = string(zeros(1,N));
    
%      while hasdata(pxds)
        [C, info] = read(pxdsTrain);
        [~, filename, ext] = fileparts(info.Filename);
        
        str = 'mask';
        maskIdx = strfind(filename, str);
        filename = strcat(filename(1:maskIdx-1),"label",filename(maskIdx+length(str):end));
        
        if ~exist(fullfile(imagePath,strcat(filename,ext)), 'file') 
            
            % Convert from categorical to uint8.
            % (RGB-class label association -> per-pixel integer value)
            L = uint8(C);
            
            I = imread('/home/tyson/Raiden/data/resized/227x227/image/2017-02-10_163916_020.00003261.tif')
            figure(1)
            imshow(I)
            figure(2)
            imshow(L)

            % Resize the data using 'nearest' interpolation to preserve labelIDs.
            L = imresize(L,[y x],'nearest');

            % Write the data to disk.
%             imwrite(L,fullfile(imagePath,strcat(filename,ext)));
            
        end
        
        imageList(r) = fullfile(imagePath,strcat(filename,ext));
        progressbar(r/N);
%     end

    progressbar(1);
    ClassNames = pxds.ClassNames;
    labelIDs_Scalar = 1:numel(ClassNames);
    pxds = pixelLabelDatastore(imageList,ClassNames,labelIDs_Scalar);