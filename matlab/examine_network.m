clear all; clc;

load('/home/tyson/Raiden/networks/cache/2019-07-28_114235/alexnet_2019-07-28_114235.mat');
load('/home/tyson/Raiden/networks/cache/alexnet_2019-07-30_121421/alexnet_2019-07-30_121421.mat');

% analyzeNetwork(net)
figure
plot(net)
subplot_tight(net)

    subplot(1,2,1)
    C = semanticseg(im, net);
    B = labeloverlay(im,C,'Colormap',cmap,'Transparency',0.4);
    imshow(B);
    pixelLabelColorbar(cmap, classNames);
    [~, filename, ext] = fileparts(info.Filename);
    title(filename,'Interpreter','none','FontSize',6);




%% Visualize activations
im = imIdx = randperm(numel(imdsTest.Files),2); %randi(length(imdsTest.Files)); 

act1 = activations(net,im,'conv1');
sz = size(act1);
act1 = reshape(act1,[sz(1) sz(2) 1 sz(3)]);
I = imtile(mat2gray(act1),'GridSize',[8 12]);
imshow(I)


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