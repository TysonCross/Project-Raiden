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
useCachedData       = 0         % if false, load and resize/process new data
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

logFile = fullfile(rootPath,'logs',strcat(networkStatus.name,'.log'))
diary(logFile)

%% DATA SETUP PHASE
disp("Setting up Data...")

% Check to see if cache exists
if useCachedData && ~exist(fullfile(cachePath,strcat('data','.mat')),'file')
    warning(['No data cache found at: ',fullfile(cachePath,'data'),newline, '(Data will be reloaded)'])
    useCachedData=0;
end

if (useCachedData==false)
    
    % Phase options
    showPixelFrequency = false;
    showTestImage = false;

    setupDataPaths;

    imds = imageDatastore(imageFolders,...
        'FileExtensions','.tif');
    pxds = pixelLabelDatastore(maskFolders,...
        labelNames,labelIDs,'FileExtensions','.tif');

    if (percentage<1)
        % Set initial random state
        rng(now); 
        numFiles = numel(imds.Files);
        shuffledIndices = randperm(numFiles);

        % Use smaller percentage of the images
        fileLimits = [3000 30000];
        numFiles = round(percentage * numFiles);
        numFiles = min(max(numFiles, min(fileLimits)),max(fileLimits));
        idx = shuffledIndices(1:numFiles);

        % Create reduced datastores
        imageFiles = imds.Files(idx);
        labelFiles = pxds.Files(idx);
        clear imds pxds
        imds = imageDatastore(imageFiles);
        pxds = pixelLabelDatastore(labelFiles, labelNames, labelIDs);
    end

    % Specify the class weights 
    % ToDo: This is slow! Can be made parallel?
    disp("Counting per-label pixel distribution...")
    labelTable = pxds.countEachLabel;
    imageFreq = labelTable.PixelCount ./ labelTable.ImagePixelCount;
    labelWeights = median(imageFreq) ./ imageFreq;
    dataStatus.weightLabels = 1;

    if showPixelFrequency
        % Visualize pixel frequency of labels
        frequency = labelTable.PixelCount/sum(labelTable.PixelCount); %#ok<*UNRCH>
        bar(1:numel(labelNames),frequency);
        xticks(1:numel(labelNames));
        xticklabels(labelTable.Name);
        xtickangle(45);
        ylabel('Frequency');
        clear frequency
        imageSize = net.Layers(1).InputSize(1:2);
    else
        disp(labelTable);
    end

    if showTestImage
        % View Overlay
        I = readimage(imds,100);
        I = histeq(I);
        C = readimage(pxds,100);
        cmap = jet(numel(labelNames));
        B = labeloverlay(I,C,'Colormap',cmap);
        figure(1)
        imshow(B)
        pixelLabelColorbar(cmap,labelNames);
        clear I B C
    end

    clear percentage numFiles idx fileLimits imageFiles labelFiles
    clear showTestImage showPixelFrequency shuffledIndices
    clear imagesFolders maskFolders labelTable
    
    dataStatus.categoricalLabels = 0;

    save(fullfile(cachePath,'data'),...
        'imds','pxds','dataStatus',...
        'labelNames', 'labelIDs','labelWeights');
    disp("Data cached") 
else
    load(fullfile(cachePath,'data'));
    clear percentage filename
    disp('Loaded Data from cache...')
end

%% NETWORK SETUP PHASE
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
        if (dataStatus.weightLabels==1)
            pxLayer = pixelClassificationLayer('Name','labels',...
                'Classes',labelNames,'ClassWeights',labelWeights);
        else
            pxLayer = pixelClassificationLayer('Name','labels');
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
 
%% Image Processing
if ( (useCachedData==false) || (dataStatus.categoricalLabels==0) )
    imagePath = fullfile(rootPath,'data');

    disp("Resizing images and labels, converting to categorical label form...")
    imds = resizeImages(imds, imageSize, imagePath);
    pxds = resizePixelLabels(pxds, imageSize, imagePath);
        
    clear percentage numFiles imagePath
    
    dataStatus.categoricalLabels = 1;

    % ToDo: overwrite images?
    save(fullfile(cachePath,'data'),...
        'imds','pxds','dataStatus',...
        'labelNames', 'labelIDs','labelWeights');
    disp("Data cached") 
else
    load(fullfile(cachePath,'data'));
    disp('Loaded Data from cache...')
end


%% Training
if (doTraining==true)
    disp("Setting up Training...")

    % Split into training and test 
    % ToDo: Partition Method non-random (sequential/split)
    % ToDo: Maove this stage into the the intial setupData script
    [imdsTrain, imdsVal, imdsTest, pxdsTrain, pxdsVal, pxdsTest] ...
        = partitionData(imds,pxds);
    numTrainingImages = numel(imdsTrain.Files) %#ok<NOPTS,NASGU>
    numValidationImages = numel(imdsVal.Files) %#ok<NOPTS,NASGU>
    numTestingImages = numel(imdsTest.Files) %#ok<NOPTS,NASGU>

    % Define validation data.
    pximdsVal = pixelLabelImageDatastore(imdsVal,pxdsVal);

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
        'ValidationData',pximdsVal, ...
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
    clear imds pxds imdsTrain pxdsTrain imdsVal pxdsVal
    clear numClasses numTestingImages numTrainingImages numValidationImages
    clear imageFreq classWeights inputLayer
    
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

%% ARCHIVE network, images, and matlab script
diary off

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

return % end script
% ToDo:  Cleanup and format below

%% SINGLE IMAGES TEST

% Single Images Check
imIdx = randperm(numel(imdsTest.Files),2); %randi(length(imdsTest.Files)); 
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