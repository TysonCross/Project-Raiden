function metrics = evaluateNetwork(outputDir, imdsTest, pxdsTest)

    if ~exist(outputDir,'dir')
        mkdir(outputDir)
    end

    pxdsResults = semanticseg(imdsTest,net, ...
        'MiniBatchSize',32, ...
        'WriteLocation',outputDir, ...
        'Verbose',false);

    metrics = evaluateSemanticSegmentation(pxdsResults, pxdsTest, ...
        'Verbose',false);
end