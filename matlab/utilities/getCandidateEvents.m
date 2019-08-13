function candidateEvents = getCandidateEvents (imds)
% Finds the events that are surrounded by gaps or a gap and a 
% start/end of the seq
% Output [startFrame Duration]
    indexedLightning = getLightningIndices(imds);
    indexedStrokes = getStrokeIndices(imds);
    totalIndices = indexedLightning + indexedStrokes;
    gapLocations = findGaps(totalIndices,2);
    %% Get the GAPS 
    candidateEvents = [];
    %handle begin to first gap
    if gapLocations(1,1) ~= 1
        %First candidate will be from the start of the array
        candidateStartFrame = 1;
        candidateStopFrame = gapLocations(1,1);
        diff = candidateStopFrame - candidateStartFrame;
        candidateEvents = [candidateStartFrame, diff];
    end
    for i =1 : size(gapLocations,1)-1
        candidateStartFrame = gapLocations(i,1)+gapLocations(i,2)+1;
        candidateStopFrame = gapLocations(i+1,1)-1;
        diff = candidateStopFrame - candidateStartFrame;
        candidateEvents = [candidateEvents; candidateStartFrame, diff];
    end
    %handle the last gap
    if ~(gapLocations(end,1)+gapLocations(end,2) == size(totalIndices))
        candidateStartFrame = gapLocations(end,1)+gapLocations(end,2)+1;
        candidateStopFrame = totalIndices(end);
        diff = candidateStopFrame - candidateStartFrame;
        candidateEvents = [candidateEvents; candidateStartFrame, diff];
    end
         
       
end