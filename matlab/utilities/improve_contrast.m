function rgbFixed = improve_contrast(dimRGB)

    % Extract the individual red, green, and blue color channels.
    redChannel = dimRGB(:, :, 1);
    greenChannel = dimRGB(:, :, 2);
    blueChannel = dimRGB(:, :, 3);

    % Apply Contrast-Limited Adaptive Histogram Equalization (CLAHE)
    redCLAHE = adapthisteq(redChannel);
    greenCLAHE = adapthisteq(greenChannel);
    blueCLAHE = adapthisteq(blueChannel);

    % Reconstruct the RGB image
    rgbFixed = cat(3, redCLAHE, greenCLAHE, blueCLAHE);
end