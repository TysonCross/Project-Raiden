figHandle = findall(groot, 'Type', 'Figure');
close(figHandle(:))
setenv('NVIDIA_CUDNN', '/usr/local/cuda');
setenv('NVIDIA_TENSORRT', '/opt/TensorRT-5.1.2.2');
% results = coder.checkGpuInstall('full')
clc;
clearvars;

%% SETUP
network = 'deeplabv3'; 
%{
    Network choices are:
    'fcn8s' (batch size ~10)
    'alexnet' (batchsize ~100)
    'deeplabv3' (batchsize ~100)
    'segnet' (batchsize ~20)
    'u-net' TBD
%}

% Percent of data to train with (0-1)
% percentage = 1.0;

% Phases to run
forceConvert        = 0         % if true, resize/process new data (slow)
partitionData       = 1         % if true, re-split Test/Training (warning)
resplitValidation   = 1         % if true, re-split Training/Validation
useCachedNet        = 0         % if false, generate new neural network
doTraining         	= 1         % if true, perform training
recoverCheckpoint   = 0         % if training did not finish, use checkpoint
archiveNet          = 1         % archive NN, data and figures to subfolder
saveImages          = 1         % generate performance figures
sendNotification    = 1         % send email notification on completion
evaluateNet         = 1         % if true, evaluate performance on test set

% global setup
rootPath = '/home/tyson/Raiden/';
scriptPath = fullfile(rootPath,'matlab');
setupColors;

networkStatus.name = strcat(network,'_',strrep(strrep(datestr(datetime('now'),31), ' ', '_'), ':', ''));

cachePath = fullfile(scriptPath,'cache');
if ~exist(cachePath,'dir')
    mkdir(cachePath);
end
checkpointPath = fullfile(rootPath,'networks','checkpoints');
if ~exist(checkpointPath,'dir')
    mkdir(checkpointPath);
end

% resolution setup
imageSize = getResolution(network);
y = imageSize(1);
x = imageSize(2);
rez = strcat(string(x),'x',string(y));

logFile = strcat(networkStatus.name,'.txt');
logFileFull = fullfile(rootPath,'logs',logFile)
diary(logFileFull)

%% Data Conversion Phase 

% This process is slow. Although there are several checks to determine
% if any source files (tifs or mask images) must be reconverted,
% this should ideally be a once off conversion. If a file exists on disk
% in the destination resized/converted folder, it will not be reconverted.

loadLabels;
loadSequences;

if (forceConvert==false)
    disp('Checking sequences...')
    % hashCheck:
    if (exist(fullfile(rootPath,'data','resized',rez,'fingerprint.mat'),'file')) ...
         
        newHash = mlreportgen.utils.hash(strcat(sequences{:},rez));
        load(fullfile(rootPath,'data','resized',rez,'fingerprint.mat'),'fingerprint');
        if (fingerprint==newHash)
            convertData=false;
        else
            convertData=true;
        end
    else % hashCheck is missing, but maybe the sequences are correct
        warning('Hash file not found. Comparing converted and specified sequences')
        converted = listConvertedSequences(rootPath, imageSize);
        if length(sequences)==length(converted)
            converted = sort(converted);
            sequences = sort(sequences);
            for i=1:numel(converted)
                if strcmpi(converted(i),sequences(i))
                    if ~forceConvert
                        warning('Source and conversion folders match. Data will not converted. Enable forceConvert to override')
                        convertData=false;
                        break
                    else
                        warning('Source and conversion folders match but forceConvert is on');
                        convertData=true;
                    end
                else
                    warning('Converted images differ from source. New data will be be converted.')
                    convertData=true;
                end
            end
        else
            convertData=true;
        end
    end
else
    convertData=true;
end
    
if ( (convertData==true) || (forceConvert==true) )
    disp("Converting Data...")
    
    % [Get list of sequences]
    loadSequences;
    resizedImageFolders = fullfile(rootPath,'data','resized', ...
        rez,sequences,'image');
    resizedLabelFolders = fullfile(rootPath,'data','resized', ...
        rez,sequences,'label');
    
    % create default datastores
    loadLabels;
    parfor i = 1:numel(imageFolders)
        imds{i} = imageDatastore(imageFolders(i),...
            'FileExtensions','.tif');
        pxds{i} = pixelLabelDatastore(maskFolders(i),...
            labelNames,labelIDs,'FileExtensions','.tif');
    end
    
    disp("Resizing images and labels, converting to categorical label form...")   
    y = imageSize(1);
    x = imageSize(2);
    rez = strcat(string(x),'x',string(y));
    str = char(strcat('Resizing images to ',{' '},rez));
    progressbar('Resizing image sequences',str)
    for j = 1:numel(imageFolders)
        % [Convert all 'tifs' to imageSize]
        imds{j} = resizeImages(imds{j}, imageSize, resizedImageFolders{j});
        progressbar(j/numel(imageFolders),[])
    end
    str = char(strcat('Converting labels to ',{' '},rez));
    progressbar('Resizing and converting label sequences',str)
    for j = 1:numel(imageFolders)
        % [Convert all 'mask' to imageSize, and RGB -> categorical]
        pxds{j} = resizePixelLabels(pxds{j}, imageSize, resizedLabelFolders{j});
        progressbar(j/numel(imageFolders),[])
    end
 progressbar(1)
    
    converted = listConvertedSequences(rootPath, imageSize);
    if numel(converted)~=numel(sequences)
        disp('Conversion failed for sequences:');
        disp(setdiff(sequences,converted));
        error('Conversion failed');
    else
        disp("Data converted successfully")
        fingerprint = mlreportgen.utils.hash(strcat(converted{:},rez));
        save(fullfile(rootPath,'data','resized',rez,'fingerprint'),'fingerprint');
    end
    
    clear imds pxds resolutionList fingerprint newHash 
    clear imageFolders maskFolders forceConvert convertData

    save(fullfile(cachePath,'metadata'), ...
    'resizedImageFolders','resizedLabelFolders', ...
    'labelIDs','labelIDs_scalar','labelNames', ...
    'sequences','rez');
    disp("Metadata cached") 
else
    load(fullfile(cachePath,'metadata'));
    disp('Loaded metadata from cache...')
end

diary off; diary on;

%% Test partition phase

% Check to see if cache exists
if partitionData && ~exist(fullfile(cachePath,strcat('data','.mat')),'file')
    warning(['No datastore cache found at: ', fullfile(cachePath,'data'), ...
        newline, '(Data will be repartitioned)'])
    partitionData=0;
end

if (partitionData==true)
    disp("Partitioning test and training Data...")

    % [split training and test]
    splitPercent = 0.15;
    [trainIndex, testIndex] = splitData(resizedImageFolders, splitPercent);
    
    imageFolder = cellstr(resizedImageFolders);
    labelFolder = cellstr(resizedLabelFolders);

    % Create datastores
    imdsTrain = imageDatastore(imageFolder(trainIndex),...
        'FileExtensions','.tif');
    pxdsTrain = pixelLabelDatastore(labelFolder(trainIndex),...
        labelNames,labelIDs_scalar,'FileExtensions','.tif');
    assert(numel(imdsTrain.Files)==numel(pxdsTrain.Files));
    
    imdsTest = imageDatastore(imageFolder(testIndex),...
        'FileExtensions','.tif');
    pxdsTest = pixelLabelDatastore(labelFolder(testIndex),...
        labelNames,labelIDs_scalar,'FileExtensions','.tif');
    assert(numel(imdsTest.Files)==numel(pxdsTest.Files));

    % Calculate the class weights 
    disp("Counting per-label pixel distribution...")  % ToDo: This is slow!
    labelTable = pxdsTrain.countEachLabel;
    imageFreq = labelTable.PixelCount ./ labelTable.ImagePixelCount;
    labelWeights = median(imageFreq) ./ imageFreq;
    disp(labelTable);

    clear trainIndex testIndex

    save(fullfile(cachePath,'data'), ...
    'imdsTrain','pxdsTrain', ...
    'imdsTest','pxdsTest', ...
    'labelWeights','labelTable');
    disp("Datastores cached") 
else
    load(fullfile(cachePath,'data'));
    disp('Loaded datastores from cache...')
    disp("Per-label pixel distribution:")
    disp(labelTable);
end

diary off; diary on;

%% Training partition phase 

if (resplitValidation==true)
    disp("Splitting training/validation data...")
   
    splitPercentage = 0.80;
    % Split training and validation
    [imdsTrain, imdsVal, pxdsTrain, pxdsVal] = ...
        partitionTrainingData(imdsTrain, pxdsTrain, splitPercentage);

    assert(numel(imdsTrain.Files)==numel(pxdsTrain.Files));
    assert(numel(imdsVal.Files)==numel(pxdsVal.Files));
    
    fprintf('Training images: %d \n', numel(imdsTrain.Files));
    fprintf('Validation images: %d \n', numel(imdsVal.Files));
    fprintf('Testing images: %d \n', numel(imdsTest.Files));
    
    % Define validation data.
    pximdsVal = pixelLabelImageDatastore(imdsVal,pxdsVal);
        
    save(fullfile(cachePath,'data'), ...
        'imdsTrain', 'imdsVal', 'imdsTest', ...
        'pxdsTrain', 'pxdsVal', 'pxdsTest', ...
        'pximdsVal', 'labelWeights', 'labelTable');
    disp("Data cached") 
else
    load(fullfile(cachePath,'data'));
    disp('Using training/validation split from cache...')
    fprintf('Training images: %d \n', numel(imdsTrain.Files));
    fprintf('Validation images: %d \n', numel(imdsVal.Files));
    fprintf('Testing images: %d \n', numel(imdsTest.Files));
end

diary off; diary on;

%% Network setup phase

if recoverCheckpoint
    disp("Attempting to load checkpoint for network...")
    filename = fullfile(checkpointPath,getLatestFile(checkpointPath));
    if exist(filename,'file')
        load(filename);
        disp(['Loaded checkpoint from ', string(filename)]);
        net = layerGraph(net);
        networkStatus.trained = 0;
    else
        error(strcat({'Error: User specified: recoverCheckpoint = 1, '},...
                {'but no checkpoint found in '}, string(checkpointPath)));
    end
    clear filename
else
    if useCachedNet
        disp("Loading cached Network...")
        if ~exist(fullfile(cachePath,strcat('network','.mat')),'file')
           msg = 'No Network Cache found. What would you like to do?';
           title = 'Create New Network?';
           btn1 = 'Make new network';
           btn2 = 'Cancel';
           q = questdlg(msg, title, ...
                btn1, btn2, btn1);
            % Handle response
            switch q
                case btn1
                    useCachedNet=0;
                case btn2
                    clear q msg title btn1 btn2
                    error(['Error: No network cache found at: ',fullfile(cachePath,'network')])
            end
            clear q msg title btn1 btn2
        end
    end

    if (useCachedNet==false)
        disp("Setting up Network...")

        % Balance class weightings
        if (exist('labelWeights','var'))
            pxLayer = pixelClassificationLayer('Name','labels',...
                'Classes',labelNames,'ClassWeights',labelWeights);
        else
            pxLayer = pixelClassificationLayer('Name','labels',...
                'Classes',labelNames);
        end

        numClasses = numel(labelNames);

        switch network
            case 'fcn8s' % fully connected CNN, based on vgg16 weighting
                lgraph = fcnLayers(imageSize, numClasses);   
                lgraph = removeLayers(lgraph,'pixelLabels');
                lgraph = addLayers(lgraph, pxLayer);
                lgraph = connectLayers(lgraph,'softmax','labels');
                net = lgraph;
                
                clear lgraph

            case 'alexnet'
                net = alexnet;
                layers = net.Layers;

                % fc6 is layers 17
                idx = 17;
                weights = layers(idx).Weights';
                weights = reshape(weights, 6, 6, 256, 4096);
                bias = reshape(layers(idx).Bias, 1, 1, []);
                layers(idx) = convolution2dLayer(6, 4096, 'NumChannels', 256, 'Name', 'fc6');
                layers(idx).Weights = weights;
                layers(idx).Bias = bias;

                % fc7 is layers 20
                idx = 20;
                weights = layers(idx).Weights';
                weights = reshape(weights, 1, 1, 4096, 4096);
                bias = reshape(layers(idx).Bias, 1, 1, []);
                layers(idx) = convolution2dLayer(1, 4096, 'NumChannels', 4096, 'Name', 'fc7');
                layers(idx).Weights = weights;
                layers(idx).Bias = bias;

                conv1 = layers(2);
                conv1New = convolution2dLayer(conv1.FilterSize, conv1.NumFilters, ...
                    'Stride', conv1.Stride, ...
                    'Padding', [100 100], ...
                    'NumChannels', conv1.NumChannels, ...
                    'WeightLearnRateFactor', conv1.WeightLearnRateFactor, ...
                    'WeightL2Factor', conv1.WeightL2Factor, ...
                    'BiasLearnRateFactor', conv1.BiasLearnRateFactor, ...
                    'BiasL2Factor', conv1.BiasL2Factor, ...
                    'Name', conv1.Name);
                conv1New.Weights = conv1.Weights;
                conv1New.Bias = conv1.Bias;

                layers(2) = conv1New;
                layers(end-2:end) = [];

                upscore = transposedConv2dLayer(64, numClasses, ...
                    'NumChannels', numClasses,...
                    'Stride', 32,...
                    'Name', 'upscore');

                layers = [
                        layers
                        convolution2dLayer(1, numClasses, 'Name', 'score_fr');
                        upscore
                        crop2dLayer('centercrop', 'Name', 'score')
                        softmaxLayer('Name', 'softmax')
                        pxLayer
                        ];

                lgraph = layerGraph(layers);
                lgraph = connectLayers(lgraph, 'data', 'score/ref');
                net = lgraph;
                
                clear idx layers upscore bias weights upscore conv1New
                clear conv1 lgraph
                
            case 'deeplabv3'
                lgraph = helperDeeplabv3PlusResnet18([imageSize 3], numClasses);
                lgraph = replaceLayer(lgraph,"classification", pxLayer);
                net = lgraph;
                
                clear lgraph

            case 'segnet'
                lgraph = segnetLayers([imageSize 3], numClasses, 'vgg16');
                lgraph = replaceLayer(lgraph,"pixelLabels", pxLayer);
                net = lgraph;
                
                clear lgraph
                
            case 'u-net'
                lgraph = unetLayers([imageSize 3], numClasses);
                lgraph = replaceLayer(lgraph,"pixelLabels", pxLayer);
                net = lgraph;
                
                clear lgraph
                
                
            case 'vgg16'
                net = vgg16;
                layersTransfer = net.Layers(1:end-3);
                lgraph = [
                    layersTransfer
                    fullyConnectedLayer(numClasses, ...
                        'Name','fc_new', ...
                        'WeightLearnRateFactor',20,...
                        'BiasLearnRateFactor',20)
                    softmaxLayer('Name','prob')
                    pxLayer ];
                net = lgraph;
                
                clear layersTransfer lgraph
                    
            case 'googlenet'
                net = googlenet;
                lgraph = layerGraph(net);
                newLayer = fullyConnectedLayer(numClasses, ...
                    'Name','fc_new', ...
                    'WeightLearnRateFactor',10, ...
                    'BiasLearnRateFactor',10);       
                lgraph = replaceLayer(lgraph,'loss3-classifier',newLayer);
                lgraph = replaceLayer(lgraph,'output',pxLayer);
                net = lgraph;
                
                % freeze early network
                layers = lgraph.Layers;
                connections = lgraph.Connections;
                layers(1:10) = freezeWeights(layers(1:10));
                lgraph = createLgraphUsingConnections(layers,connections);
                net = lgraph;
                
                clear layers connections lgraph newLayer

            case 'inceptionresnetv2'
                net = inceptionresnetv2;
                lgraph = layerGraph(net);
                newLayer = fullyConnectedLayer(numClasses, ...
                    'Name','fc_new', ...
                    'WeightLearnRateFactor',10, ...
                    'BiasLearnRateFactor',10);       
                lgraph = replaceLayer(lgraph,...
                    'predictions',newLayer);
                lgraph = replaceLayer(lgraph, ...
                    'ClassificationLayer_predictions',pxLayer);
                
                % freeze pretrained network
                layers = lgraph.Layers;
                connections = lgraph.Connections;
                layers(1:end-3) = freezeWeights(layers(1:end-3));
                lgraph = createLgraphUsingConnections(layers,connections);
                net = lgraph;
                
                clear layers connections lgraph newLayer
 
            otherwise
                error('Error: Invalid network name specified')
        end

        clear pxLayer numClasses

        networkStatus.trained = 0;
        save(fullfile(cachePath,'network'),...
            'net','networkStatus','imageSize');
        disp("Network created") 

    else
        updatedNetName = networkStatus.name;
        load(fullfile(cachePath,'network'));
        disp('Loaded Network from cache...')
        
        networkStatus.name = updatedNetName;
        
        disp('Updating network name...')
        save(fullfile(cachePath,'network'),...
            'net','networkStatus','imageSize');
    end
end

diary off; diary on;

%% Training
if (doTraining==true) && (useCachedNet==true)
    net = layerGraph(net);
end

if (doTraining==true)
    disp("Setting up Training...")
    
    checkpointsFolder = fullfile(rootPath,'networks','checkpoints');
    close all;
    
    
    % Define training options.
%     ToDo: trainingDefaults? With individual overrides?
    options = trainingOptions('sgdm', ...
        'ExecutionEnvironment','auto', ...
        'DispatchInBackground', false, ...
        'MaxEpochs', 50, ...  
        'MiniBatchSize', 100, ...
        'Shuffle','every-epoch', ...
        'CheckpointPath', checkpointPath, ...
        'InitialLearnRate',1e-3, ... % from 1e-3
        'LearnRateSchedule','piecewise',...
        'LearnRateDropPeriod',10,...
        'LearnRateDropFactor',0.3,...
        'Momentum',0.9, ...
        'L2Regularization',0.005, ... % from 0.005
        'GradientThreshold', 10, ...
        'ValidationData',pximdsVal, ...
        'ValidationFrequency', 50,...
        'ValidationPatience', 6, ...
        'Verbose', 1, ...
        'VerboseFrequency',50,...
        'Plots','training-progress')

%     options = trainingOptions('adam', ...
%         'ExecutionEnvironment','auto', ... % 'WorkerLoad', 1, ...
%         'DispatchInBackground', true, ...
%         'MaxEpochs',30, ...
%         'MiniBatchSize',8, ...
%         'Shuffle','every-epoch', ...
%         'CheckpointPath', checkpointPath, ...
%         'LearnRateSchedule','piecewise',...
%         'LearnRateDropPeriod',10,...
%         'LearnRateDropFactor',0.3,...
%         'InitialLearnRate',1e-2, ...
%         'L2Regularization',0.001, ...
%         'GradientThreshold', 10, ...
%         'ValidationData',pximdsVal, ...
%         'ValidationFrequency', 50,...
%         'ValidationPatience', 6, ...
%         'Verbose', 1, ...
%         'VerboseFrequency',50,...
%         'Plots','training-progress')

    % Define augmenting methods
    pixelRange = [-32 32];
    scaleRange = [0.5 2.0];
    augmenter = imageDataAugmenter( ...
        'RandXReflection',true, ...
        'RandXTranslation',pixelRange, ...
        'RandYTranslation',pixelRange, ...
        'RandXScale',scaleRange, ...
        'RandYScale',scaleRange);

    pximds = pixelLabelImageDatastore(imdsTrain,pxdsTrain,...
        'DataAugmentation', augmenter);

    
    % shuffle the data
    pximds = pximds.shuffle;
    
    % Clear memory
%     reset(gpuDevice(1));
    clear numTestingImages numTrainingImages numValidationImages
    clear inputLayer convertData forceConvert partitionData
    clear recoverCheckpoint resplitValidation
    clear imdsTrain imdsVal pxdsTrain pxdsVal labelIDs labelIDs_scalar
    clear labelTable labelWeights network sequences
    clear maskFolders imageFolders resizedImageFolders resizedLabelFolders
    clear fingerprint newHash 
    clear pixelRange scaleRange 
    
    disp("Beginning training...")
    tic;
    [net, networkStatus.info] = trainNetwork(pximds, net, options);
    networkStatus.trainingTime = toc;
    
    networkStatus.trained = networkStatus.trained + 1;
    save(fullfile(cachePath,'network'),...
        'net','networkStatus','imageSize');
    disp("Network created") 
    
    % clear out checkpoints
    delete(fullfile(checkpointPath,'net_checkpoint_*.mat'));

else
    warning("Training skipped by user request")
end

diary off; diary on;

%% EVALUATION
if (networkStatus.trained && evaluateNet)
    disp("Evaluating network performance");
    
    testDir = fullfile('~/Documents/MATLAB/temp',networkStatus.name);
    if ~exist(testDir,'dir')
        mkdir(testDir)
    end
    
    pxdsResults = semanticseg(imdsTest,net, ...
        'MiniBatchSize',16, ...
        'WriteLocation',testDir, ...
        'Verbose',false);

    metrics = evaluateSemanticSegmentation(pxdsResults,pxdsTest,'Verbose',false);
    metrics.DataSetMetrics
    metrics.ClassMetrics
    
    save(fullfile(cachePath,'network'),...
        'net','networkStatus','metrics');
    disp("Network created") 
end

diary off; diary on;

%% ARCHIVE network, images, and matlab script
sendFileList = {''};
if (archiveNet)
   disp('Saving data, please wait...')
   currentFileName = strcat(mfilename('fullpath'),'.m');
   if exist(currentFileName,'file')
        foldername = fullfile(rootPath,"networks","cache",networkStatus.name);
        mkdir(foldername);
        copyfile(currentFileName, foldername);
        copyfile(fullfile(cachePath,'data.mat'),foldername);
        copyfile(fullfile(cachePath,'metadata.mat'),foldername);
        copyfile(fullfile(cachePath,'network.mat'),foldername);
        disp('Network and data archived')
        figHandle = findall(groot, 'Type', 'Figure');
        if saveImages && (numel(figHandle)>0)
            fig_name = figHandle.Name;
            fig_name(isspace(fig_name)==1)='_';
            fig_name = regexprep(fig_name, '[ .,''!?():]', '');
            fig_name = sprintf('%s.pdf',fig_name);
            fn = sprintf('%s/%s',foldername,fig_name);
            export_fig(fn,figHandle(1));
            fprintf("%d figures exported to %s\n",length(figHandle),foldername);
            sendFileList = strcat(sendFileList,{' --content-type="application/pdf" --attach="'},fn,{'"'});
            disp('Figure archived')
            close(figHandle(:));
        end
        
        diary off;
        copyfile(logFileFull,foldername);
        sendFileList = strcat(sendFileList, {' --content-type="text/plain" --attach="'},logFileFull,{'"'});
        disp('Log archived')
   else
       str = strcat(string(currentFileName), {' does not exist!'});
       warning(str);
       warning('Trained network not archived');
   end
else
    warning('Trained network not archived');
end

diary off;

%% NOTIFICATIONS

if sendNotification
    [hours, mins, secs] = sec2hms(networkStatus.trainingTime);
%     subject = strcat('ELEN4012 - Training for', {' '} , networkStatus.name, {' complete'});
    subject = strcat({'Training for '}, networkStatus.name, ...
        {' has completed at '}, ...
        datestr(datetime('now'),31), ...
        {'. Training time took '}, ...
        string(hours), {':'}, ...
        string(mins), {':'}, ...
        string(secs), {' (hh:mm:ss)'});
mail_str = strcat({'echo " " | mail -s "'}, subject, {'" '}, sendFileList, {' 1239448@students.wits.ac.za'});
    if ~(unix(char(mail_str)))
        disp('Notification sent')
    else
        warning('Warning: mail notification failed')
    end
end

return % end script
