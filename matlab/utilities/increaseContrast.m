function grayCLAHE = increaseContrast(dimGray)

    % Apply Contrast-Limited Adaptive Histogram Equalization (CLAHE)
    grayCLAHE = adapthisteq(dimGray);

end