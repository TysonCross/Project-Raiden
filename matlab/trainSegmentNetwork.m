%% trainSegmentNetwork.m
% This script implements data preperation, training and evaluation of 
% various deep learning models, mainly using transfer learning on known
% semantic segmentation network topologies.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% prescript clean-up and reset:
figHandle = findall(groot, 'Type', 'Figure'); close(figHandle(:))
setenv('NVIDIA_CUDNN', '/usr/local/cuda');
setenv('NVIDIA_TENSORRT', '/opt/TensorRT-5.1.2.2');
clc; clearvars;

%% SETUP
networkType = 'deeplabv3';

%{
    Network choices are:
    'fcn8s' (batch size ~10)
    'alexnet' (batchsize ~100) 
    'deeplabv3' (batchsize ~100) (trained with full/latest dataset)
    'segnet' (batchsize ~20)
    'u-net' (batchsize ~30)
%}

% Phases to run
opt.forceConvert	= 0;	% resize/convert/process new data (slow)
opt.preProcess     	= 1; 	% if true, apply time-denoising on input data
opt.reSplitData     = 1;	% re-split Test/Training/Validation data *
opt.fromCheckpoint 	= 0;	% if training did not finish, use checkpoint
opt.useCachedNet   	= 0;   	% if false, generate new neural network
opt.doTraining    	= 1;   	% if true, perform training
opt.evaluateNet    	= 1;   	% if true, evaluate performance on test set
opt.archiveNet     	= 1;   	% archive NN, data and figures to subfolder

% Percentage of each sequence (strokes will not be culled)
% * In order to take affect after a change, splitData must be enabled
opt.percentage = 0.80;      % only use a percentage of images

% resolution setup
imageSize = getResolution(networkType);
y = imageSize(1);
x = imageSize(2);
rez = strcat(string(x),'x',string(y));

% global setup
projectPath = '/home/tyson/Raiden/';
scriptPath = fullfile(projectPath,'matlab');
setupColors;
networkStatus.name = strcat(networkType,'_', rez, '_', ...
    strrep(strrep(datestr(datetime('now'),31), ' ', '_'), ':', ''));

cachePath = fullfile(scriptPath,'cache');
if ~exist(cachePath,'dir')
    mkdir(cachePath);
end

checkpointPath = fullfile(projectPath,'networks','checkpoints');
if ~exist(checkpointPath,'dir')
    mkdir(checkpointPath);
end

logFile = strcat(networkStatus.name,'.txt');
logFileFull = fullfile(projectPath,'logs',logFile);
diary(logFileFull)

cprintf([0,0.5,1], '=============== Configuration ===============\n');
displayConfiguration(opt, networkType, rez, networkStatus.name, logFile);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Data Conversion Phase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cprintf([0,0.5,1], '\n=================== Data ====================\n');

% This process is slow. Although there are a couple checks to determine
% if any source files (tifs or mask images) must be resized/(re)converted,
% this should ideally be a once-off conversion. If a file exists on disk
% in the destination resized/converted folder, it will not be reconverted
% unless the forceConvert option is enabled.

loadLabels;
loadSequences;

% Check if we need to convert any files
opt.convertData = checkConversion(projectPath, cachePath, imageSize, opt.forceConvert);
    
if ( opt.convertData==true || opt.forceConvert==true )
	convertData(projectPath, cachePath, imageSize, opt.forceConvert, opt.preProcess)
else
    fprintf('Loading image metadata from cache...')
end

if exist(fullfile(cachePath,'metadata.mat'),'file')
    load(fullfile(cachePath,'metadata'));
    fprintf('\t Done \n');
else
    error('Error: Image cache does not exist at %s \n', ...
        fullfile(cachePath,'metadata.mat'))
end

diary off; diary on;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Split Test/Training data phase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This phase seperates some test data

% Check to see if cache exists
if (~exist(fullfile(cachePath,strcat('data','.mat')),'file') && ...
        opt.reSplitData)
    
    cprintf([1,0.5,0],['Warning: No datastore cache found at: %s \n'...
        '(Training/Test data will be repartitioned) \n'], ...
        fullfile(cachePath,'data'));
end

if (opt.reSplitData==false && opt.percentage < 1)
    cprintf([1,0.5,0], ['Warning: splitData is off. ', ...
        'Randomized subset will not be re-selected. ' ...
        'Enable ''splitData'' to force an update\n'])
end

if (opt.reSplitData==true  || opt.forceConvert)
    splitTestPercent = 0.15;
    splitTestData(resizedImageFolders, cachePath, resizedLabelFolders, ...
        splitTestPercent, opt.percentage);
else
    fprintf('Loading datastores from cache...')
end

if exist(fullfile(cachePath,'data.mat'),'file')
    load(fullfile(cachePath,'data'));
    fprintf('\t Done \n');
else
    error('Error: Data cache does not exist at %s \n', ...
        fullfile(cachePath,'data.mat'))
end

% display info
cprintf([0.2,0.7,0],'\n      Per-label pixel label count for dataset\n\n')
disp(labelTable);
disp(' ');

diary off; diary on;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Training/Validation partition phase 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (opt.reSplitData==true || ~exist('imdsVal','var'))
    disp("Splitting training/validation data...")
    splitTrainingPercentage = 0.80;
    splitValidationData(imdsTrain, pxdsTrain, ...
        splitTrainingPercentage, cachePath, ...
        imdsTest, pxdsTest, labelWeights, labelTable);
else
    fprintf('Loading training/validation-split from cache...')
end

if exist(fullfile(cachePath,'data.mat'),'file')
    load(fullfile(cachePath,'data'));
    fprintf('\t Done \n');
else
    error('Error: Data cache does not exist at %s \n', ...
        fullfile(cachePath,'data.mat'))
end

% display info
cprintf([0.2,0.7,0],'\n\tTraining images: \t %d \n', numel(imdsTrain.Files));
cprintf([0.2,0.7,0],'\tValidation images: \t %d \n', numel(imdsVal.Files));
cprintf([0.2,0.7,0],'\tTesting images: \t %d \n', numel(imdsTest.Files));

diary off; diary on;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Network setup phase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cprintf([0,0.5,1], '\n================== Network ================== \n');

if opt.fromCheckpoint
    fprintf("Attempting to load checkpoint for network...")
    filename = fullfile(checkpointPath,getLatestFile(checkpointPath));
    if exist(filename,'file')
        load(filename);
        fprintf('\t Done \n');
        disp(['Loaded checkpoint from ', string(filename)]);
        net = layerGraph(net);
        networkStatus.trained = 0;
    else
        error(strcat({'Error: User specified: opt.fromCheckpoint = 1, '},...
                {'but no checkpoint found in '}, string(checkpointPath)));
    end
    clear filename
else
    if opt.useCachedNet
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
                    opt.useCachedNet=0;
                case btn2
                    clear q msg title btn1 btn2
                    error(['Error: No network cache found at: ', ...
                        fullfile(cachePath,'network')])
            end
            clear q msg title btn1 btn2
        end
    end

    if (opt.useCachedNet==false)
        createNetwork(networkType, cachePath, labelWeights, networkStatus);
        load(fullfile(cachePath,'network'));
    else
        fprintf('Loading Network from cache...')
        updatedNetName = networkStatus.name;
        load(fullfile(cachePath,'network'));
        networkStatus.name = updatedNetName;
        clear updatedNetName
        
        save(fullfile(cachePath,'network'),...
        'net','networkStatus','imageSize');
        fprintf('\t Done \n');

    end
end

diary off; diary on;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Training
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (opt.doTraining==true) && (opt.useCachedNet==true)
    if ~(contains(class(net),'LayerGraph'))
        net = layerGraph(net);
    end
end

if (opt.doTraining==true)
    cprintf([0,0.5,1], '\n================= Training ==================\n');
    
    checkpointsFolder = fullfile(projectPath,'networks','checkpoints');
    close all;
    
    % Define augmenting methods
    pixelRange = [-16 16];
    scaleRange = [1 2.0]; 
    augmenter = imageDataAugmenter( ...
        'RandXReflection',true, ...
        'RandXTranslation',pixelRange, ...
        'RandYTranslation',pixelRange, ...
        'RandXScale',scaleRange);

    % Validation datastore
    pximdsVal = pixelLabelImageDatastore(imdsVal,pxdsVal,...
        'DataAugmentation', augmenter);
    
    % Define training options.
    options = trainingOptions('sgdm', ...
        'ExecutionEnvironment','auto', ...
        'MaxEpochs', 20, ...  
        'MiniBatchSize', 120, ...
        'Shuffle','every-epoch', ...
        'CheckpointPath', checkpointPath, ...
        'InitialLearnRate',1e-3, ... % from 1e-3
        'LearnRateSchedule','piecewise',...
        'LearnRateDropPeriod',5,...
        'LearnRateDropFactor',0.5,...
        'Momentum',0.9, ...
        'L2Regularization',0.003, ... % from 0.005
        'GradientThreshold', 10, ...
        'ValidationData',pximdsVal, ...
        'ValidationFrequency', 25,...
        'ValidationPatience', 4, ...
        'Verbose', 1, ...
        'VerboseFrequency',50,...
        'Plots','training-progress');
    
    % display info
    cprintf([0.2,0.7,0], '\t\t      Training Options \n');
    disp(options);
    
    % Training datastore
    pximds = pixelLabelImageDatastore(imdsTrain,pxdsTrain,...
        'DataAugmentation', augmenter);
    
    % shuffle the data
    pximdsVal = pximdsVal.shuffle;
    pximds = pximds.shuffle;
    
    % Clear memory
    clear numTestingImages numTrainingImages numValidationImages
    clear inputLayer opt.convertData opt.forceConvert opt.reSplitData
    clear opt.fromCheckpoint opt.resplitValidation
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
    disp("Network trained") 
    
    % clear out checkpoints
    delete(fullfile(checkpointPath,'net_checkpoint_*.mat'));
false
else
    cprintf([1,0.5,0],'Warning: Training skipped by user request \n')
end

diary off; diary on;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Evaluation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (networkStatus.trained==0 && opt.evaluateNet)
            cprintf([1,0.5,0], ['Warning: Network evaluation was ', ...
                'requested, but the network has not been trained yet!', ...
                ' Please enable ''doTraining'' if you want to train ', ...
                'a network \n'])
            
elseif (networkStatus.trained && opt.evaluateNet)
    cprintf([0,0.5,1], '\n================ Evaluation =================\n');
    fprintf("Evaluating network against overall test set...\t")
    metrics = evaluateNetwork(imdsTest, pxdsTest, net, networkStatus);
    fprintf('Done\n\n');
    cprintf([0.2,0.7,0],'\t\t\t Evaluation metrics\n\n');
    disp(metricsOverall.DataSetMetrics); disp(' ');
    disp(metricsOverall.ClassMetrics); disp(' ');
    
    save(fullfile(cachePath,'network'), ...
        'net','networkStatus','imageSize','metrics');
    disp("Performance metrics added to network cache") 

    % split the test set back into indivual sequences
    disp("Evaluating each test sequence individually...")
    
    [imdsTestSequences, pxdsTestSequences] = seperateSequences(imdsTest, pxdsTest);
    
    networkFile = fullfile(cachePath,'network');
    doPreprocessing = true;
    doOverlay = true;
    doCompare = true;
    fromTraining = true;
    batchSize = 32;
    
    for ii=1:numel(imdsTestSequences)
        [~,filename] = fileparts(imdsTestSequences{ii}.Files{1});
        sequencePath = split(filename, '.');
        sequencePath = sequencePath{1};
        disp(['Sequence: ', sequencePath]);
        outputPath = fullfile(projectPath,'networks','output', ...
            networkStatus.name,sequencePath);
        segmentResults(networkFile, imdsTestSequences{ii}, outputPath, ...
            doPreprocessing, doOverlay, doCompare, ...
            pxdsTestSequences{ii}, batchSize, fromTraining);
    end
    
    disp("Individual test sequence analysis and output complete.")

    clear networkFile sequenceDir outputPath  isSeqPXDS
    clear doPreprocessing doOverlay doCompare labelDir progressBarFigure;
end

diary off; diary on;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Archive network, images, and matlab script
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sendFileList = {''};
if (opt.archiveNet)
   cprintf([0,0.5,1], '\n=============== Archive Data ================\n');

   fprintf('Saving data, please wait...')
%    currentFileName = strcat(mfilename('fullpath'),'.m');
currentFileName = fullfile(scriptPath,'trainSegmentNetwork.m');
   if exist(currentFileName,'file')
        foldername = fullfile(projectPath,"networks","cache", ...
            networkStatus.name);
        mkdir(foldername);
        copyfile(currentFileName, foldername);
        copyfile(fullfile(cachePath,'data.mat'),foldername);
        copyfile(fullfile(cachePath,'metadata.mat'),foldername);
        copyfile(fullfile(cachePath,'network.mat'),foldername);
        disp('Network and data archived')
        figHandle = findall(groot, 'Type', 'Figure');
        if (numel(figHandle)>0)
            fig_name = figHandle.Name;
            fig_name(isspace(fig_name)==1)='_';
            fig_name = regexprep(fig_name, '[ .,''!?():]', '');
            fig_name = sprintf('%s.pdf',fig_name);
            fn = sprintf('%s/%s',foldername,fig_name);
            warning('off')
            export_fig(fn,figHandle(1));
            warning('on')
            fprintf("%d figures exported to %s\n", ...
                length(figHandle),foldername);
            sendFileList = strcat(sendFileList, ...
                {' --content-type="application/pdf" --attach="'},fn,{'"'});
            disp('Figure archived')
            close(figHandle(:));
        else
            cprintf([1,0.5,0],'Warning: No figures found \n')
        end
        
        fprintf('\t Saved \n')
        diary off;
        copyfile(logFileFull,foldername);
        sendFileList = strcat(sendFileList, ...
            {' --content-type="text/plain" --attach="'},logFileFull,{'"'});
        disp('Log archived')
   else
       cprintf([1,0.5,0], ['Warning: %s does not exist! ', ...
           'Network not archived. \n'], string(currentFileName));
   end
else
    cprintf([1,0.5,0], ['Warning: Network not archived ', ...
        'because ''archiveNet'' is disabled \n']);
end

diary off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Notifications
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (opt.archiveNet && opt.doTraining)
    [hours, mins, secs] = sec2hms(networkStatus.trainingTime);
    subject = strcat({'Training for '}, networkStatus.name, ...
        {' has completed at '}, ...
        datestr(datetime('now'),31), ...
        {'. Training time took '}, ...
        string(hours), {':'}, ...
        string(mins), {':'}, ...
        string(secs), {' (hh:mm:ss)'});
    mail_str = strcat({'echo " " | mail -s "'}, subject, ...
        {'" '}, sendFileList, {' 1239448@students.wits.ac.za'});
    if ~(unix(char(mail_str)))
        disp('Notification sent')
    else
        cprintf([1,0.5,0], 'Warning: mail notification failed \n')
    end
end

return % end script
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%