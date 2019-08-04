function [imds, pxds] = randomSubset(imds_full, pxds_full, percentage)
% Reduce the data to a randomised subset by percentage
    
% Set initial random state
rng(now); 
numFiles = numel(imds_full.Files);
shuffledIndices = randperm(numFiles);

% Use X% of the images
N = round(percentage * numFiles);
idx = shuffledIndices(1:N);

% Create image datastore
imageFiles = imds_full.Files(idx);
imds = imageDatastore(imageFiles,'FileExtensions','.tif');

% Create pixel label datastores
loadLabels;
labelFiles = pxds_full.Files(idx);
pxds = pixelLabelDatastore(labelFiles, labelNames, labelIDs,'FileExtensions','.tif');
% pxds = pixelLabelDatastore(labelFiles, labelNames, labelIDs_scalar,'FileExtensions','.tif');
end