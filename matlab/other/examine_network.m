clear all; clc;

load('/home/tyson/Raiden/networks/cache/alexnet_2019-08-04_011521/network.mat');
load('/home/tyson/Raiden/networks/cache/deeplabv3_2019-08-08_073519/network.mat');
load('/home/tyson/Raiden/networks/cache/segnet_2019-08-09_083513/network.mat');

% analyzeNetwork(net)
figure
plot(net)
subplot_tight(net)

loadLabels;
setupColors;
I = imread('/mnt/Shield/Raiden/data/sequences/2017-02-10_163357/2017-02-10_163357_010/tif/2017-02-10_163357_010.00000255.tif');
im = uint8(I/256);
im = imresize(im,[227 227]);
im = imresize(im,[256 256]);



    subplot(1,2,1)
    C = semanticseg(im, net);
    B = labeloverlay(im,C,'Colormap',cmap,'Transparency',0.4);
    imshow(B);
    pixelLabelColorbar(cmap, labelNames);
%     [~, filename, ext] = fileparts(info.Filename);
%     title(filename,'Interpreter','none','FontSize',6);


%% Visualize activations
% im = imIdx = randperm(numel(imdsTest.Files),2); %randi(length(imdsTest.Files)); 

act1 = activations(net,im,'conv3_3');
sz = size(act1);
act1 = reshape(act1,[sz(1) sz(2) 1 sz(3)]);
I_a = imtile(mat2gray(act1),'GridSize',[16 16]);
figure
imshow(I_a)


act1 = activations(net,im,'upscore');

sz = size(act1);
act1 = reshape(act1,[sz(1) sz(2) 1 sz(3)]);
I = imtile(mat2gray(act1),'GridSize',[1 6]);
imshow(I)

act1ch32 = act1(:,:,:,32);
act1ch32 = mat2gray(act1ch32);
act1ch32 = imresize(act1ch32,imgSize);

I = imtile({im,act1ch32});
imshow(I)