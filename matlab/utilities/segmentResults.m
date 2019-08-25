function metrics = segmentResults(networkFile, sequenceObject, outputPath, ...
    doPreprocessing, doOverlay, doCompare, labelObject, batchSize, fromTraining, ...
    progressBarFigure)
    if exist('progressBarFigure', 'var')
        progress = uiprogressdlg(progressBarFigure,'Title','Performing Segmentation',...
        'Message','Starting');
    end
    if nargin == 8
        fromTraining = false;
    elseif nargin == 7
        fromTraining = false;
        batchSize = 1;
    elseif nargin == 6
        error('Compare set but no label directory specified')
    elseif nargin == 5
        fromTraining = false;
        batchSize = 1;
        labelObject = '';
        doCompare = false;
    elseif nargin == 4
        doOverlay = false;
        doCompare = false;
        labelObject = '';
        batchSize = 1;
        fromTraining = false;
    elseif nargin == 3
        doPreprocessing = true;
        doOverlay = false;
        doCompare = false;
        labelObject = '';
        batchSize = 1;
        fromTraining = false;
    end

    % variable declaration
    ext = '.png';
    setupColors;

    % load network
    load(networkFile,'net','networkStatus');
    if ~exist('net','var')
        error('No network defined')
    end

    imageSize = net.Layers(1).InputSize(1:2);

    % setup temp folder
    hashString = strcat(datestr(datetime('now')),networkStatus.name);
    newHash = cellfun(@(s)s(1:6),cellstr(mlreportgen.utils.hash(hashString)),'uni',0);
    tempOutputPathBase = fullfile(tempdir,strcat(networkStatus.name,'_',newHash));

    % assign output directory
    if fromTraining
        tryPath = fullfile(outputPath,'trainingEvaluation');
        i = 0;
        while exist(tryPath, 'dir')
            i = i + 1;
            tryPath = fullfile(outputPath, strcat('trainingEvaluation_',string(i)));
        end
        outputPath = tryPath;
        clear tryPath
    end

    % create directories
%     comparisonDir = fullfile(outputPath, 'comparison');
%     if doCompare && ~exist(comparisonDir, 'dir')
%         mkdir(comparisonDir)
%     end

    overlayDir = fullfile(outputPath,'overlay');
    if doOverlay && ~exist(overlayDir,'dir')
        mkdir(overlayDir)
    end

    tempOutputDir = fullfile(tempOutputPathBase,'output');
    if ~exist(tempOutputDir,'dir')
        mkdir(tempOutputDir);
    end
    
    outputDir = fullfile(outputPath,'output');
    if ~exist(outputDir,'dir')
        mkdir(outputDir);
    end

    analysisDir = fullfile(outputPath,'analysis');
    if ~exist(analysisDir,'dir')
        mkdir(analysisDir);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Resize (if required)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % assign the input file sequence to either an image folder, or to an imds from the trained network for testing
    if fromTraining
        % get original image size
        loadSequences;
        sizeImds = imageDatastore(imageFolders(1));
        originalSize = size(sizeImds.readimage(1));
        imds = sequenceObject;
        clear sizeImds sequences imageFolders labelFolders
    else
        if exist('progressBarFigure', 'var')
            progress.Value = 0.1;
            progress.Message = 'Resizing images';
        end

        % setup input images
        imdsInput = imageDatastore(sequenceObject);
        originalSize = size(imdsInput.readimage(1));
        tempOutputPath = fullfile(tempOutputPathBase,'img');

        forceConvert = true;
        outerProgressBar = false;
        imds = processImages(imdsInput, imageSize, tempOutputPath, ...
            forceConvert, doPreprocessing , outerProgressBar);
        clear sizeImds sequences imageFolders labelFolders
        clear newHash hashString outerProgressBar forceConvert imdsInput
    end

    if doCompare
        loadLabels;

        if fromTraining
            % input from training script is integer valued image
            pxds = labelObject;
        else
            % input from App is RGB pixel labels
            pxdsMasks = pixelLabelDatastore(labelObject, labelNames, labelIDs);

            if exist('progressBarFigure', 'var')
                progress.Value = 0.2;
            end
            forceConvert = true;
            % resize labels to match network input (save into temp folder)
            tempOutputPath = fullfile(tempOutputPathBase,'label');
            outerProgressBar = false;
            pxds = processPixelLabels(pxdsMasks, imageSize, tempOutputPath, forceConvert, outerProgressBar);
            clear outerProgressBar forceConvert
        end
    else
        metrics = 'No Metrics evaluated. Please specify ''doCompare''';
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Segment data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    disp(size(imds.readimage(1)))
    fprintf('Performing segmentation... \t');
    if exist('progressBarFigure', 'var')
        progress.Value = 0.3;
        progress.Message = 'Segmenting images';
    end
    resultPixelLabels = semanticseg(imds, net, ...
        'MiniBatchSize', batchSize, ...
        'WriteLocation', tempOutputDir, ...
        'Verbose', true);
    tempOutputNames = imageDatastore(tempOutputDir);

    fprintf('Done \n');

    if exist('progressBarFigure', 'var')
        progress.Value = 0.7;
        progress.Message = 'Resize output images';
    end

    fprintf('Processing output images... \t');
    for n = 1:numel(imds.Files)

        I = imds.readimage(n);
        labelIm = resultPixelLabels.readimage(n);

        [~,name] = fileparts(string(imds.Files(n)));
        splitName = split(name,'.');
        insertLength = strlength(splitName(1));                        % 21

        if doOverlay
            segImage = labeloverlay(I, labelIm, 'Colormap',cmap,'Transparency',0.2);
            outImage = imresize(segImage, [originalSize(1) originalSize(2)],'nearest');
            imwrite(outImage, fullfile(overlayDir, strcat(name.insertAfter(insertLength,'_overlay'),  ext)));
        end

%         if doCompare
%             expectedResult = readimage(pxds,n);
% 
%             % convert from categorical to uint8
%             actual = uint8(labelIm);
%             expected = uint8(expectedResult);
% 
%             diffImage = imfuse(actual, expected, 'diff');
%             str = fullfile(comparisonDir, strcat(name.insertAfter(insertLength,'_comparison'), ext));
%             diffImage = imresize(diffImage,[originalSize(1) originalSize(2)]);
%             imwrite(diffImage, str);
%         end

        % Change name of ouput, color labels
        
        outputName = fullfile(outputDir, strcat(name.insertAfter(insertLength,'_output'), ext));
        labelImColor = ind2rgb(labelIm, cmapOffset);
        imwrite(labelImColor, outputName);
%         cmd = char(strcat({'mv "'},string(tempOutputNames.Files(n)), {'" "'}, outputName,{'"'}));
%         if unix(cmd)
%             error('Error attempting to rename %s to %s',string(tempOutputNames.Files(n)), outputName);
%         end
    end
    fprintf('Done \n');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Evaluate and count/classify events
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % prepare input for segmentation
    pxdsResults = pixelLabelDatastore(outputDir, labelNames, labelIDs_scalar);

    % collect output
    outputData = imageDatastore(outputDir);

    % find and classify events
    fprintf('Analyzing and classifying events... \t');
    eventsCellArray = createEvents(outputData);                %#ok<NASGU>

    % Export the classifications
    save(fullfile(analysisDir, 'events' ), 'eventsCellArray')
    fprintf('Done \n');

    % Evaluate the performance metrics
    if doCompare
        metrics = evaluateSemanticSegmentation(pxdsResults, pxds, ...
            'Verbose',false);

        save(fullfile(analysisDir, 'metrics' ),'metrics')
        writetable(metrics.DataSetMetrics, fullfile(analysisDir,'DataSetMetrics.txt'));
        writetable(metrics.ClassMetrics, fullfile(analysisDir,'ClassMetrics'));
        % writetable(metrics.NormalizedConfusionMatrix, fullfile(analysisDir,'NormalizedConfusionMatrix.txt'));
        % writetable(outputMetrics.ImageMetrics, fullfile(analysisDir,'ImageMetrics.txt'));

        cprintf([0.2,0.7,0],'\t\t\t Evaluation metrics\n\n');
%         disp(metrics.NormalizedConfusionMatrix); disp(' ');
        disp(metrics.DataSetMetrics); disp(' ');
        disp(metrics.ClassMetrics); disp(' ');
    else
        metrics = 'No Evaluation performed. Enable doCompare.';
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Clean up
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fprintf('Cleaning up... \t')

    if exist('progressBarFigure', 'var')
        progress.Value = .95;
        progress.Message = 'Cleaning up';
    end

%     [~, msg] = rmdir(fullfile(tempOutputPathBase, 'img'),'s');
%     disp(msg);
    [status, msg] = rmdir(fullfile(tempOutputPathBase),'s');
    if status 
        disp(msg);
    end

    %     clear actual ans cmap diffImage expected expectedResult I ...
    %         imds info labelDir labelIDs labelIDs_scalar labelNames ...
    %         msg n name net numClasses originalSize outImage outputImage ...
    %         outputDir pxds resultPixelLabels tempDS segImage sequenceDir ...
    %         status str sz ;

    fprintf('Done \n')

    if exist('progressBarFigure', 'var')
        progress.Value = 1;
        progress.Message = 'Completed';
        close(progress);
    end
end
