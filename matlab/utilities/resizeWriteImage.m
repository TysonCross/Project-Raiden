function resizeWriteImage(Im16, imageSize, destinationPath, ...
                            filename, ext, doBorders)
    
    if nargin < 6
        doBorders = false;
    end

    y = imageSize(1);
    x = imageSize(2);
    
    % Resize image.
    I = imresize(Im16,[y x],'bicubic');
    
    if doBorders
    % Create black border
        I(1,:,:) = 0;
        I(end,:,:) = 0;
        I(:,1,:) = 0;
        I(:,end,:) = 0;
    end

    % Write image to disk.
    imwrite(I,fullfile(destinationPath,strcat(filename,ext)));
    
end