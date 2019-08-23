function outputMetrics = segmentResults(networkFile, sequences, outputPath, ...
  doPreprocessing, doOverlay, doCompare, labels, isDsPassed, progressBarFigure)

ext = '.png';

    load(networkFile);
    outputDir = fullfile(outputPath,networkStatus.name,'trainingEvaluation');
    i=0;
    while exist(outputDir, 'dir')
        i=i+1;
        outputDir = fullfile(outputPath,networkStatus.name, ...
            strcat('trainingEvaluation_',string(i)));
    end
    
    if nargin == 6
         error('Compare set but no label directory specified')
    elseif nargin == 5
        doCompare = false;
        labels = '';
    elseif nargin == 4
        doOverlay = false;
        doCompare = false;
        labels = '';
    elseif nargin == 3
        doPreprocessing = true;
        doOverlay = false;
        doCompare = false;
        labels = '';
    end

    if ~exist('net','var')
        if exist('lgraph','var')
            net =lgraph;
        else
            error('No network defined')
        end
    end
    
    if exist('progressBarFigure', 'var')
        progress = uiprogressdlg(progressBarFigure,'Title','Please Wait',...
            'Message','Loading network');
        loadLabels;
    end
    
    setupColors;
    imageSize = net.Layers(1).InputSize(1:2);

    %% Resize
    if isDsPassed
       imds = sequences;
    else
        imds = imageDatastore(sequences);
    end
    
    originalSize = size(imds.readimage(1));
    destinationPath = fullfile(tempdir,'img');
    
    if ~exist(fullfile(outputDir,'output'),'dir')
      mkdir(fullfile(outputDir,'output'));
    end

%     if ~exist(fullfile(outputDir,'tmp'),'dir')
%         mkdir(fullfile(outputDir,'tmp'))
%     end
%     
    if exist('progressBarFigure', 'var')
        progress.Value = .1;
        progress.Message = 'Resizing images';
        disp("Resizing images...")
    end
    
    y = imageSize(1);
    x = imageSize(2);
    rez = strcat(string(x),'x',string(y));
    forceConvert = true;
    outerProgressBar = false;
    imds = processImages(imds, imageSize, destinationPath, ...
    forceConvert, doPreprocessing , outerProgressBar);
   
    if doCompare
        if isDsPassed
            pxds = labels;
        else
            pxds = pixelLabelDatastore(labels, ...
            labelNames, labelIDs, 'FileExtensions','.tif');
        end
        disp("Resizing labels and converting to categorical label form...")
        
        if exist('progressBarFigure', 'var')
            progress.Value = .2;
            progress.Message = 'Resizing Labels';
        end
        destinationPath = fullfile(tempdir,'label');
        pxds = processPixelLabels(pxds, imageSize, destinationPath, ...
                forceConvert, outerProgressBar);
    else
        outputMetrics = [];
    end

    %% Segment data
    if exist('progressBarFigure', 'var')
        progress.Value = 0.3;
        progress.Message = 'Segmenting images';
    end
    
    resultPixelLabels = semanticseg(imds, net, ...
            'MiniBatchSize', 1, ...
            'WriteLocation', fullfile(outputDir, 'output'), ...
            'Verbose', true);
    tempDS = imageDatastore(fullfile(outputDir, 'output')); 
    
    if doCompare
         if ~exist(fullfile(outputDir,'comparison'),'dir')
            mkdir(fullfile(outputDir,'comparison'))
        end
    end

    if doOverlay
        disp('Creating overlay...')
        if ~exist(fullfile(outputDir,'overlay'),'dir')
            mkdir(fullfile(outputDir,'overlay'))
        end
    end
    
    if exist('progressBarFigure', 'var')
        progress.Value = 0.7;
        progress.Message = 'Resize output images';
    end
    
    for n = 1:length(imds.Files)
     [~,name,~] = fileparts(string(imds.Files(n)));

     I = readimage(imds,n);

        if doOverlay
            segImage = labeloverlay(I,resultPixelLabels.readimage(n), ...
                'Colormap',cmap,'Transparency',0.2);
        else
            segImage = unit8(resultPixelLabels);
        end

            splitName = split(name,'.');
            insertLength = strlength(splitName(1));  % 21

        if doCompare
            numClasses = numel(labelNames);
            expectedResult = readimage(pxds,n);
            actual = uint8(resultPixelLabels.readimage(n));
            expected = uint8(expectedResult);
            %show diff only
%             actual = uint8(resultPixelLabels.readimage(n));
%             expected = uint8(expectedResult)
            diffImage = imfuse(actual, expected, 'diff');
            str = fullfile(outputDir,'comparison', ...
                strcat(name.insertAfter(insertLength,'_comparison'), ext));
            outImage = imresize(diffImage,[originalSize(1) originalSize(2)]); 
            imwrite(outImage, str);

        end
        
        outImage = imresize(segImage,[originalSize(1) originalSize(2)]);
        imwrite(outImage, fullfile(outputDir,'overlay', ...
            strcat(name.insertAfter(insertLength,'_overlay'),  ext)));
        
        % Change name of ouput
        outputName = fullfile(outputDir, 'output', ...
            strcat(name.insertAfter(insertLength,'_output'),  ext));
        
        movefile(string(tempDS.Files(n)),outputName);
       
    end
    %% Evaluate and produce events
    pxdsResults = pixelLabelDatastore(fullfile(outputDir, ...
        '/output'),labelNames,labelIDs_scalar);
    
     outputMetrics = evaluateSemanticSegmentation(pxdsResults, pxds, ...
        'Verbose',false);
    
    
     finalOutputDir = fullfile(outputDir, 'output');
     outputDs = imageDatastore(finalOutputDir, 'FileExtensions', '.png');

            eventsCellArray = createEvents(outputDs);
            % export the variables
            % Events
            analysisDir = fullfile(outputDir,'analysis');
            mkdir(analysisDir)
            save(fullfile(analysisDir, 'events' ),"eventsCellArray")
            % metrics
            if doCompare % require a pxds 
                cprintf([0.2,0.7,0],'\t\t\t Evaluation metrics\n\n');
                save(fullfile(analysisDir, 'outputMetrics' ),"metrics")
                writetable(outputMetrics.NormalizedConfusionMatrix, ...
                    fullfile(analysisDir,'NormalizedConfusionMatrix.txt'));
                disp(outputMetrics.NormalizedConfusionMatrix); disp(' ');
                writetable(outputMetrics.DataSetMetrics, ...
                    fullfile(analysisDir,'DataSetMetrics.txt'));
                disp(outputMetrics.DataSetMetrics); disp(' ');
                writetable(outputMetrics.ClassMetrics, ...
                    fullfile(analysisDir,'ClassMetrics'));
                disp(outputMetrics.ClassMetrics); disp(' ');
                % writetable(metrics.ImageMetrics, ...
                %   fullfile(analysisDir,'ImageMetrics.txt'));
                % disp(metrics.ImageMetrics); disp(' ');
            end
    %% Clean up
    fprintf('Cleaning up... \t ')
    
    if exist('progressBarFigure', 'var')
        progress.Value = .95;
        progress.Message = 'Cleaning up';
    end


      [~, msg] = rmdir(fullfile(tempdir, 'img'),'s');
      disp(msg);
      [~, msg] = rmdir(fullfile(tempdir, 'label'),'s');
      disp(msg);

    clear actual ans cmap diffImage expected expectedResult I ...
        imds info labelDir labelIDs labelIDs_scalar labelNames ...
        msg n name net numClasses originalSize outImage outputImage ...
        outputDir pxds resultPixelLabels tempDS segImage sequenceDir ...
        status str sz ;

    fprintf('Done \n')

    if exist('progressBarFigure', 'var')
        progress.Value = 1;
        progress.Message = 'Completed';
        close(progress);
    end
end
