
%% Import variables
fromApp = true;
if ~fromApp
    load('/home/tyson/Dropbox/Academic/4th Year/ELEN4012/Raiden/networks/cache/deeplabv3_2019-08-08_073519/network.mat');
    sequenceDir = '/mnt/Shield/Raiden/data/sequences/test/full_seq/tif';
    outputDir = '~/Desktop/test';
    % labelDir = '/home/jason/Desktop/reduced/mask';
    doOverlay = true;
    doCompare = false;
else
    load(app.Networkfile_Edit.Value); 
    sequenceDir = app.Inputfolder_Edit.Value;
    outputDir = app.Outputpath_Edit.Value;

    doOverlay = app.Makeoverlay_CheckBox.Value;
    doCompare = app.Comparewithexpected_CheckBox.Value;
end

if ~exist('net','var')
    if exist('lgraph','var')
        net =lgraph;
    else
        error('No network defined')
    end
end

if doCompare
    labelDir = app.Pixellabels_Edit.Value;
end

loadLabels;
setupColors;
sz = net.Layers(1).InputSize(1:2);

%% Resize
imds = imageDatastore(sequenceDir);
originalSize = size(imds.readimage(1));


% Create output folders
if ~exist(fullfile(outputDir,'output'),'dir')
  mkdir(fullfile(outputDir,'output'));
end

if ~exist(fullfile(outputDir,'tmp'),'dir')
    mkdir(fullfile(outputDir,'tmp'))
end

disp("Resizing images...")

y = sz(1);
x = sz(2);
rez = strcat(string(x),'x',string(y));
str = char(strcat('Resizing images to ',{' '},rez));
progressbar('Resizing image sequences',str)
imds = resizeImages(imds, sz, fullfile(outputDir,'tmp','img') );
if doCompare
    pxds = pixelLabelDatastore(labelDir,...
    labelNames,labelIDs,'FileExtensions','.tif');
    disp("Resizing labels and converting to categorical label form...")
    str = char(strcat('Converting labels to ',{' '},rez));
    progressbar('Resizing and converting label sequences',str)
    pxds = resizePixelLabels(pxds, sz, fullfile(outputDir,'tmp','label'));
end
progressbar(1)

%% Segment data
resultPixelLabels = semanticseg(imds, net, ...
        'MiniBatchSize', 32, ...
        'WriteLocation', fullfile(outputDir, '/output'), ...
        'Verbose', true);

if doCompare
     if ~exist(fullfile(outputDir,'comparison'),'dir')
        mkdir(fullfile(outputDir,'comparison'))
    end
end

if doOverlay
    disp('Creating overlay...')
    if ~exist(fullfile(outputDir,'overlay'),'dir')
        mkdir(fullfile(outputDir,'overlay'))
    end
end

for n = 1:length(imds.Files)
 [~,name,~] = fileparts(string(imds.Files(n)));
 
 I = readimage(imds,n);
    if doOverlay
        segImage = labeloverlay(I,resultPixelLabels.readimage(n),'Colormap',cmap,'Transparency',0.4);
    else
        segImage = unit8(resultPixelLabels);
    end
    
    if doCompare
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

disp('Clearing tmp folder...')

if exist(fullfile(outputDir,'tmp'),'dir')
    [~, msg] = rmdir(fullfile(outputDir,'tmp'), 's');
    disp(msg);
end

clear actual ans cmap diffImage expected expectedResult I ...
    imds info labelDir labelIDs labelIDs_scalar labelNames ...
    msg n name net numClasses originalSize outputImage ...
    outputDir pxds resultPixelLabels segImage sequenceDir ...
    status str sz outImage;

disp('Done.')
msgbox('Operation Completed');