function imageSize = getResolution(network)
        % [ height x width ]

    switch network
            case 'fcn8s'
                imageSize = [227 227];

            case 'alexnet'
                imageSize = [227 227];
                
            case 'deeplabv3'
                imageSize = [256 256];
%                 imageSize = [256 512];
                
            case 'segnet'
                imageSize = [256 256];

            case 'u-net'
                imageSize = [256 256];
                
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