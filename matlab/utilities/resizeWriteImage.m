function resizeWriteImage(Im16, imageSize, destinationPath, filename, ext)

    y = imageSize(1);
    x = imageSize(2);
    
    % Resize image.
    Im16 = imresize(Im16,[y x],'bicubic');

    % convert to 8-bit
    I = uint8(Im16/256 -1);

    % Create black border
        I(1,:,:) = 0;
        I(end,:,:) = 0;
        I(:,1,:) = 0;
        I(:,end,:) = 0;

    % Write image to disk.
    imwrite(I,fullfile(destinationPath,strcat(filename,ext)));
    
end