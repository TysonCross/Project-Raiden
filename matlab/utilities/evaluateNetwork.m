function metrics = evaluateNetwork(imdsTest, pxdsTest, net, networkStatus)

    % setup temp folder
    hashString = strcat(datestr(datetime('now')),networkStatus.name);
    newHash = cellfun(@(s)s(1:6),cellstr(mlreportgen.utils.hash(hashString)),'uni',0);
    tempOutputDir = fullfile(tempdir,strcat(networkStatus.name,'_',newHash));
    
    if ~exist(tempOutputDir,'dir')
        mkdir(tempOutputDir);
    end

    pxdsResults = semanticseg(imdsTest,net, ...
        'MiniBatchSize',32, ...
        'WriteLocation',tempOutputDir, ...
        'Verbose',false);

    metrics = evaluateSemanticSegmentation(pxdsResults, pxdsTest, ...
        'Verbose',false);
    
    % cleanup
    [status, msg] = rmdir(fullfile(tempOutputDir),'s');
    if status 
        disp(msg);
    end
end