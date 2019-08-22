function segmentResults(networkFile, sequenceDir, outputDir, ...
  doPreprocessing, doOverlay, doCompare, labelDir, progressBarFigure)
% function segmentResults(networkFile, sequenceDir, outputDir, ...
% doPreprocessing, doOverlay, doCompare, labelDir, progressBarFigure)
% once doPreprocessing is used change line 68 and 69 as well as the app
% check app as well
    load(networkFile);
        if nargin == 3 
            %doPreprocessing = true;
            doOverlay = false;
            doCompare = false;
            labelDir = '';
        elseif nargin == 4
            %doPreprocessing = true;
            %doOverlay = false;
            doCompare = false;
            labelDir = '';
        elseif nargin == 5
            %doPreprocessing = true;
            %doCompare = false;
            labelDir = '';
        elseif nargin ==6 
            %error(['All options and labelDir needs to be supplied if ', ...
            %    'doCompare is requested'])
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
    imds = imageDatastore(sequenceDir);
    originalSize = size(imds.readimage(1));
    destinationPath = fullfile(outputDir,'tmp','img');
    
    if ~exist(fullfile(outputDir,'output'),'dir')
      mkdir(fullfile(outputDir,'output'));
    end

    if ~exist(fullfile(outputDir,'tmp'),'dir')
        mkdir(fullfile(outputDir,'tmp'))
    end
    
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
        
        
        pxds = pixelLabelDatastore(labelDir,...
        labelNames,labelIDs,'FileExtensions','.tif');
        disp("Resizing labels and converting to categorical label form...")
        
        if exist('progressBarFigure', 'var')
            progress.Value = .2;
            progress.Message = 'Resizing Labels';
        end
        destinationPath = fullfile(outputDir,'tmp','label');
        pxds = processPixelLabels(pxds, imageSize, destinationPath, ...
                forceConvert, outerProgressBar);

    end

    %% Segment data
    if exist('progressBarFigure', 'var')
        progress.Value = .3;
        progress.Message = 'Segmenting images';
    end
    
    resultPixelLabels = semanticseg(imds, net, ...
            'MiniBatchSize', 1, ...
            'WriteLocation', fullfile(outputDir, '/output'), ...
            'Verbose', true);
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
        progress.Value = .7;
        progress.Message = 'Reize output images';
    end
    
    for n = 1:length(imds.Files)
     [~,name,~] = fileparts(string(imds.Files(n)));

     I = readimage(imds,n);
        if doOverlay
            segImage = labeloverlay(I,resultPixelLabels.readimage(n), ...
                'Colormap',cmap,'Transparency',0.4);
        else
            segImage = unit8(resultPixelLabels);
        end

        if doCompare
            numClasses = numel(labelNames);
            expectedResult = readimage(pxds,n);
            actual = uint8(resultPixelLabels.readimage(n))*(255/numClasses);
            expected = uint8(expectedResult)*(255/numClasses);
            diffImage = imfuse(actual, expected);
            % ToDo: please make the '21' value programatic?
            insertLength = 21;
            str = strcat(outputDir,'/comparison/', ...
                name.insertAfter(insertLength,'_comparison'), '.tif');
            outImage = imresize(diffImage,[originalSize(1) originalSize(2)]); 
            imwrite(outImage, str);

        end
        outImage = imresize(segImage,[originalSize(1) originalSize(2)]);
        % ToDo: please make the '21' value programatic?
        insertLength = 21;
        imwrite(outImage, strcat(outputDir,'/overlay/', ...
            name.insertAfter(insertLength,'_out'),  '.tif'));

    end

    fprintf('Cleaning up... \t ')
    
    if exist('progressBarFigure', 'var')
        progress.Value = .9;
        progress.Message = 'Cleaning up';
    end

    if exist(fullfile(outputDir,'tmp'),'dir')
        [~, msg] = rmdir(fullfile(outputDir,'tmp'), 's');
        disp(msg);
    end

    clear actual ans cmap diffImage expected expectedResult I ...
        imds info labelDir labelIDs labelIDs_scalar labelNames ...
        msg n name net numClasses originalSize outputImage ...
        outputDir pxds resultPixelLabels segImage sequenceDir ...
        status str sz outImage;

    fprintf('Done \n')

    if exist('progressBarFigure', 'var')
        progress.Value = 1;
        progress.Message = 'Completed';
        close(progress);
    end
end
