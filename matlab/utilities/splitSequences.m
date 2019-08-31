function[index1, index2] = splitSequences(resizedImageFolders, splitPercent, ext)
% This function used to create an index for the training and
% testing data based on the requested split percentage. 
%
% INPUT : resizedImageFolders = A list of folders containing image sequences 
%         splitPercent = [0-1] value of the original data to assign to index1
%
% OUTPUT: index1 = The index of the sequence images to use for training
%         index2 = The index of the sequence images to use for testing 
    if nargin < 3
        ext = '.png';
    end
    if (splitPercent==0)
        index2 = [];
        index1 = 1:length(resizedImageFolders);
    elseif (splitPercent==1)
        error('splitPercent=1 means no images are used for training!')
    else
        numberOfSequences = length(resizedImageFolders);
        sequenceLengths = zeros(1, numberOfSequences);

        % get the number of tif files in each folder
        parfor i = 1:numberOfSequences
            folder = strcat(resizedImageFolders{i},"/*",ext);
            sequenceLengths(i) = numel(dir(folder));
        end

        if ~min(sequenceLengths(:))
            error(['No files found! Check file format: images must be ',ext])
        end
        
        totalFrames = sum(sequenceLengths);
        framesToFill = round(splitPercent * totalFrames);

        % prepare the viable candidate sequences
        candidateIndex = find(sequenceLengths < framesToFill);
        index2 = [];

        while ~isempty(candidateIndex)
            % pick a random sequence
            chosenSequence = candidateIndex(randi(length(candidateIndex)));
            index2 = [ index2 chosenSequence];

            % subtract the added sequence length
            chosenSequenceLength = sum(sequenceLengths(chosenSequence));
            framesToFill = framesToFill - chosenSequenceLength;

            % recheck which sequences are short enough
            candidateIndex = find(sequenceLengths < framesToFill);

            % remove the indices already selected
            candidateIndex = setdiff(candidateIndex, index2);
        end

        index2 = sort(nonzeros(index2))';
        index1 = setdiff(1:numberOfSequences, index2);
        assert(numberOfSequences-numel(index1)-numel(index2)==0);
    end
end
