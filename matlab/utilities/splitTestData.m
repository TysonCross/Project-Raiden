function splitTestData(resizedImageFolders, cachePath, resizedLabelFolders, ...
    splitTestPercent, dataPercentage)

    loadLabels;
    ext = '.png';
    
    % [split training and test]
    [trainIndex, testIndex] = splitSequences(resizedImageFolders, ...
        splitTestPercent, ext);
    
    imageFolder = cellstr(resizedImageFolders);
    labelFolder = cellstr(resizedLabelFolders);

    % Create datastores
    imdsTrain = imageDatastore(imageFolder(trainIndex));
    pxdsTrain = pixelLabelDatastore(labelFolder(trainIndex),...
        labelNames,labelIDs_scalar);
    assert(numel(imdsTrain.Files)==numel(pxdsTrain.Files));
    
    imdsTest = imageDatastore(imageFolder(testIndex));
    pxdsTest = pixelLabelDatastore(labelFolder(testIndex),...
        labelNames,labelIDs_scalar);
    assert(numel(imdsTest.Files)==numel(pxdsTest.Files))

    % Most input non-stroke frame have multiple frames that are extremely 
    % similar. This function reduces the non-stroke frames to a randomised
    % percentage of the total frames. The random subset of frames are 
    % returned sorted, by sequence and filename/frame order
    % The test set should not be threshed as we need to evaluate whole
    % sequences for the direction classification to work.
    if dataPercentage < 1
        [imdsTrain, pxdsTrain] = randomSubset(imdsTrain, pxdsTrain, dataPercentage);
    end
    
    % Calculate the class weights 
    disp("Counting per-label pixel distribution...")
    labelTable = pxdsTrain.countEachLabel;
    imageFreq = labelTable.PixelCount ./ labelTable.ImagePixelCount;
    labelWeights = median(imageFreq) ./ imageFreq;

%     clear trainIndex testIndex

    save(fullfile(cachePath,'data'), ...
    'imdsTrain','pxdsTrain', ...
    'imdsTest','pxdsTest', ...
    'labelWeights','labelTable');

    disp("Datastores cached") 
end