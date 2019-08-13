function results = findGaps(arrayOfSummedEvents, blankLength)
    if nargin == 1
        blankLength=3;
    end
    transitionPoints = diff([0 arrayOfSummedEvents == 0 0]); %1> becomes 0 -1 away from zero
    startOfRun = find(transitionPoints == 1);
    endOfRun = find(transitionPoints == -1); 
    runlengths = endOfRun - startOfRun;
    %keep only those runs of length 4 or more:
    startOfRun(runlengths < blankLength) = [];
    endOfRun(runlengths < blankLength) = [];
    %expand each run into a list indices:
    results = [startOfRun ; endOfRun-startOfRun]';
    %indices = arrayfun(@(s, e) s:e-1, startOfRun, endOfRun, 'UniformOutput', false);
end
