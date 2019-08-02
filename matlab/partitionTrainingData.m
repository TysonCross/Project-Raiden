function [imdsTrain, imdsVal, pxdsTrain, pxdsVal] = partitionValidationData(imds, pxds)
% Partition  data by randomly selecting 60% of the data for training.
% 20% used for validation, and the rest is used for testing.
    
% Set initial random state for example reproducibility.
rng(0); 
numFiles = numel(imds.Files);
shuffledIndices = randperm(numFiles);

% Use 80% of the images for training.
N = round(0.80 * numFiles);
trainingIdx = shuffledIndices(1:N);

% Use the rest for testing.
validationIdx = shuffledIndices(N+1:end);

% Create image datastores for training, validation and test.
trainingImages = imds.Files(trainingIdx);
validationImages = imds.Files(validationIdx);
imdsTrain = imageDatastore(trainingImages);
imdsVal = imageDatastore(validationImages);

% Extract class and label IDs info.
classes = pxds.ClassNames;
labelIDs = 1:numel(pxds.ClassNames);

% Create pixel label datastores for training, validation and test..
trainingLabels = pxds.Files(trainingIdx);
validationLabels = pxds.Files(validationIdx);
pxdsTrain = pixelLabelDatastore(trainingLabels, classes, labelIDs);
pxdsVal = pixelLabelDatastore(validationLabels, classes, labelIDs);
end