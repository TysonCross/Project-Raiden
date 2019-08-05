
%% Import variables
%% ARHG: Can't change labels after removing them from the view
%testing
% sequenceDir = '/home/jason/Desktop/reduced/tif';
% labelDir = '/home/jason/Desktop/reduced/mask';
% load('/home/jason/Desktop/reduced/alexnet_2019-07-30_121421/alexnet_2019-07-30_121421.mat'); %%ToDo add a check here and only load the vars as requested
% outputDir = '/home/jason/Desktop/Testout';
% sz = net.Layers(1).InputSize(1:2);

sequenceDir = app.EditField.Value;
labelDir = app.EditField_4.Value;
load(app.EditField_2.Value); %%ToDo add a check here and only load the vars as requested
if ~exist('net','var')
    if exist('lgraph','var')
        net =lgraph;
    else
        error('No network defined')
    end
end

outputDir = app.EditField_3.Value;
sz = net.Layers(1).InputSize(1:2);
loadLabels;
setupColors;


%% Resize
imds = imageDatastore(sequenceDir);
pxds = pixelLabelDatastore(labelDir,...
    labelNames,labelIDs,'FileExtensions','.tif');
disp("Resizing images and labels, converting to categorical label form...")
imds = resizeImages(imds, sz, fullfile(outputDir,'img') );
pxds = resizePixelLabels(pxds, sz, fullfile(outputDir,'label'));
%% Create output folders
if ~exist(fullfile(outputDir,'output'),'dir')
  mkdir(fullfile(outputDir,'output'));
end
if(app.ComparewithexpectedCheckBox.Value)
 if ~exist(fullfile(outputDir,'compare'),'dir')
    mkdir(fullfile(outputDir,'compare'))
 end
end
if ~exist(fullfile(outputDir,'tmp'),'dir')
    mkdir(fullfile(outputDir,'tmp'))
end
%% Segment data
resultPixelLabels = semanticseg(imds,net, ...
        'MiniBatchSize', 1, ...
        'WriteLocation', fullfile(outputDir, 'tmp'), ...
        'Verbose', false); %Label the data
for n = 1:length(imds.Files)
 [~,name,~] = fileparts(string(imds.Files(n)));
 [I, info] = readimage(imds,n); %Read image
    %if MakeOverlay
    if(app.MakeoverlayCheckBox.Value)
        segImage = labeloverlay(I,resultPixelLabels.readimage(n),'Colormap',cmap,'Transparency',0.4);
        
    else
        segImage = unit8(resultPixelLabels);
    end
    if(app.ComparewithexpectedCheckBox.Value)
        numClasses = numel(labelNames);
        expectedResult = readimage(pxds,n);
        actual = uint8(resultPixelLabels.readimage(n))*(255/numClasses);
        expected = uint8(expectedResult)*(255/numClasses);
        diffImage = imfuse(actual, expected);
        str = strcat(outputDir,'/compare/', name.insertAfter(21,'_compare'), '.tif');
        imwrite(diffImage, str);
        
    end
    imwrite(segImage, strcat(outputDir,'/output/', name.insertAfter(21,'_out'),  '.tif'));
    
    
end

disp('Done');

%if MakeOverlay
%if(app.MakeoverlayCheckBox.Value)