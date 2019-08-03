clear all; clc; close all; %#ok<CLALL>

setenv('NVIDIA_CUDNN', '/usr/local/cuda');
setenv('NVIDIA_TENSORRT', '/opt/TensorRT-5.1.2.2');
% results = coder.checkGpuInstall('full')

%% SETUP
network = 'alexnet';
%{
    Network choices are:
    'fcn8s'
    'alexnet'
    'vgg16' TBD (output not correct dimension)
    'googlenet' TBD (output not correct dimension)
    'inceptionresnetv2' SLOW to setup, TBD (output not correct dimension)
%}

% Percent of data to train with (0-1)
percentage = 1.0;

% Phases to run
forceConvert        = 0         % if true, resize/process new data (slow)
partitionData       = 1         % if true, re-split Test/Training (warning)
resplitValidation   = 1         % if true, re-split Training/Validation
useCachedNet        = 0         % if false, generate new neural network
doTraining         	= 1         % if true, perform training
recoverCheckpoint   = 0         % if training did not finish, use checkpoint
archiveNet          = 1         % archive NN, data and figures to subfolder
saveImages          = 1         % generate performance figures
sendNotification    = 1         % send PushBullet notification on completion

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
    
logFile = fullfile(rootPath,'logs',strcat(networkStatus.name,'.log'))
diary(logFile)

%% Data Conversion Phase 

% This process is slow. Although there are several checks to determine
% if any source files (tifs or mask images) must be reconverted,
% this should ideally be a once off conversion. If a file exists on disk
% in the destination resized/converted folder, it will not be reconverted.

if (forceConvert==false)
    disp('Checking sequences...')
    % hashCheck:
    if (exist(fullfile(rootPath,'data','resized',rez,'fingerprint.mat'),'file')) ...
         
        loadLabels;
        loadSequences;
        newHash = mlreportgen.utils.hash(strcat(sequences{:},network,rez));
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
    
    resolutionList = {
        [227 227]; ...
%         [224 224]; ...
%         [299 299]; ...
        };
    
    % create default datastores
    loadLabels;
    parfor i = 1:numel(imageFolders)
        imds{i} = imageDatastore(imageFolders(i),...
            'FileExtensions','.tif');
        pxds{i} = pixelLabelDatastore(maskFolders(i),...
            labelNames,labelIDs,'FileExtensions','.tif');
    end
    
    disp("Resizing images and labels, converting to categorical label form...")   
    for i = 1:numel(resolutionList)
        sz = resolutionList{i};
        y = sz(1);
        x = sz(2);
        rez = strcat(string(x),'x',string(y));
        str = char(strcat('Resizing images to ',{' '},rez));
        progressbar('Resizing image sequences',str)
        for j = 1:numel(imageFolders)
            % [Convert all 'tifs' to imageSize]
            imds{j} = resizeImages(imds{j}, sz, resizedImageFolders{j});
            progressbar(j/numel(imageFolders),[])
        end
        str = char(strcat('Converting labels to ',{' '},rez));
        progressbar('Resizing and converting label sequences',str)
        for j = 1:numel(imageFolders)
            % [Convert all 'mask' to imageSize, and RGB -> categorical]
            pxds{j} = resizePixelLabels(pxds{j}, sz, resizedLabelFolders{j});
            progressbar(j/numel(imageFolders),[])
        end
    end
     progressbar(1)
    
    converted = listConvertedSequences(rootPath, imageSize);
    if numel(converted)~=numel(sequences)
        disp('Conversion failed for sequences:');
        disp(setdiff(sequences,converted));
        error('Conversion failed');
    else
        disp("Data converted successfully")
        fingerprint = mlreportgen.utils.hash(strcat(converted{:},network,rez));
        save(fullfile(rootPath,'data','resized',rez,'fingerprint'),'fingerprint');
    end
    
    clear imds pxds resolutionList fingerprint newHash 
    clear imageFolders maskFolders forceConvert convertData

    save(fullfile(cachePath,'metadata'), ...
    'resizedImageFolders','resizedLabelFolders', ...
    'labelIDs','labelIDs_scalar','labelNames', ...
    'sequences','rez');
    disp("Datapaths cached") 
else
    load(fullfile(cachePath,'metadata'));
    disp('Loaded Data from cache...')
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
    disp("Partitioning Test and Training Data...")

    % [split training and test]
    splitPercent = 0.25;
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
    
%     % Find errant files:
%     for i=1:max(numel(imdsTrain.Files),numel(pxdsTrain.Files))
%         str1=string(imdsTrain.Files{i});
%         str2 = string(strrep(pxdsTrain.Files{i},'_label',''));
%         if extractBetween(str1,strlength(str1)-33,strlength(str1))~=...
%                 extractBetween(str2,strlength(str2)-33,strlength(str2))
%             disp(imdsTrain.Files{i});
%             disp(pxdsTrain.Files{i});
%             break
%         end
%     end

    % Specify the class weights 
    disp("Counting per-label pixel distribution...")  % ToDo: This is slow!
    labelTable = pxdsTrain.countEachLabel;
    imageFreq = labelTable.PixelCount ./ labelTable.ImagePixelCount;
    labelWeights = median(imageFreq) ./ imageFreq;
    disp(labelTable);

    clear trainIndex testIndex

    save(fullfile(cachePath,'data'), ...
    'imdsTrain','pxdsTrain', ...
    'imdsTest','pxdsTest', ...
    'labelWeights');
    disp("Datastores cached") 
else
    load(fullfile(cachePath,'data'));
    disp('Loaded datastores from cache...')
    disp(labelTable);
end

diary off; diary on;

%% Training partition phase 

if (resplitValidation==false)
    disp("Splitting training/validation data...")

   clear numFiles imagePath imageFreq labelTable
    
    % Split training and validation
    [imdsTrain, imdsVal, pxdsTrain, pxdsVal] = ...
        partitionTrainingData(imdsTrain, pxdsTrain);

    assert(numel(imdsTrain.Files)==numel(pxdsTrain.Files));
    assert(numel(imdsVal.Files)==numel(pxdsVal.Files));
    
    fprintf('Training images: %d \n', numel(imdsTrain.Files));
    fprintf('Validation images: %d \n', numel(imdsVal.Files));
    fprintf('Testing images: %d \n', numel(imdsTest.Files));
        
    save(fullfile(cachePath,'data'), ...
        'imdsTrain', 'imdsVal', 'imdsTest', ...
        'pxdsTrain', 'pxdsVal', 'pxdsTest', ...
        'labelWeights');
    disp("Data cached") 
else
    load(fullfile(cachePath,'data'));
    clear percentage filename
    disp('Using training/validation split from cache...')
end

diary off; diary on;

%% Network setup phase

disp("Setting up Network...")
if recoverCheckpoint
    filename = fullfile(checkpointPath,getLatestFile(checkpointPath));
    if exist(filename,'file')
        load(filename);
        disp(['Loaded checkpoint from ', string(filename)]);
    else
        error(strcat({'Error: User specified: recoverCheckpoint = 1, '},...
                {'but no checkpoint found in '}, string(checkpointPath)));
    end
    clear filename
else
    if useCachedNet
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
                imageSize = [227 227];
                lgraph = fcnLayers(imageSize, numClasses);   
                lgraph = removeLayers(lgraph,'pixelLabels');
                lgraph = addLayers(lgraph, pxLayer);
                lgraph = connectLayers(lgraph,'softmax','labels');
                net = lgraph;
                
                clear lgraph

            case 'alexnet'
                imageSize = [227 227];
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
                
                clear idx layers upscore bias weights upscore conv1New\
                clear conv1 lgraph

            case 'vgg16'
                imageSize = [224 224];
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
                imageSize = [224 224];
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
                imageSize = [299 299];
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

        clear pxLayer numClasses useCachedNet

        % ToDo: lgraph -> net
        networkStatus.trained = 0;
        save(fullfile(cachePath,'network'),...
            'net','networkStatus','imageSize');
        disp("Network created") 

    else
        load(fullfile(cachePath,'network'));
        disp('Loaded Network from cache...')
    end
end

diary off; diary on;

%% Training

if (doTraining==true)
    disp("Setting up Training...")
    
    checkpointsFolder = fullfile(rootPath,'networks','checkpoints');

    % Define training options.
    % ToDo: trainingDefaults? With individual overrides?
    options = trainingOptions('sgdm', ...
        'LearnRateSchedule','piecewise',...
        'LearnRateDropPeriod',10,...
        'LearnRateDropFactor',0.3,...
        'Momentum',0.9, ...
        'InitialLearnRate',1e-2, ... % from 1e-3
        'L2Regularization',0.001, ... % from 0.005  %'GradientThreshold', 6, ...
        'ValidationData',pxdsVal, ...
        'MaxEpochs',40, ...  
        'MiniBatchSize',100, ...
        'Shuffle','every-epoch', ...
        'CheckpointPath', checkpointPath, ...
        'VerboseFrequency',50,...
        'Plots','training-progress',...
        'ValidationFrequency', 100,...
        'ValidationPatience', 6);

    % Define augmenting methods
    pixelRange = [-20 20];
    scaleRange = [0.9 1.1];
    augmenter = imageDataAugmenter( ...
        'RandXReflection',true, ...
        'RandXTranslation',pixelRange, ...
        'RandYTranslation',pixelRange, ...
        'RandXScale',scaleRange, ...
        'RandYScale',scaleRange);

    pximds = pixelLabelImageDatastore(imdsTrain,pxdsTrain,...
        'DataAugmentation', augmenter);

    % Clear memory
    clear numClasses numTestingImages numTrainingImages numValidationImages
    clear inputLayer
    
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
if networkStatus.trained
    disp("Evaluating network performance");
    
    testDir = '~/Documents/MATLAB/temp';

    pxdsResults = semanticseg(imdsTest,net, ...
        'MiniBatchSize',16, ...
        'WriteLocation',tempdir, ...
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

if (archiveNet)
   disp('Saving data, please wait...')
   currentFileName = strcat(mfilename('fullpath'),'.m');
   if exist(currentFileName,'file')
        foldername = fullfile(rootPath,"networks","cache",networkStatus.name);
        mkdir(foldername);
        copyfile(currentFileName, foldername);
        copyfile(fullfile(cachePath,'data.mat'),foldername);
        copyfile(fullfile(cachePath,'network.mat'),foldername);
        copy(logFile,foldername);
        
        if saveImages
            figHandle = findall(groot, 'Type', 'Figure');
            fig_name = figHandle(1).Name;
            fig_name(isspace(fig_name)==1)='_';
            fig_name = regexprep(fig_name, '[ .,''!?():]', '');
            fn = sprintf('%s/%s.pdf',foldername,fig_name);
            export_fig(fn,figHandle(1));
            fprintf("%d figures exported to %s\n",length(figHandle),foldername);
            close all;
        end
   else
       str = strcat(string(currentFileName), {' does not exist!'});
       warning(str);
       warning('Trained network not archived');
   end
else
    warning('Trained network not archived');
end

% NOTIFICATIONS
if sendNotification
    % Send notification when done:
    apiKey = 'o.iU7I4FP6qJmjML6GOW6WL49iTM5Zvjf5';
    p = Pushbullet(apiKey);
    str = strcat(strrep(strrep(datestr(datetime('now'),31),...
        ' ', '_'), ':', ''),'_',network);
    [hours, mins, secs] = sec2hms(networkStatus.trainingTime);
    subject = strcat('Training for', {' '} , network, {' complete'});
    msg = strcat('Training for', {' '} , network, ...
        {' has completed at '}, ...
        datestr(datetime('now'),31), {' after '}, ...
        string(hours), {' h '}, ...
        string(mins), {' min '}, ...
        string(secs), {' sec'});
    p.pushNote([],subject,msg);
end

diary off;
return % end script
% ToDo:  Cleanup and format below

%% SINGLE IMAGES TEST

% Single Images Check
imIdx = randperm(numel(imdsTest.Files),2); %#ok<*UNRCH> %randi(length(imdsTest.Files)); 
figure(1)
for i = 1:2
    subplot(2,2,i)
    [I,info] = readimage(imdsTest,imIdx(i));
    C = semanticseg(I, net);
    B = labeloverlay(I,C,'Colormap',cmap,'Transparency',0.4);
    imshow(B);
    pixelLabelColorbar(cmap, labelNames);
    [~, filename, ext] = fileparts(info.Filename);
    title(filename,'Interpreter','none','FontSize',6);
end
for i = 3:4
    subplot(2,2,i)
    [I,info] = readimage(imdsTest,imIdx(i-2));
    C = semanticseg(I, net);
    expectedResult = readimage(pxdsTest,imIdx(i-2));
    actual = uint8(C);
    expected = uint8(expectedResult);
    imshowpair(actual, expected, 'diff')
    title('Actual vs Expected');
end

%% Visualize activations

im = readimage(imdsTest,randi(length(imdsTest.Files)));

act1 = activations(net,im,'conv3');
sz1 = size(act1);
act1 = reshape(act1,[sz1(1) sz1(2) 1 sz1(3)]);
I = imtile(mat2gray(act1),'GridSize',[8 12]);
imshow(I)

act1ch32 = act1(:,:,:,32);
act1ch32 = mat2gray(act1ch32);
act1ch32 = imresize(act1ch32,imageSize);

I = imtile({im,act1ch32});
imshow(I)

% clear GPU
reset(gpuDevice(1));