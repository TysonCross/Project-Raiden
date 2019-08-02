function imds = resizeImages(imds, sz, imagePath)
 % Resize images to [sz(1) sz(2)].

    y = sz(1);
    x = sz(2);
   
    rez = strcat(string(x),'x',string(y));
    imagePath = fullfile(imagePath,'resized',rez,'image');
 
    if ~exist(imagePath,'dir')
        mkdir(imagePath)
    end

    reset(imds)
    N = length(imds.Files);
    imageList = string(zeros(1,N));
    
    str = char(strcat('Resizing images to ',{' '},rez));
    progressbar(str)

    for r = 1:numel(imds.Files)
        [~, filename, ext] = fileparts(imds.Files{r});
        
        if ~exist(fullfile(imagePath,strcat(filename,ext)), 'file')
            Im16 = imds.readimage(r);

            % Convert to 8-bit
            I = uint8(Im16/256);
            
            % Resize image.
            I = imresize(I,[y x]);    

            % Write to disk.
            imwrite(I,fullfile(imagePath,strcat(filename,ext)));
        end
        
        imageList(r) = fullfile(imagePath,strcat(filename,ext));
        progressbar(r/N);
    end

    progressbar(1);
    imds = imageDatastore(imageList);
end