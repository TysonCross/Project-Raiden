
%% Import vairables
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
outputDir = app.EditField_3.Value;
sz = net.Layers(1).InputSize(1:2);
getLabelIDs;
setupColors;

%% Resize
imds = imageDatastore(sequenceDir);
pxds = pixelLabelDatastore(labelDir,...
    classNames,labelIDs,'FileExtensions','.tif');
disp("Resizing images and labels, converting to categorical label form...")
imds = resizeImages(imds, sz, [outputDir '/img/'] );
pxds = resizePixelLabels(pxds, sz, [outputDir '/label/']);

%% Create output folders
  mkdir(strcat(outputDir,'/output/'));
  if(app.ComparewithexpectedCheckBox.Value)
    mkdir(strcat(outputDir,'/compare/'))
  end

%% Segment data
resultPixelLabels = semanticseg(imds,net); %Label the data
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
        numClasses = numel(classNames);
        expectedResult = readimage(pxds,n);
        actual = uint8(resultPixelLabels.readimage(n))*(255/numClasses);
        expected = uint8(expectedResult)*(255/numClasses);
        diffImage = imfuse(actual, expected, 'diff');
        str = strcat(outputDir,'/compare/', name.insertAfter(21,'_compare'), '.tif');
        imwrite(diffImage, str);
        
    end
    imwrite(segImage, strcat(outputDir,'/output/', name.insertAfter(21,'_out'),  '.tif'));
    
    
end


disp('Done');



%if MakeOverlay
%if(app.MakeoverlayCheckBox.Value)