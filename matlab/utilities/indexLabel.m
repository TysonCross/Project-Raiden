function labelList = indexLabel(imds, labelID, opt)
% This function returns an array,with a binary value for each frame 
% containing the specified label .

if numel(imds.Files)
    imageSize = size(imds.readimage(1));
    y = imageSize(1);
    x = imageSize(2);
    if labelID == double(Label.leader)
        threshold = round(0.0025* x * y);
    else
        threshold = 0;
    end
else
    threshold = 0;
end

    numImages = numel(imds.Files);
    occurrenceFrames = zeros(1,numImages);
    for i=1:numImages 
        im = imds.readimage(i);
        if nnz(im(:)==labelID) > threshold % any frame has the event, do
            occurrenceFrames(i) = 1; % true
        end
    end
    
    if nargin == 2
        labelList = find(occurrenceFrames);
    elseif strcmp(opt,'logical')
        labelList = occurrenceFrames;
    else
        error('Invalid option');
    end
    
end
