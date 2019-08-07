
%% Import variables
%testing
% sequenceDir = '/home/jason/Desktop/reduced/tif';
% labelDir = '/home/jason/Desktop/reduced/mask';
% load('/home/jason/Desktop/reduced/alexnet_2019-07-30_121421/alexnet_2019-07-30_121421.mat'); %%ToDo add a check here and only load the vars as requested
% outputDir = '/home/jason/Desktop/test';
% sz = net.Layers(1).InputSize(1:2);

%Might be worth it to check the folders for tifs in the app??

sequenceDir = app.Inputfolder_Edit.Value;
outputDir = app.Outputpath_Edit.Value;
load(app.Networkfile_Edit.Value); 
if ~exist('net','var')
    if exist('lgraph','var')
        net =lgraph;
    else
        error('No network defined')
    end
end

if (app.Comparewithexpected_CheckBox.Value)
    labelDir = app.Pixellabels_Edit.Value;
    %created required dir
     if ~exist(fullfile(outputDir,'comparison'),'dir')
        mkdir(fullfile(outputDir,'comparison'))
    end
end

loadLabels;
sz = net.Layers(1).InputSize(1:2);
setupColors;

%% Resize
imds = imageDatastore(sequenceDir);
originalSize = size(imds.readimage(1));

disp("Resizing images")
imds = resizeImages(imds, sz, fullfile(outputDir,'tmp','img') );
if (exist('labelDir'))
    pxds = pixelLabelDatastore(labelDir,...
    labelNames,labelIDs,'FileExtensions','.tif');
    disp("Resizing labels and converting to categorical label form...")
    pxds = resizePixelLabels(pxds, sz, fullfile(outputDir,'tmp','label'));
end


%% Create output folders
if ~exist(fullfile(outputDir,'output'),'dir')
  mkdir(fullfile(outputDir,'output'));
end
if ~exist(fullfile(outputDir,'tmp'),'dir')
    mkdir(fullfile(outputDir,'tmp'))
end
if ~exist(fullfile(outputDir,'overlay'),'dir')
    mkdir(fullfile(outputDir,'overlay'))
end

%% Segment data
resultPixelLabels = semanticseg(imds,net, ...
        'MiniBatchSize', 1, ...
        'WriteLocation', fullfile(outputDir, '/output'), ...
        'Verbose', false); %Label the data
for n = 1:length(imds.Files)
 [~,name,~] = fileparts(string(imds.Files(n)));
 [I, info] = readimage(imds,n); %Read image
    %if MakeOverlay
    if(app.Makeoverlay_CheckBox.Value)
        segImage = labeloverlay(I,resultPixelLabels.readimage(n),'Colormap',cmap,'Transparency',0.4);
    else
        segImage = unit8(resultPixelLabels);
    end
    
    if(app.Comparewithexpected_CheckBox.Value)
        numClasses = numel(labelNames);
        expectedResult = readimage(pxds,n);
        actual = uint8(resultPixelLabels.readimage(n))*(255/numClasses);
        expected = uint8(expectedResult)*(255/numClasses);
        diffImage = imfuse(actual, expected);
        str = strcat(outputDir,'/comparison/', name.insertAfter(21,'_comparison'), '.tif');
        outImage = imresize(diffImage,[originalSize(1) originalSize(2)]); 
        imwrite(outImage, str);
        
    end
    outImage = imresize(segImage,[originalSize(1) originalSize(2)]); 
    imwrite(outImage, strcat(outputDir,'/overlay/', name.insertAfter(21,'_out'),  '.tif'));
    
    
end
disp('Clearing tmp folder')
%Only attempt to remove a dir that exists 
if exist(fullfile(outputDir,'tmp'),'dir')
    [status, msg]=rmdir(fullfile(outputDir,'tmp'), 's'); % s = rm -rf
    disp(msg);
end
clear actual ans cmap diffImage expected expectedResult I ...
    imds info labelDir labelIDs labelIDs_scalar labelNames ...
    msg n name net numClasses originalSize outputImage ...
    outputDir pxds resultPixelLabels segImage sequenceDir ...
    status str sz outImage;
disp('Done');

%if MakeOverlay
%if(app.MakeoverlayCheckBox.Value)