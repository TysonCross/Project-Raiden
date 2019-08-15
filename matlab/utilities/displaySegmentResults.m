%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                          DISPLAYSEGMENTRESULTS.M
% Take in Sequence, options and trained network
% Basic defined vars
% ToDo: add selection options
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
labelButton= true;

%% Define root path
%ToDo: This should be done dynamically
rootPath = '~/Desktop/';
loadSequences;
%% Sequence to load
sequenceDir = uigetdir(fullfile(rootPath),'Select the sequence to load');
    if ~sequenceDir
        error('No directory has been defined')
    end
%% Options

outputDir = uigetdir(fullfile(rootPath),'Select the output diretory');
    if ~outputDir
        disp('No directory has been defined, using standard tmp')
    end

if labelButton
    labelDir=uigetdir(fullfile(rootPath),'Select the masks');
end

% load network
[file,path] = uigetfile('*.mat',...
                      'Select the Network File to load',fullfile(rootPath,'networks','cache'));
load(fullfile(path,file));
if ~exist('net','var')
    disp('Error: No cached network in file');
    return
end
sz = net.Layers(1).InputSize(1:2);


%% Resize
imds = imageDatastore(sequenceDir);
pxds = pixelLabelDatastore(labelDir,...
    labelNames,labelIDs,'FileExtensions','.tif');
disp("Resizing images and labels, converting to categorical label form...")
imds = resizeImages(imds, sz, outputDir);
pxds = resizePixelLabels(pxds, sz, outputDir);

%% Segment
pxdsResults = semanticseg(imds,net);
for n = 1:length(imds.Files)
 [I, info] = readimage(imds,n);
 B = labeloverlay(I,pxdsResults.readimage(n),'Transparency',0.2);
 imwrite(B, [info.Filename,'out'  ,'.tif'])

end
