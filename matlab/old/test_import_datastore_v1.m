clear all; clc;

setenv('NVIDIA_CUDNN', '/usr/local/cuda');
setenv('NVIDIA_TENSORRT', '/opt/TensorRT-5.1.2.2');
% results = coder.checkGpuInstall('full')

%% TEMP
% % load pretrained networks
rootPath = '/home/tyson/Dropbox/Academic/4th Year/ELEN4012/Raiden/';

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

sequences = {...
    '/2017-02-10_162903/2017-02-10_162903_010/';...
    '/2017-02-10_163357/2017-02-10_163357_010';...
    '/2017-02-10_163553/2017-02-10_163553_010';...
    '/2017-02-10_163553/2017-02-10_163553_020';...
    '/2017-02-10_163553/2017-02-10_163553_030';...
    '/2017-02-10_163553/2017-02-10_163553_040';...
    '/2017-02-10_163553/2017-02-10_163553_050';...
    '/2017-02-10_163553/2017-02-10_163553_060';...
    '/2017-02-10_163553/2017-02-10_163553_070';...
    '/2017-02-10_163553/2017-02-10_163553_080';...
    '/2017-02-10_163553/2017-02-10_163553_090';...
    '/2017-02-10_163553/2017-02-10_163553_100';...
    '/2017-02-10_163553/2017-02-10_163553_110';...
    '/2017-02-10_163553/2017-02-10_163553_120';...
    '/2017-02-10_163553/2017-02-10_163553_130';...
    '/2017-02-10_163553/2017-02-10_163553_140';...
    '/2017-02-10_163553/2017-02-10_163553_150';...
    '/2017-02-10_163553/2017-02-10_163553_160';...
    '/2017-02-10_163553/2017-02-10_163553_170';...
    '/2017-02-10_163553/2017-02-10_163553_180';...
    '/2017-02-10_163553/2017-02-10_163553_190';...
    '/2017-02-10_163553/2017-02-10_163553_200';...
    '/2017-02-10_163553/2017-02-10_163553_210';...
    '/2017-02-10_163553/2017-02-10_163553_220';...
    '/2017-02-10_163553/2017-02-10_163553_230';...
    '/2017-02-10_163553/2017-02-10_163553_240';...
    '/2017-02-10_163553/2017-02-10_163553_250';...
    '/2017-02-10_163553/2017-02-10_163553_260';...
    '/2017-02-10_163907/2017-02-10_163907_010';...
    '/2017-02-10_163907/2017-02-10_163907_020';...
    '/2017-02-10_163907/2017-02-10_163907_030';...
    '/2017-02-10_163907/2017-02-10_163907_040';...
    '/2017-02-10_163907/2017-02-10_163907_050';...
    '/2017-02-10_163907/2017-02-10_163907_060';...
    '/2017-02-10_163916/2017-02-10_163916_010';...
    '/2017-02-10_163916/2017-02-10_163916_020';...
    '/2017-02-10_164114/2017-02-10_164114_010';...
    '/2017-02-10_164114/2017-02-10_164114_020';...
    '/2017-02-10_164114/2017-02-10_164114_030';...
    '/2017-02-10_164114/2017-02-10_164114_040';...
    '/2017-02-10_164114/2017-02-10_164114_050';...
    '/2017-02-10_164114/2017-02-10_164114_060';...
    '/2017-02-10_164114/2017-02-10_164114_070';...
    '/2017-02-10_164114/2017-02-10_164114_080';...
    '/2017-02-10_164114/2017-02-10_164114_090';...
    '/2017-02-10_164141/2017-02-10_164141_010'};


sequencesPath = '/mnt/Shield/Raiden/data/sequences';
imageFolders = fullfile(sequencesPath,sequences,'tif',filesep);
imds = imageDatastore(imageFolders,...
    'FileExtensions','.tif');
maskFolders = fullfile(sequencesPath,sequences,'mask',filesep);
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

% View Overlay
I = readimage(imds,100);
I = histeq(I);
C = readimage(pxds,100);
cmap = jet(numel(classNames));
B = labeloverlay(I,C,'Colormap',cmap);
figure
imshow(B)
pixelLabelColorbar(cmap,classNames);

% Specify the class weights 
% ToDo: This is slow!
disp("Counting per-label pixel distribution...")
tbl = countEachLabel(pxds);

% Visualize pixel frequency of labels
frequency = tbl.PixelCount/sum(tbl.PixelCount);
bar(1:numel(classNames),frequency)
xticks(1:numel(classNames)) 
xticklabels(tbl.Name)
xtickangle(45)
ylabel('Frequency')

% Converting to Categorical data
disp("Converting to canononical label form...")
labelFolders = fullfile(sequencesPath,sequences,'label');
pxds = convertCategorical(pxds, labelFolders);

% Split into training and test 
% ToDo: Partition Method non-random (sequential/split)
[imdsTrain, imdsVal, imdsTest, pxdsTrain, pxdsVal, pxdsTest] = partitionData(imds,pxds);

numTrainingImages = numel(imdsTrain.Files)
numValidationImages = numel(imdsVal.Files)
numTestingImages = numel(imdsTest.Files)


%% NETWORK
disp("Setting up Network...")
imageSize = [256 512]
numClasses = numel(classNames);
lgraph = fcnLayers(imageSize, numClasses);    % Create vgg16

imageFreq = tbl.PixelCount ./ tbl.ImagePixelCount;
classWeights = median(imageFreq) ./ imageFreq;

pxLayer = pixelClassificationLayer('Name','labels','Classes',tbl.Name,'ClassWeights',classWeights);
lgraph = removeLayers(lgraph,'pixelLabels');
lgraph = addLayers(lgraph, pxLayer);
lgraph = connectLayers(lgraph,'softmax','labels');

%% TRAINING
disp("Setting up Training...")

% Define validation data.
pximdsVal = pixelLabelImageDatastore(imdsVal,pxdsVal,...
    'DispatchInBackground',true);

pretrainedFolder = fullfile(rootPath,'networks','pretrained');
% ToDo: Add additional network options
pretrainedNetwork = fullfile(pretrainedFolder,'FCN8s.mat'); 

checkpointsFolder = fullfile(rootPath,'networks','checkpoints');

% Define training options. 
options = trainingOptions('adam', ...
    'InitialLearnRate',1e-3, ...
    'MaxEpochs',30, ...  
    'MiniBatchSize',8, ...
    'ValidationData',pximdsVal, ...
    'Shuffle','every-epoch', ...
    'CheckpointPath', checkpointsFolder, ...
    'Plots','training-progress',...
    'VerboseFrequency',2);

% Define training data
augmenter = imageDataAugmenter('RandXReflection',true,...
    'RandXTranslation',[-10 10],'RandYTranslation',[-10 10]);

pximds = pixelLabelImageDatastore(imdsTrain,pxdsTrain,...
    'DispatchInBackground',true, 'DataAugmentation',augmenter);


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
I = readimage(imdsTest,35);
C = semanticseg(I, net);
B = labeloverlay(I,C,'Colormap',cmap,'Transparency',0.4);
imshow(B)
pixelLabelColorbar(cmap, classes);

expectedResult = readimage(pxdsTest,35);
actual = uint8(C);
expected = uint8(expectedResult);
imshowpair(actual, expected)

%% EVALUATION
tempdir = '~/Documents/MATLAB/temp';

pxdsResults = semanticseg(imdsTest,net, ...
    'MiniBatchSize',8, ...
    'WriteLocation',tempdir, ...
    'Verbose',true);

metrics = evaluateSemanticSegmentation(pxdsResults,pxdsTest,'Verbose',true);
metrics.DataSetMetrics
metrics.ClassMetrics

