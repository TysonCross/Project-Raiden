function splitValidationData(imdsTrain, pxdsTrain, splitTrainingPercentage)
    disp("Partitioning test and training Data...")

    % Split training and validation
    [imdsTrain, imdsVal, pxdsTrain, pxdsVal] = ...
        partitionTrainingData(imdsTrain, pxdsTrain, splitTrainingPercentage);

    assert(numel(imdsTrain.Files)==numel(pxdsTrain.Files));
    assert(numel(imdsVal.Files)==numel(pxdsVal.Files));
    
    % Define validation data.
    pximdsVal = pixelLabelImageDatastore(imdsVal,pxdsVal);
        
    save(fullfile(cachePath,'data'), ...
        'imdsTrain', 'imdsVal', 'imdsTest', ...
        'pxdsTrain', 'pxdsVal', 'pxdsTest', ...
        'pximdsVal', 'labelWeights', 'labelTable');
    
    disp("Data cached") 
    
end