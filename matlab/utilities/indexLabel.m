function labelList = indexLabel(outputDs,labelID,opt)

    numImages=numel(outputDs.Files);
    occuranceFrames=zeros(1,numImages);
    for i=1 : numImages 
        tmp = outputDs.readimage(i);
        if any(tmp(:) == labelID) % any frame has the event, do
            occuranceFrames(i) = 1; % true
        end
        %else load new image
    end
    if nargin == 2
           labelList = find(occuranceFrames);
       
    elseif(opt == 'logical')
          labelList = occuranceFrames;
    else
        error('Invalid option');
    end
    
end
