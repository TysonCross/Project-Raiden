clear all; clc;

setenv('NVIDIA_CUDNN', '/usr/local/cuda');
setenv('NVIDIA_TENSORRT', '/opt/TensorRT-5.1.2.2');
% results = coder.checkGpuInstall('full')

%% TEMP
rootPath = '/home/tyson/Raiden/';

%% DATA
disp("Setting up Data...")

% classNames = [
%     "lightning" , ...  % "leader" "stroke" "channel"  
%     "sky"       , ...  % "sky" "cloud"
%     "ground"    , ...
%     ];
% 
% labelIDs = {... 
%     % "lightning"
%     [ 
%     255 000 000;...    % leader
%     255 255 255;...    % stroke
%     255 255 000;...    % channel
%     ]  
%     % "sky"
%     [
%     000 255 255;...    % cloud
%     000 000 255;...    % sky
%     ]
%     % "ground"
%     [
%     000 255 000;...    % ground
%     ]
% };

classNames = [
    "leader" , ...
    "stroke" , ...
    "channel", ...  
    "cloud"    , ...
    "sky"  , ...
    "ground"
    ];

labelIDs = [... 
    255 000 000;...    % leader
    255 255 255;...    % stroke
    255 255 000;...    % channel
    000 255 255;...    % cloud
    000 000 255;...    % sky
    000 255 000;...    % ground
    ];

% sequences = {...
%    {'/2017-02-10_162903/2017-02-10_162903_010'};...
%    {'/2017-02-10_163357/2017-02-10_163357_010'};...
%    {'/2017-02-10_163553/2017-02-10_163553_010';...
%     '/2017-02-10_163553/2017-02-10_163553_020';...
%     '/2017-02-10_163553/2017-02-10_163553_030';...
%     '/2017-02-10_163553/2017-02-10_163553_040';...
%     '/2017-02-10_163553/2017-02-10_163553_050';...
%     '/2017-02-10_163553/2017-02-10_163553_060';...
%     '/2017-02-10_163553/2017-02-10_163553_070';...
%     '/2017-02-10_163553/2017-02-10_163553_080';...
%     '/2017-02-10_163553/2017-02-10_163553_090';...
%     '/2017-02-10_163553/2017-02-10_163553_100';...
%     '/2017-02-10_163553/2017-02-10_163553_110';...
%     '/2017-02-10_163553/2017-02-10_163553_120';...
%     '/2017-02-10_163553/2017-02-10_163553_130';...
%     '/2017-02-10_163553/2017-02-10_163553_140';...
%     '/2017-02-10_163553/2017-02-10_163553_150';...
%     '/2017-02-10_163553/2017-02-10_163553_160';...
%     '/2017-02-10_163553/2017-02-10_163553_170';...
%     '/2017-02-10_163553/2017-02-10_163553_180';...
%     '/2017-02-10_163553/2017-02-10_163553_190';...
%     '/2017-02-10_163553/2017-02-10_163553_200';...
%     '/2017-02-10_163553/2017-02-10_163553_210';...
%     '/2017-02-10_163553/2017-02-10_163553_220';...
%     '/2017-02-10_163553/2017-02-10_163553_230';...
%     '/2017-02-10_163553/2017-02-10_163553_240';...
%     '/2017-02-10_163553/2017-02-10_163553_250';...
%     '/2017-02-10_163553/2017-02-10_163553_260'};...
%    {'/2017-02-10_163907/2017-02-10_163907_010';...
%     '/2017-02-10_163907/2017-02-10_163907_020';...
%     '/2017-02-10_163907/2017-02-10_163907_030';...
%     '/2017-02-10_163907/2017-02-10_163907_040';...
%     '/2017-02-10_163907/2017-02-10_163907_050';...
%     '/2017-02-10_163907/2017-02-10_163907_060'};...
%    {'/2017-02-10_163916/2017-02-10_163916_010';...
%     '/2017-02-10_163916/2017-02-10_163916_020'};...
%    {'/2017-02-10_164114/2017-02-10_164114_010';...
%     '/2017-02-10_164114/2017-02-10_164114_020';...
%     '/2017-02-10_164114/2017-02-10_164114_030';...
%     '/2017-02-10_164114/2017-02-10_164114_040';...
%     '/2017-02-10_164114/2017-02-10_164114_050';...
%     '/2017-02-10_164114/2017-02-10_164114_060';...
%     '/2017-02-10_164114/2017-02-10_164114_070';...
%     '/2017-02-10_164114/2017-02-10_164114_080';...
%     '/2017-02-10_164114/2017-02-10_164114_090';...
%     '/2017-02-10_164141/2017-02-10_164141_010'}
%     };

% sequences = {...
%     '/2017-02-10_162903/2017-02-10_162903_010';...
%     '/2017-02-10_163357/2017-02-10_163357_010';...
%     '/2017-02-10_163553/2017-02-10_163553_010';...
%     '/2017-02-10_163553/2017-02-10_163553_020';...
%     '/2017-02-10_163553/2017-02-10_163553_030';...
%     '/2017-02-10_163553/2017-02-10_163553_040';...
%     '/2017-02-10_163553/2017-02-10_163553_050';...
%     '/2017-02-10_163553/2017-02-10_163553_060';...
%     '/2017-02-10_163553/2017-02-10_163553_070';...
%     '/2017-02-10_163553/2017-02-10_163553_080';...
%     '/2017-02-10_163553/2017-02-10_163553_090';...
%     '/2017-02-10_163553/2017-02-10_163553_100';...
%     '/2017-02-10_163553/2017-02-10_163553_110';...
%     '/2017-02-10_163553/2017-02-10_163553_120';...
%     '/2017-02-10_163553/2017-02-10_163553_130';...
%     '/2017-02-10_163553/2017-02-10_163553_140';...
%     '/2017-02-10_163553/2017-02-10_163553_150';...
%     '/2017-02-10_163553/2017-02-10_163553_160';...
%     '/2017-02-10_163553/2017-02-10_163553_170';...
%     '/2017-02-10_163553/2017-02-10_163553_180';...
%     '/2017-02-10_163553/2017-02-10_163553_190';...
%     '/2017-02-10_163553/2017-02-10_163553_200';...
%     '/2017-02-10_163553/2017-02-10_163553_210';...
%     '/2017-02-10_163553/2017-02-10_163553_220';...
%     '/2017-02-10_163553/2017-02-10_163553_230';...
%     '/2017-02-10_163553/2017-02-10_163553_240';...
%     '/2017-02-10_163553/2017-02-10_163553_250';...
%     '/2017-02-10_163553/2017-02-10_163553_260';...
%     '/2017-02-10_163907/2017-02-10_163907_010';...
%     '/2017-02-10_163907/2017-02-10_163907_020';...
%     '/2017-02-10_163907/2017-02-10_163907_030';...
%     '/2017-02-10_163907/2017-02-10_163907_040';...
%     '/2017-02-10_163907/2017-02-10_163907_050';...
%     '/2017-02-10_163907/2017-02-10_163907_060';...
%     '/2017-02-10_163916/2017-02-10_163916_010';...
%     '/2017-02-10_163916/2017-02-10_163916_020';...
%     '/2017-02-10_164114/2017-02-10_164114_010';...
%     '/2017-02-10_164114/2017-02-10_164114_020';...
%     '/2017-02-10_164114/2017-02-10_164114_030';...
%     '/2017-02-10_164114/2017-02-10_164114_040';...
%     '/2017-02-10_164114/2017-02-10_164114_050';...
%     '/2017-02-10_164114/2017-02-10_164114_060';...
%     '/2017-02-10_164114/2017-02-10_164114_070';...
%     '/2017-02-10_164114/2017-02-10_164114_080';...
%     '/2017-02-10_164114/2017-02-10_164114_090';...
%     '/2017-02-10_164141/2017-02-10_164141_010';...
%     };

sequences = {...
    '/2017-02-10_162903/2017-02-10_162903_010';...
    '/2017-02-10_163357/2017-02-10_163357_010';...
    '/2017-02-10_163553/2017-02-10_163553_010';...
    '/2017-02-10_163553/2017-02-10_163553_020';...
    '/2017-02-10_163553/2017-02-10_163553_030';...
    '/2017-02-10_163553/2017-02-10_163553_040';...
    '/2017-02-10_163553/2017-02-10_163553_050';...
    };

sequencesPath = '/mnt/Shield/Raiden/data/sequences';
imageFolders = fullfile(sequencesPath,sequences,'tif',filesep);
maskFolders = fullfile(sequencesPath,sequences,'mask',filesep);

imds = imageDatastore(imageFolders,... %'ReadFcn',@readDatastoreGray,...
    'FileExtensions','.tif');
pxds = pixelLabelDatastore(maskFolders,...
    classNames,labelIDs,'FileExtensions','.tif');

% Overlay colors
cmap = [
    000 000 128;...    % leader
    128 128 128;...    % stroke
    128 128 000;...    % channel
    128 128 000;...    % cloud
    128 000 000 ;...    % sky
    000 128 000;...    % ground
    ];

% Normalize between [0 1].
cmap = cmap ./ 255;
    
showTestImage = false;
if showTestImage
   
    % View Overlay
    I = readimage(imds,100);
    I = histeq(I);
    C = readimage(pxds,100);
    cmap = jet(numel(classNames));
    B = labeloverlay(I,C,'Colormap',cmap);
    figure
    imshow(B)
    pixelLabelColorbar(cmap,classNames);
end

% Specify the class weights 
% ToDo: This is slow! Can be made parallel?
disp("Counting per-label pixel distribution...")
tbl = countEachLabel(pxds);

showPixelFrequency = false;
if showPixelFrequency
    % Visualize pixel frequency of labels
    frequency = tbl.PixelCount/sum(tbl.PixelCount); %#ok<*UNRCH>
    bar(1:numel(classNames),frequency)
    xticks(1:numel(classNames)) 
    xticklabels(tbl.Name)
    xtickangle(45)
    ylabel('Frequency')
else
    disp(tbl);
end

%% Image processing (resize, filtering, etc)
sz = [227 227];
imagePath = fullfile(rootPath,'data');

disp("Resizing images and labels, converting to categorical label form...")
imds = resizeImages(imds, sz, imagePath);
pxds = resizePixelLabels(pxds, sz, imagePath);

% disp("Converting to categorical label form...")
% labelFolders = fullfile(sequencesPath,sequences,'label');
% pxds = convertCategorical(pxds, labelFolders);

%% NETWORK
disp("Setting up Network...")
imageSize = sz;
numClasses = numel(classNames);
lgraph = fcnLayers(imageSize, numClasses);    % Create vgg16

imageFreq = tbl.PixelCount ./ tbl.ImagePixelCount;
classWeights = median(imageFreq) ./ imageFreq;

pxLayer = pixelClassificationLayer('Name','labels','Classes',...
    tbl.Name,'ClassWeights',classWeights);
lgraph = removeLayers(lgraph,'pixelLabels');
lgraph = addLayers(lgraph, pxLayer);
lgraph = connectLayers(lgraph,'softmax','labels');

%% TRAINING
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

pretrainedFolder = fullfile(rootPath,'networks','pretrained');
% ToDo: Add additional network options
pretrainedNetwork = fullfile(pretrainedFolder,'FCN8s.mat'); 

checkpointsFolder = fullfile(rootPath,'networks','checkpoints');

% Define training options. 
% options = trainingOptions('adam', ...
%     'InitialLearnRate',1e-3, ...
%     'MaxEpochs',30, ...  
%     'MiniBatchSize',2, ...
%     'ValidationData',pximdsVal, ...
%     'Shuffle','every-epoch', ...
%     'CheckpointPath', checkpointsFolder, ...
%     'Plots','training-progress',...
%     'VerboseFrequency',2);

options = trainingOptions('sgdm', ...
    'LearnRateSchedule','piecewise',...
    'LearnRateDropPeriod',10,...
    'LearnRateDropFactor',0.3,...
    'Momentum',0.9, ...
    'InitialLearnRate',1e-3, ...
    'L2Regularization',0.005, ...
    'ValidationData',pximdsVal,...
    'MaxEpochs',30, ...  
    'MiniBatchSize',4, ...
    'Shuffle','never', ...
    'CheckpointPath', tempdir, ...
    'VerboseFrequency',2,...
    'Plots','training-progress',...
    'ValidationPatience', 4);

% Define training data
augmenter = imageDataAugmenter('RandXReflection',true,...
    'RandXTranslation',[-10 10],'RandYTranslation',[-10 10]);

pximds = pixelLabelImageDatastore(imdsTrain,pxdsTrain,...
    'DataAugmentation',augmenter);

doTraining = true;
if doTraining    
    [net, info] = trainNetwork(pximds,lgraph,options);
    save('FCN8s_new.mat','net');
else
    data = load(pretrainedNetwork); 
    net = data.net;
end

%% SINGLE IMAGE TEST

% single Image
imNum = randi(length(imdsTest.Files));
figure(1)
[I,info] = readimage(imdsTest,imNum);
info.Filename
C = semanticseg(I, net);
B = labeloverlay(I,C,'Colormap',cmap,'Transparency',0.4);
imshow(B)
pixelLabelColorbar(cmap, classNames);
figure(2)
expectedResult = readimage(pxdsTest,imNum);
actual = uint8(C);
expected = uint8(expectedResult);
imshowpair(actual, expected)

%% EVALUATION
tempdir = '~/Documents/MATLAB/temp';

pxdsResults = semanticseg(imdsTest,net, ...
    'MiniBatchSize',8, ...
    'WriteLocation',tempdir, ...
    'Verbose',false);

metrics = evaluateSemanticSegmentation(pxdsResults,pxdsTest,'Verbose',false);
metrics.DataSetMetrics
metrics.ClassMetrics
