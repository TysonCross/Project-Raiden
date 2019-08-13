function rgbFixed = noise_removal(noisyRGB, filterSize)
    if nargin < 2
            filterSize = 2;
    end
    
    % Extract the individual red, green, and blue color channels.
    redChannel = noisyRGB(:, :, 1);
    greenChannel = noisyRGB(:, :, 2);
    blueChannel = noisyRGB(:, :, 3);

    % Median Filter the channels
    redMF = medfilt2(redChannel, [filterSize filterSize]);
    greenMF = medfilt2(greenChannel, [filterSize filterSize]);
    blueMF = medfilt2(blueChannel, [filterSize filterSize]);

    % Reconstruct the noise free RGB image
    rgbFixed = cat(3, redMF, greenMF, blueMF);
end