%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                             SPLITDATA.M
% [trainIndex, test] = splitData(imageFolders, splitPercent)
% splitData is a function used to create an index for the training and
% testing data based on the requested split percentage. This allows the for
% example, testing the 'true' performance of a CNN, on unseen footage.
%
% INPUT : imageFolders = A list of folders containg image sequences 
%         splitPercent = 0 to 1 value of the original data to use as 
%                        training data
%
% OUTPUT: trainIndex = The index of the seqeunce images to use for training
%         test       = The index of the sequence images to use for testing 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[trainIndex, testIndex] = splitData(imageFolders, splitPercent)

    ext = '.png';
    if (splitPercent==0)
        testIndex = [];
        trainIndex = 1:length(imageFolders);
    elseif (splitPercent==1)
                error('splitPercent = 1 means no images are used for training.')
    else
        numberOfSequences = length(imageFolders);
        sequenceLengths = zeros(1, numberOfSequences);

        % get the number of tif files in each folder
        parfor i = 1:numberOfSequences
            sequenceLengths(i) = numel(dir([imageFolders{i},'/*',ext]));
        end

        if ~min(sequenceLengths(:))
            error(['No files found! Check file format: images must be ',ext])
        end
        
        totalFrames = sum(sequenceLengths);
        framesToFill = round(splitPercent * totalFrames);

        % prepare the viable candidate sequences
        candidateIndex = find(sequenceLengths < framesToFill);
        testIndex = [];

        while ~isempty(candidateIndex)
            % pick a random sequence
            chosenSequence = candidateIndex(randi(length(candidateIndex)));
            testIndex = [ testIndex chosenSequence];

            % subtract the added sequence length
            chosenSequenceLength = sum(sequenceLengths(chosenSequence));
            framesToFill = framesToFill - chosenSequenceLength;

            % recheck which sequences are short enough
            candidateIndex = find(sequenceLengths < framesToFill);

            % remove the indices already selected
            candidateIndex = setdiff(candidateIndex, testIndex);
        end

        testIndex = sort(nonzeros(testIndex))';
        trainIndex = setdiff(1:numberOfSequences, testIndex);
        assert(numberOfSequences-numel(trainIndex)-numel(testIndex)==0);
    end
end
