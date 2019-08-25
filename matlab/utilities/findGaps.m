function results = findGaps(arrayOfSummedEvents, blankLength)
% Function that finds frames that have no lightning in frame where blankLength 
% determines the number of blank frames that constitues the end of a lightning
% event.  
%
% INPUT:  
%         ARRAYOFSUMMEDEVENTS:Takes an array where a presence of lightning array
%                             for the frame sequence is given ie ( 0 1 2 0 1 ).
%                             This array is formed by summing the binary 
%                             array indicating lightning frames and the binary  
%                             array indicating stroke frames.
%         BLANKLENGTH: The number of blank frames that should surround a 
%                      'complete' event.
% OUTPUT:
%         RESULTS: An array where the first column is the start of a candidate 
%                  event and the second column is the number of frames in the 
%                  candidate event.

    if nargin == 1
        blankLength=3;
    end
    
    transitionPoints = diff([0 arrayOfSummedEvents==0 0]); 
    
    % 1 shows it goes to 0; -1 shows is goes away from zero
    startOfRun = find(transitionPoints == 1);
    endOfRun = find(transitionPoints == -1); 
    runlengths = endOfRun - startOfRun;
    
    %keep only those runs of length blankLength or more:
    startOfRun(runlengths < blankLength) = [];
    endOfRun(runlengths < blankLength) = [];

    results = [startOfRun ; endOfRun-startOfRun]';
end
