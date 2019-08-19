trainedUnet_url = 'https://www.mathworks.com/supportfiles/vision/data/multispectralUnet.mat';
downloadTrainedUnet(trainedUnet_url,'/home/tyson/Raiden/networks/pretrainedNetwork/');


modelfile = '~/Raiden/networks/unet.onnx';
loadLabels;
net = importONNXNetwork(modelfile,'OutputLayerType','pixelclassification','Classes',labelIDs_scalar)
protofile = '/home/tyson/Raiden/networks/pretrainedNetwork/u-net-release/phseg_v5-train.prototxt';
datafile = '/home/tyson/Raiden/networks/pretrainedNetwork/u-net-release/phseg_v5.caffemodel';
net = importCaffeNetwork(protofile,datafile) 
layers = importCaffeLayers(protofile)
sz = imageSize;

y = sz(1);
x = sz(2);

    rez = strcat(string(x),'x',string(y));
    imagePath = fullfile(imagePath,'resized',rez,'label');
    
    reset(pxdsTrain)
    N = length(pxdsTrain.Files);
    r = 1;
    imageList = string(zeros(1,N));
    
%      while hasdata(pxds)
        [C, info] = read(pxdsTrain);
        [~, filename, ext] = fileparts(info.Filename);
        
        str = 'mask';
        maskIdx = strfind(filename, str);
        filename = strcat(filename(1:maskIdx-1),"label",filename(maskIdx+length(str):end));
        
        if ~exist(fullfile(imagePath,strcat(filename,ext)), 'file') 
            
            % Convert from categorical to uint8.
            % (RGB-class label association -> per-pixel integer value)
            L = uint8(C);
            
            I = imread('/home/tyson/Raiden/data/resized/227x227/image/2017-02-10_163916_020.00003261.tif')
            figure(1)
            imshow(I)
            figure(2)
            imshow(L)

            % Resize the data using 'nearest' interpolation to preserve labelIDs.
            L = imresize(L,[y x],'nearest');

            % Write the data to disk.
%             imwrite(L,fullfile(imagePath,strcat(filename,ext)));
            
        end
        
        imageList(r) = fullfile(imagePath,strcat(filename,ext));
        progressbar(r/N);
%     end

    progressbar(1);
    ClassNames = pxds.ClassNames;
    labelIDs_Scalar = 1:numel(ClassNames);
    pxds = pixelLabelDatastore(imageList,ClassNames,labelIDs_Scalar);
    
    
imagefilename = '/mnt/Shield/Raiden/data/sequences/test/dark/tif/2017-10-21_171820_000.00000240.tif';
image = imread(imagefilename);
subplot(1, 2, 1);
imshow(image);
title('Original Image', 'FontSize', 20);
image = im2double(image);
image = (image - mean2(image))./std2(image);
image = im2uint8(rgb2gray(image));
subplot(1, 2, 2);
imshow(image);
title('Output image', 'FontSize', 20);
    
    spectrumPlot(image)
    sfPlot(image)
    
unetLayers