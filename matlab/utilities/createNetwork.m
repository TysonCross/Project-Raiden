function net = createNetwork(networkType, cachePath, labelWeights)
disp("Setting up Network...")

    loadLabels;
    numClasses = numel(labelNames);
    imageSize = getResolution(networkType);
    
    % Balance class weightings
    if (exist('labelWeights','var'))
        pxLayer = pixelClassificationLayer('Name','labels',...
            'Classes',labelNames,'ClassWeights',labelWeights);
    else
        pxLayer = pixelClassificationLayer('Name','labels',...
            'Classes',labelNames);
    end


    switch networkType
        case 'fcn8s' % fully connected CNN, based on vgg16 weighting
            lgraph = fcnLayers(imageSize, numClasses);   

            lgraph = removeLayers(lgraph,'pixelLabels');
            lgraph = addLayers(lgraph, pxLayer);
            lgraph = connectLayers(lgraph,'softmax','labels');
            net = lgraph;

            clear lgraph

        case 'alexnet'
            lgraph = helperAlexNet(numClasses, pxLayer);
            net = lgraph;

            clear idx layers upscore bias weights upscore conv1New
%             clear conv1 lgraph

        case 'deeplabv3'
            lgraph = helperDeeplabv3PlusResnet18([imageSize 3], ...
                numClasses);
            lgraph = replaceLayer(lgraph,"classification", pxLayer);
            net = lgraph;

%             clear lgraph

        case 'segnet'
            lgraph = segnetLayers([imageSize 3], numClasses, 'vgg16');
            lgraph = replaceLayer(lgraph,"pixelLabels", pxLayer);
            net = lgraph;

%             clear lgraph

        case 'u-net'


            % create a new unet
            encoderDepth = 4;
            lgraph = unetLayers([imageSize 3], numClasses, ...
                'EncoderDepth',encoderDepth);
            lgraph = replaceLayer(lgraph,"Segmentation-Layer", pxLayer);

            transferWeights = false;
            doNormalisation = false;

            if ~doNormalisation
                imageInputLayerName = 'ImageInput';
                newLayer = imageInputLayer([imageSize 3],'Name',imageInputLayerName,'Normalization','none');
                lgraph = replaceLayer(lgraph,"ImageInputLayer",newLayer);
            end

            if transferWeights
                % load pretrained unet
                pretrainedNet = load('/home/tyson/Raiden/networks/pretrainedNetwork/multispectralUnet.mat');
                pretrainedNet = layerGraph(pretrainedNet.net);

                % transfer weights
                for ii = 1:length(lgraph)
                  if isprop(lgraph(ii), 'Weights') % Does layer l have weights?
                    lgraph(ii).Weights = pretrainedNet.Layers(ii).Weights;
                  end
                  if isprop(lgraph(ii), 'Bias') % Does layer l have biases?
                    lgraph(ii).Bias = pretrainedNet.Layers(ii).Bias;
                  end
                end
            end

            net = lgraph;

%             clear lgraph layers pretrainedNet


        case 'vgg16'
            net = vgg16;
            layersTransfer = net.Layers(1:end-3);
            lgraph = [
                layersTransfer
                fullyConnectedLayer(numClasses, ...
                    'Name','fc_new', ...
                    'WeightLearnRateFactor',20,...
                    'BiasLearnRateFactor',20)
                softmaxLayer('Name','prob')
                pxLayer ];
            net = lgraph;

%             clear layersTransfer lgraph

        case 'googlenet'
            net = googlenet;
            lgraph = layerGraph(net);
            newLayer = fullyConnectedLayer(numClasses, ...
                'Name','fc_new', ...
                'WeightLearnRateFactor',10, ...
                'BiasLearnRateFactor',10);       
            lgraph = replaceLayer(lgraph,'loss3-classifier',newLayer);
            lgraph = replaceLayer(lgraph,'output',pxLayer);
            net = lgraph;

            % freeze early network
            layers = lgraph.Layers;
            connections = lgraph.Connections;
            layers(1:10) = freezeWeights(layers(1:10));
            lgraph = createLgraphUsingConnections(layers,connections);
            net = lgraph;

%             clear layers connections lgraph newLayer

        case 'inceptionresnetv2'
            net = inceptionresnetv2;
            lgraph = layerGraph(net);
            newLayer = fullyConnectedLayer(numClasses, ...
                'Name','fc_new', ...
                'WeightLearnRateFactor',10, ...
                'BiasLearnRateFactor',10);       
            lgraph = replaceLayer(lgraph,...
                'predictions',newLayer);
            lgraph = replaceLayer(lgraph, ...
                'ClassificationLayer_predictions',pxLayer);

            % freeze pretrained network
            layers = lgraph.Layers;
            connections = lgraph.Connections;
            layers(1:end-3) = freezeWeights(layers(1:end-3));
            lgraph = createLgraphUsingConnections(layers,connections);
            net = lgraph;

%             clear layers connections lgraph newLayer

        otherwise
            error('Error: Invalid network name specified')
    end

%     clear pxLayer numClasses

    networkStatus.trained = 0;
    save(fullfile(cachePath,'network'),...
        'net','networkStatus','imageSize');
    disp("Network created") 
end