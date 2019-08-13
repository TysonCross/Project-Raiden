function lgraph = helperAlexNet(numClasses, pxLayer)
% pretrained alexnet trained on ImageNet

    net = alexnet;
    layers = net.Layers;

    % fc6 is layers 17
    idx = 17;
    weights = layers(idx).Weights';
    weights = reshape(weights, 6, 6, 256, 4096);
    bias = reshape(layers(idx).Bias, 1, 1, []);
    layers(idx) = convolution2dLayer(6, 4096, ...
        'NumChannels', 256, 'Name', 'fc6');
    layers(idx).Weights = weights;
    layers(idx).Bias = bias;

    % fc7 is layers 20
    idx = 20;
    weights = layers(idx).Weights';
    weights = reshape(weights, 1, 1, 4096, 4096);
    bias = reshape(layers(idx).Bias, 1, 1, []);
    layers(idx) = convolution2dLayer(1, 4096, ...
        'NumChannels', 4096, 'Name', 'fc7');
    layers(idx).Weights = weights;
    layers(idx).Bias = bias;

    conv1 = layers(2);
    conv1New = convolution2dLayer( ...
        conv1.FilterSize, conv1.NumFilters, ...
        'Stride', conv1.Stride, ...
        'Padding', [100 100], ...
        'NumChannels', conv1.NumChannels, ...
        'WeightLearnRateFactor', conv1.WeightLearnRateFactor, ...
        'WeightL2Factor', conv1.WeightL2Factor, ...
        'BiasLearnRateFactor', conv1.BiasLearnRateFactor, ...
        'BiasL2Factor', conv1.BiasL2Factor, ...
        'Name', conv1.Name);
    conv1New.Weights = conv1.Weights;
    conv1New.Bias = conv1.Bias;

    layers(2) = conv1New;
    layers(end-2:end) = [];

    upscore = transposedConv2dLayer(64, numClasses, ...
        'NumChannels', numClasses,...
        'Stride', 32,...
        'Name', 'upscore');

    layers = [
            layers
            convolution2dLayer(1, numClasses, 'Name', 'score_fr');
            upscore
            crop2dLayer('centercrop', 'Name', 'score')
            softmaxLayer('Name', 'softmax')
            pxLayer
            ];

    lgraph = layerGraph(layers);
    lgraph = connectLayers(lgraph, 'data', 'score/ref');
end