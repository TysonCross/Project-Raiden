function strokeArray = createVolume(imdsInput, imdsLabel, chosenLabel)
for i=1:252
    inputImage = imdsInput.readimage(i);
    maskImage = imdsLabel.readimage(i);
    maskImage = maskImage==chosenLabel;
    maskedRgbImage = bsxfun(@times, inputImage, cast(maskImage, 'like', inputImage));
    strokeArray{i} = maskedRgbImage(:,:,1);
%     imwrite(maskedRgbImage, [num2str(i) '.png']);
end

method = 'bicubic';

vis3D(vol, method);