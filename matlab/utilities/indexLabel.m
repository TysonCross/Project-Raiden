function labelList = indexLabel(outputDs, labelID, opt)
    
    imageSize = size(outputDs.readimage(1));
    y = imageSize(1);
    x = imageSize(2);
    threshold = round(0.005 * x * y);
    
    if nargin == 2
        labelList = find(occuranceFrames);
    elseif(opt == 'logical')
        labelList = occuranceFrames;
    else
        error('Invalid option');
    end
    
    numImages = numel(outputDs.Files);
    occuranceFrames = zeros(1,numImages);
    for i = 1:numImages 
        tmp = outputDs.readimage(i);
        indx = tmp(:)==labelID;
        if nnz(indx) > threshold: % any frame has the event, do
            occuranceFrames(i) = 1; % true
        end
        %else load new image
    end
    
end
