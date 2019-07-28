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
    r = 1;
    imageList = string(zeros(1,N));
    
    str = char(strcat('Resizing images to ',{' '},rez));
    progressbar(str)
    
    while hasdata(imds)
        [Im16,info] = read(imds);
        [~, filename, ext] = fileparts(info.Filename);
        
        if ~exist(fullfile(imagePath,strcat(filename,ext)), 'file')
            % Convert to 8-bit
            I = uint8(Im16/256);
            
            % Resize image.
            I = imresize(I,[y x]);    

            % Write to disk.
            imwrite(I,fullfile(imagePath,strcat(filename,ext)));
        end
        
        imageList(r) = fullfile(imagePath,strcat(filename,ext));
        progressbar(r/N);
        r = r + 1;
    end

    progressbar(1);
    imds = imageDatastore(imageList);
end