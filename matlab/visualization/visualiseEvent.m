function strokeArray = visualiseEvent(imds, pxds, ...
    chosenLabel, frameRange)

    for i=frameRange
        inputImage = im2uint8(imds.readimage(i));
        maskImage = uint8(pxds.readimage(i));
        maskImage(maskImage~=chosenLabel) = 0;
        inputImage = inputImage(:,:,1);
        maskedRgbImage = inputImage .* maskImage;
%         maskedRgbImage = bsxfun(@times, inputImage, cast(maskImage, 'like', inputImage));
        vol(:,:,i) = maskedRgbImage(:,:,1);
    end

    method = 'bicubic';
    
    view([45 30]); 
    vis3D(vol, method);
end