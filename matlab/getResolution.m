function imageSize = getResolution(network)
    switch network
            case 'fcn8s'
                imageSize = [227 227];

            case 'alexnet'
                imageSize = [227 227];

            case 'vgg16'
                imageSize = [224 224];

            case 'googlenet'
                imageSize = [224 224];

            case 'inceptionresnetv2'
                imageSize = [299 299];

            otherwise
                warning('Invalid network name: assuming resolution of 227x227')
                imageSize = [227 227];
    end
end