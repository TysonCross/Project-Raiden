function imds = resizeImages(imds, imageSize, destinationPath)
 % Resize images to [sz(1) sz(2)].

     if ~exist(destinationPath,'dir')
        mkdir(destinationPath)
     end
    
    y = imageSize(1);
    x = imageSize(2);
    
    reset(imds)
    N = length(imds.Files);
    r = 1;
    imageList = string(zeros(1,N));
    
%     rez = strcat(string(x),'x',string(y));
%     str = char(strcat('Resizing images to ',{' '},rez));
%     progressbar('',str)

    while hasdata(imds)
        [Im16,info] = read(imds);
        [~, filename, ext] = fileparts(info.Filename);
        
        if ~exist(fullfile(destinationPath,strcat(filename,ext)), 'file')

            % Convert to 8-bit
            I = uint8(Im16/256);
            
            % Resize image.
            I = imresize(I,[y x]);    

            % Write to disk.
            imwrite(I,fullfile(destinationPath,strcat(filename,ext)));
        end
        
        imageList(r) = fullfile(destinationPath,strcat(filename,ext));
        progressbar([],r/N);
        r = r + 1;
    end

    progressbar([],1);
    imds = imageDatastore(imageList);
end