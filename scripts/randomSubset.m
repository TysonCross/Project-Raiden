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
ClassNames = pxds_full.ClassNames;
labelIDs = 1:numel(pxds_full.ClassNames);
labelFiles = pxds_full.Files(idx);
pxds = pixelLabelDatastore(labelFiles, ClassNames, labelIDs,'FileExtensions','.tif');
end