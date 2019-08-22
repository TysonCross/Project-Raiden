function metrics = evaluateNetwork(outputDir, imdsTest, pxdsTest)

    if ~exist(outputDir,'dir')
        mkdir(outputDir)
    end

    pxdsResults = semanticseg(imdsTest,net, ...
        'MiniBatchSize',32, ...
        'WriteLocation',outputDir, ...
        'Verbose',true);

    metrics = evaluateSemanticSegmentation(pxdsResults, pxdsTest, ...
        'Verbose',false);
end