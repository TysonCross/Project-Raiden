function imds = resizeImagesPar(imds, sz, imagePath)
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
    
	parfor_progress(N);

    parfor r = 1:length(imds.Files)
        [~,info] = imds.readimage(r); 
        [~, filename, ext] = fileparts(info.Filename);
        
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
        parfor_progress;
    end

    parfor_progress(0);
    imds = imageDatastore(imageList);
end