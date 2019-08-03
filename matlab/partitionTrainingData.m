function [imdsTrain, imdsVal, pxdsTrain, pxdsVal] = partitionTrainingData(imds, pxds)
% Partition data by randomly selecting 80% of the data for training,
% the rest is used for validation.
    
% Set initial random state for example reproducibility
rng(0); 
numFiles = numel(imds.Files);
shuffledIndices = randperm(numFiles);

% Use 80% of the images for training
N = round(0.80 * numFiles);
trainingIdx = shuffledIndices(1:N);

% Use the rest for testing
validationIdx = shuffledIndices(N+1:end);

% Create image datastores for training and validation
trainingImages = imds.Files(trainingIdx);
validationImages = imds.Files(validationIdx);
imdsTrain = imageDatastore(trainingImages);
imdsVal = imageDatastore(validationImages);

% Extract class and label IDs info
classes = pxds.ClassNames;
labelIDs = 1:numel(pxds.ClassNames);

% Create pixel label datastores for trainin and validation
trainingLabels = pxds.Files(trainingIdx);
validationLabels = pxds.Files(validationIdx);
pxdsTrain = pixelLabelDatastore(trainingLabels, classes, labelIDs);
pxdsVal = pixelLabelDatastore(validationLabels, classes, labelIDs);
end