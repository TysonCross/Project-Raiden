function splitValidationData(imds, pxds, splitPercentage, cachePath, ...
    imdsTest, pxdsTest, labelWeights, labelTable)
    disp("Partitioning test and training Data...")
% Partitions data by randomly selecting a percentage of the data for training,
% the rest is used for validation.

% Set initial random state 
    rng(now);
    numFiles = numel(imds.Files);
    shuffledIndices = randperm(numFiles);

    % Use a percentage of the images for training
    N = round(splitPercentage * numFiles);
    trainingIdx = shuffledIndices(1:N);

    % Use the rest for testing
    validationIdx = shuffledIndices(N+1:end);

    % Create image datastores for training and validation
    trainingImages = imds.Files(trainingIdx);
    validationImages = imds.Files(validationIdx);
    imdsTrain = imageDatastore(trainingImages);
    imdsVal = imageDatastore(validationImages);

    % load class and label IDs info
    loadLabels;

    % Create pixel label datastores for training and validation
    trainingLabels = pxds.Files(trainingIdx);
    validationLabels = pxds.Files(validationIdx);
    pxdsTrain = pixelLabelDatastore(trainingLabels, labelNames, labelIDs_scalar);
    pxdsVal = pixelLabelDatastore(validationLabels, labelNames, labelIDs_scalar);

    % check nothing went wrong
    assert(numel(imdsTrain.Files)==numel(pxdsTrain.Files));
    assert(numel(imdsVal.Files)==numel(pxdsVal.Files));
    
    save(fullfile(cachePath,'data'), ...
        'imdsTrain', 'imdsVal', 'imdsTest', ...
        'pxdsTrain', 'pxdsVal', 'pxdsTest', ...
        'labelWeights', 'labelTable');
    
    disp("Data cached") 
    
end