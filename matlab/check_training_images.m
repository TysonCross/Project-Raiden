%% SINGLE IMAGES TEST

% Single Images Check
imIdx = randperm(numel(imdsTest.Files),2); %#ok<*UNRCH> %randi(length(imdsTest.Files)); 
figure(1)
for i = 1:2
    subplot(2,2,i)
    [I,info] = readimage(imdsTest,imIdx(i));
    C = semanticseg(I, net);
    B = labeloverlay(I,C,'Colormap',cmap,'Transparency',0.4);
    imshow(B);
    pixelLabelColorbar(cmap, labelNames);
    [~, filename, ext] = fileparts(info.Filename);
    title(filename,'Interpreter','none','FontSize',6);
end
for i = 3:4
    subplot(2,2,i)
    [I,info] = readimage(imdsTest,imIdx(i-2));
    C = semanticseg(I, net);
    expectedResult = readimage(pxdsTest,imIdx(i-2));
    actual = uint8(C);
    expected = uint8(expectedResult);
    imshowpair(actual, expected, 'diff')
    title('Actual vs Expected');
end

%% Visualize activations

im = readimage(imdsTest,randi(length(imdsTest.Files)));

act1 = activations(net,im,'conv3');
sz1 = size(act1);
act1 = reshape(act1,[sz1(1) sz1(2) 1 sz1(3)]);
I = imtile(mat2gray(act1),'GridSize',[8 12]);
imshow(I)

act1ch32 = act1(:,:,:,32);
act1ch32 = mat2gray(act1ch32);
act1ch32 = imresize(act1ch32,imageSize);

I = imtile({im,act1ch32});
imshow(I)