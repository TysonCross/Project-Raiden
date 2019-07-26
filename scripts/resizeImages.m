function imds = resizeImages(imds, imageFolder)
% Resize images to [360 480].

if ~exist(imageFolder,'dir') 
    mkdir(imageFolder)
end

reset(imds)
while hasdata(imds) %
% parfor r = 1:length(imds.Files)
    % Read an image.
%     [I,info] = imds.readimage(r); 
    [I,info] = read(imds);
    [~, filename, ext] = fileparts(info.Filename);
    
    if ~exist(strcat(imageFolder,filename,ext), 'file') 
        % Resize image.
        I = imresize(I,[360 480]);    
    
        % Write to disk.
        imwrite(I,strcat(imageFolder,filename,ext))
    end
end

imds = imageDatastore(imageFolder);
end