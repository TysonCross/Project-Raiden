function rgbFixed = noise_removal_gpu(noisyRGB) %#codegen
    coder.gpu.kernelfun();
    
    % Extract the individual red, green, and blue color channels.
    redChannel = noisyRGB(:, :, 1);
    greenChannel = noisyRGB(:, :, 2);
    blueChannel = noisyRGB(:, :, 3);

    % Median Filter the channels
    redMF = medfilt2(redChannel, [2 2]);
    greenMF = medfilt2(greenChannel, [2 2]);
    blueMF = medfilt2(blueChannel, [2 2]);

    % Reconstruct the noise free RGB image
    rgbFixed = cat(3, redMF, greenMF, blueMF);
end