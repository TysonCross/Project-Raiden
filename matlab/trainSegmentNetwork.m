%% trainSegmentNetwork.m
% This script implements data preperation, training and evaluation of 
% various deep learning models, mainly using transfer learning on known
% network topologys.
%
% ToDo(Tyson): Expand on the above as is required
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
    'deeplabv3' (batchsize ~100)
    'segnet' (batchsize ~20)
%}

% Phases to run
opt.forceConvert	= 1;	% resize/convert/process new data (slow)
opt.preProcess     	= 1; 	% if true, median filter on input data
opt.splitTestData 	= 1;	% re-split Test/Training data *
opt.splitValData 	= 1;	% re-split Training/Validation data
opt.fromCheckpoint 	= 0;	% if training did not finish, use checkpoint
opt.useCachedNet   	= 0;   	% if false, generate new neural network
opt.doTraining    	= 1;   	% if true, perform training
opt.evaluateNet    	= 1;   	% if true, evaluate performance on test set
opt.archiveNet     	= 1;   	% archive NN, data and figures to subfolder

% Percentage of each sequence (strokes will not be culled)
% (In order to take affect after a change, splitTestData must be enabled)
opt.percentage    	= 0.25;	% only use a percentage of images

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
opt.convertData = checkConversion(projectPath, imageSize, opt.forceConvert);
    
if ( (opt.convertData==true) || (opt.forceConvert==true) )
	convertData(projectPath, imageSize, opt.forceConvert, opt.preProcess)
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
        opt.splitTestData)
    
    cprintf([1,0.5,0],['Warning: No datastore cache found at: %s \n'...
        '(Training/Test data will be repartitioned) \n'], ...
        fullfile(cachePath,'data'));
end

if (opt.splitTestData==false && opt.percentage < 1)
    cprintf([1,0.5,0], ['Warning: splitTestData is off. ', ...
        'Randomized subset will not be re-selected. ' ...
        'Enable ''splitTestData'' to force an update\n'])
end

if (opt.splitTestData==true  || opt.forceConvert)
    splitTestPercent = 0.15;
    splitTestData(resizedImageFolders, resizedLabelFolders, ...
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

if (opt.splitValData==true || ~exist('imdsVal','var'))
    disp("Splitting training/validation data...")
    splitTrainingPercentage = 0.8;
    splitValidationData(imdsTrain, pxdsTrain, splitTrainingPercentage);
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
        createNetwork(networkType, cachePath, labelWeights);
        load(fullfile(cachePath,'network'));
    else
        fprintf('Loading Network from cache...')
        updatedNetName = networkStatus.name;
        load(fullfile(cachePath,'network'));
        networkStatus.name = updatedNetName;
        clear updatedNetName
        
%         disp('Updating network name...')
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
    
    % Define training options.
    options = trainingOptions('sgdm', ...
        'ExecutionEnvironment','auto', ...
        'MaxEpochs', 30, ...  
        'MiniBatchSize', 100, ...
        'Shuffle','every-epoch', ...
        'CheckpointPath', checkpointPath, ...
        'InitialLearnRate',1e-2, ... % from 1e-3
        'LearnRateSchedule','piecewise',...
        'LearnRateDropPeriod',10,...
        'LearnRateDropFactor',0.3,...
        'Momentum',0.9, ...
        'L2Regularization',0.003, ... % from 0.005
        'GradientThreshold', 10, ...
        'ValidationData',pximdsVal, ...
        'ValidationFrequency', 25,...
        'ValidationPatience', 6, ...
        'Verbose', 1, ...
        'VerboseFrequency',50,...
        'Plots','training-progress');
    
    % display info
    cprintf([0.2,0.7,0], '\t\t      Training Options \n');
    disp(options);

    pximds = pixelLabelImageDatastore(imdsTrain,pxdsTrain);

    % shuffle the data
    pximds = pximds.shuffle;
    
    % Clear memory
    clear numTestingImages numTrainingImages numValidationImages
    clear inputLayer opt.convertData opt.forceConvert opt.splitTestData
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
end

if (networkStatus.trained && opt.evaluateNet)
    cprintf([0,0.5,1], '\n================ Evaluation =================\n');
    
    outputDir = fullfile(projectPath,"networks","output",networkStatus.name)
    if ~exist(outputDir,'dir')
        mkdir(outputDir)
    end
    
    pxdsResults = semanticseg(imdsTest,net, ...
        'MiniBatchSize',16, ...
        'WriteLocation',outputDir, ...
        'Verbose',true);

    metrics = evaluateSemanticSegmentation(pxdsResults,pxdsTest, ...
        'Verbose',false);
    cprintf([0.2,0.7,0],'\t\t\t Evaluation metrics\n\n');
    disp(metrics.DataSetMetrics);
    disp(' ');
    disp(metrics.ClassMetrics);
    disp(' ');
    
    save(fullfile(cachePath,'network'), ...
        'net','networkStatus','imageSize','metrics');
    disp("Performance metrics added to network cache") 
end

diary off; diary on;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Archive network, images, and matlab script
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sendFileList = {''};
if (opt.archiveNet)
   cprintf([0,0.5,1], '\n=============== Archive Data ================\n');

   fprintf('Saving data, please wait...')
   currentFileName = strcat(mfilename('fullpath'),'.m');
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
            export_fig(fn,figHandle(1));
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