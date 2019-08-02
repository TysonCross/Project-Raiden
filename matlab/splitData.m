function[trainIndex, testIndex] = splitData(imageFolders, splitPercent)
  
    if (splitPercent==0)      
        trainIndex = [];
        testIndex = 1:length(imageFolders);
    else
        
        numberOfSequences = length(imageFolders);
        sequenceLengths = zeros(1, numberOfSequences);

        % get the number of tif files in each folder
        for i = 1:numberOfSequences
            sequenceLengths(i) = numel(dir([imageFolders{i} '*.tif']));
        end

        totalFrames = sum(sequenceLengths);
        framesToFill = round(splitPercent * totalFrames);

        % prepare the viable candidate sequences
        candidateIndex = find(sequenceLengths < framesToFill);
        testIndex = [];
        
        while ~isempty(candidateIndex)
            % pick a random sequence
            testIndex = [ testIndex ...
                candidateIndex(randi(length(candidateIndex)))];

            % subtract the added sequence length 
            framesToFill = framesToFill - sum(sequenceLengths(testIndex));
            
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