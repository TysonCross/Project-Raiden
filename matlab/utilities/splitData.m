function[trainIndex, testIndex] = splitData(imageFolders, splitPercent)
  
    if (splitPercent==0)      
        testIndex = [];
        trainIndex = 1:length(imageFolders);
    else
        
        numberOfSequences = length(imageFolders);
        sequenceLengths = zeros(1, numberOfSequences);

        % get the number of tif files in each folder
        parfor i = 1:numberOfSequences
            sequenceLengths(i) = numel(dir([imageFolders{i} '/*.tif']));
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
%         disp(['Test frames: ', string(sum(sequenceLengths(testIndex)))]);
%         disp(['Train frames: ', string(sum(sequenceLengths(trainIndex)))]);
%         disp(['Test is ', string(sum(sequenceLengths(testIndex))/sum(sequenceLengths)*100),'%']);
        assert(numberOfSequences-numel(trainIndex)-numel(testIndex)==0);
    end
end