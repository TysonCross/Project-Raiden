clear all; clc;

setenv('NVIDIA_CUDNN', '/usr/local/cuda');
setenv('NVIDIA_TENSORRT', '/opt/TensorRT-5.1.2.2');
% results = coder.checkGpuInstall('full')

%% SETUP
rootPath = '/home/tyson/Raiden/';
%{
Network choices are:
'fcn8s'
 Description, pros, cons

'alexnet'
 Description, pros, cons

'vgg16' TBD (output layers not correct dimensions)
 Description, pros, cons

'googlenet' TBD (output layers not correct dimensions)
 Description, pros, cons

'inceptionresnetv2' SLOW to setup, TBD (output layers not correct dimensions)
 Description, pros, const
%}
network = 'fcn8s';

% Percent of data to train with (0-1)
percentage = 0.3;

% Per-stage options
showPixelFrequency = false;
showTestImage = false;
saveNet = true;
saveImages = true;

% global setup
setupColors;


%% DATA
disp("Setting up Data...")

setupDataPaths;

imds = imageDatastore(imageFolders,...
    'FileExtensions','.tif');
pxds = pixelLabelDatastore(maskFolders,...
    classNames,labelIDs,'FileExtensions','.tif');

% Set initial random state
rng(now); 
numFiles = numel(imds.Files);
shuffledIndices = randperm(numFiles);

% Use smaller percentage of the images
% fileLimit = 4000;
% N = max(min(round(percentage * numFiles),fileLimit),fileLimit);
N = round(percentage * numFiles);
idx = shuffledIndices(1:N);

% Create reduced datastores
imageFiles = imds.Files(idx);
labelFiles = pxds.Files(idx);
clear imds pxds
imds = imageDatastore(imageFiles);
pxds = pixelLabelDatastore(labelFiles, classNames, labelIDs);

% Specify the class weights 
% ToDo: This is slow! Can be made parallel?
disp("Counting per-label pixel distribution...")
labelTable = pxds.countEachLabel

if showPixelFrequency
    % Visualize pixel frequency of labels
    frequency = labelTable.PixelCount/sum(labelTable.PixelCount);
    bar(1:numel(classNames),frequency)
    xticks(1:numel(classNames)) 
    xticklabels(labelTable.Name)
    xtickangle(45)
    ylabel('Frequency')
    clear frequency
else
    disp(labelTable);
end
    
if showTestImage
    % View Overlay
    I = readimage(imds,100);
    I = histeq(I);
    C = readimage(pxds,100);
    cmap = jet(numel(classNames));
    B = labeloverlay(I,C,'Colormap',cmap);
    figure(1)
    imshow(B)
    pixelLabelColorbar(cmap,classNames);
    clear I B C
end

clear percentage N idx

%% Network setup
disp("Setting up Network...")

% Balance class weightings
imageFreq = labelTable.PixelCount ./ labelTable.ImagePixelCount;
classWeights = median(imageFreq) ./ imageFreq;
pxLayer = pixelClassificationLayer('Name','labels','Classes',...
    labelTable.Name,'ClassWeights',classWeights);
numClasses = numel(classNames);

switch network
    case 'fcn8s' % fully connected CNN, based on vgg16
        sz = [227 227];
        lgraph = fcnLayers(sz, numClasses);   
        lgraph = removeLayers(lgraph,'pixelLabels');
        lgraph = addLayers(lgraph, pxLayer);
        lgraph = connectLayers(lgraph,'softmax','labels');
        
%         % freeze pretrained network
%         layers = lgraph.Layers;
%         connections = lgraph.Connections;
%         layers(1:end-3) = freezeWeights(layers(1:end-3));
%         lgraph = createLgraphUsingConnections(layers,connections);
        
    case 'alexnet'
        sz = [227 227];
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
      
        clear layers upscore
        
    case 'vgg16'
        sz = [224 224];
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
        clear layersTransfer

    case 'googlenet'
        sz = [224 224];
        net = googlenet;
        lgraph = layerGraph(net);
        newLayer = fullyConnectedLayer(numClasses, ...
            'Name','fc_new', ...
            'WeightLearnRateFactor',10, ...
            'BiasLearnRateFactor',10);       
        lgraph = replaceLayer(lgraph,'loss3-classifier',newLayer);
        lgraph = replaceLayer(lgraph,'output',pxLayer);
        clear newLayer
        
        % freeze early network
        layers = lgraph.Layers;
        connections = lgraph.Connections;
        layers(1:10) = freezeWeights(layers(1:10));
        lgraph = createLgraphUsingConnections(layers,connections);
        clear layers connections

    case 'inceptionresnetv2'
        sz = [299 299];
        net = inceptionresnetv2;
        lgraph = layerGraph(net);
        newLayer = fullyConnectedLayer(numClasses, ...
            'Name','fc_new', ...
            'WeightLearnRateFactor',10, ...
            'BiasLearnRateFactor',10);       
        lgraph = replaceLayer(lgraph,'predictions',newLayer);
        lgraph = replaceLayer(lgraph,'ClassificationLayer_predictions',pxLayer);
        clear newLayer
        
        % freeze pretrained network
        layers = lgraph.Layers;
        connections = lgraph.Connections;
        layers(1:end-3) = freezeWeights(layers(1:end-3));
        lgraph = createLgraphUsingConnections(layers,connections);
        clear layers connections
    
    otherwise
        disp('No network specified! Script stopped.')
    return
end

clear pxLayer
% analyzeNetwork(net)
% analyzeNetwork(lgraph)

%% Image Processing
imageSize = sz;
imagePath = fullfile(rootPath,'data');

disp("Resizing images and labels, converting to categorical label form...")
imds = resizeImages(imds, sz, imagePath);
pxds = resizePixelLabels(pxds, sz, imagePath);

%% Training
disp("Setting up Training...")

% Split into training and test 
% ToDo: Partition Method non-random (sequential/split)
[imdsTrain, imdsVal, imdsTest, pxdsTrain, pxdsVal, pxdsTest] ...
    = partitionData(imds,pxds);

numTrainingImages = numel(imdsTrain.Files)
numValidationImages = numel(imdsVal.Files)
numTestingImages = numel(imdsTest.Files)

% Define validation data.
pximdsVal = pixelLabelImageDatastore(imdsVal,pxdsVal);

checkpointsFolder = fullfile(rootPath,'networks','checkpoints');

% Define training options. 
options = trainingOptions('sgdm', ...
    'LearnRateSchedule','piecewise',...
    'LearnRateDropPeriod',10,...
    'LearnRateDropFactor',0.3,...
    'Momentum',0.9, ...
    'InitialLearnRate',1e-3, ...
    'L2Regularization',0.005, ...
    'GradientThreshold', 6, ...
    'ValidationData',pximdsVal, ...
    'MaxEpochs',30, ...  
    'MiniBatchSize',20, ...
    'Shuffle','never', ...
    'CheckpointPath', tempdir, ...
    'VerboseFrequency',10,...
    'Plots','training-progress',...
    'ValidationFrequency', 50,...
    'ValidationPatience', 4);

% Define training data
pixelRange = [-20 20];
scaleRange = [0.9 1.1];
augmenter = imageDataAugmenter( ...
    'RandXReflection',true, ...
    'RandXTranslation',pixelRange, ...
    'RandYTranslation',pixelRange, ...
    'RandXScale',scaleRange, ...
    'RandYScale',scaleRange);

pximds = pixelLabelImageDatastore(imdsTrain,pxdsTrain,...
    'DataAugmentation',augmenter);

% Clear memory
clear imds pxds imdsTrain pxdsTrain imdsVal pxdsVal
clear numClasses numTestingImages numTrainingImages numValidationImages
clear imageFreq classWeights inputLayer

doTraining = true;
if doTraining    
    [net, info] = trainNetwork(pximds,lgraph,options);
end

%% SAVE network. images, and matlab script

if (saveNet)
   disp('Copying data, please wait...')
   currentFileName = strcat(mfilename('fullpath'),'.m');
   if exist(currentFileName,'file')
        str = strrep(strrep(datestr(datetime('now'),31), ' ', '_'), ':', '');
        foldername = fullfile(rootPath,"networks","cache",str);
        mkdir(foldername);
        save(fullfile(foldername,strcat(network,'_',str,'.mat')),'net');
        copyfile(currentFileName, foldername);

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
       fprintf('WARNING: %s does not exist!\n',currentFileName);
       disp("WARNING: trained network not archived")
   end
else
    disp("WARNING: trained network not archived")
end

%% SINGLE IMAGES TEST

% Single Images Check
imIdx = randperm(numel(imdsTest.Files),2); %randi(length(imdsTest.Files)); 
figure(1)
for i = 1:2
    subplot(2,2,i)
    [I,info] = readimage(imdsTest,imIdx(i));
    C = semanticseg(I, net);
    B = labeloverlay(I,C,'Colormap',cmap,'Transparency',0.4);
    imshow(B)
    pixelLabelColorbar(cmap, classNames);
    [~, filename, ext] = fileparts(info.Filename)
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

%% EVALUATION
tempdir = '~/Documents/MATLAB/temp';

pxdsResults = semanticseg(imdsTest,net, ...
    'MiniBatchSize',8, ...
    'WriteLocation',tempdir, ...
    'Verbose',false);

metrics = evaluateSemanticSegmentation(pxdsResults,pxdsTest,'Verbose',false);
metrics.DataSetMetrics
metrics.ClassMetrics


