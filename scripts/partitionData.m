function [imdsTrain, imdsVal, imdsTest, pxdsTrain, pxdsVal, pxdsTest ] = partitionCamVidData(imds,pxds)
% Partition CamVid data by randomly selecting 60% of the data for training.
% 20% used for validation, and the rest is used for testing.
    
% Set initial random state for example reproducibility.
rng(0); 
numFiles = numel(imds.Files);
shuffledIndices = randperm(numFiles);

% Use 60% of the images for training.
N = round(0.60 * numFiles);
trainingIdx = shuffledIndices(1:N);

% Use 20% of the images for validation
V = round(0.20 * numFiles);
validationIdx = shuffledIndices(N+1:N+V);

% Use the rest for testing.
testIdx = shuffledIndices(N+V+1:end);

% Create image datastores for training, validation and test.
trainingImages = imds.Files(trainingIdx);
validationImages = imds.Files(validationIdx);
testImages = imds.Files(testIdx);
imdsTrain = imageDatastore(trainingImages);
imdsVal = imageDatastore(validationImages);
imdsTest = imageDatastore(testImages);

% Extract class and label IDs info.
classes = pxds.ClassNames;
labelIDs = 1:numel(pxds.ClassNames);

% Create pixel label datastores for training, validation and test..
trainingLabels = pxds.Files(trainingIdx);
validationLabels = pxds.Files(validationIdx);
testLabels = pxds.Files(testIdx);
pxdsTrain = pixelLabelDatastore(trainingLabels, classes, labelIDs);
pxdsVal = pixelLabelDatastore(validationLabels, classes, labelIDs);
pxdsTest = pixelLabelDatastore(testLabels, classes, labelIDs);
end