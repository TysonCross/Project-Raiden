function candidateEvents = getCandidateEvents (imds)
% Finds the events that are surrounded by 2 gaps or a gap and a 
% start/end of the seqeunce of frames. For example the input could look like
%   [ ... gap EVENT gap ... ]
%   [Event gap ...]
%   [... gap Event]
%
% OUTPUT:
%        Array where the first column is the startFrames and the 
%        second column is the number of frames that contain the event
%        ie,  [startFrame Duration]

    indexedLightning = getLightningIndices(imds);
    indexedStrokes = getStrokeIndices(imds);
    totalIndices = indexedLightning + indexedStrokes;
    gapLocations = findGaps(totalIndices,2);
    
    % Get the GAPS 
    candidateEvents = [];
    %handle begin to first gap
    if ~isempty(gapLocations)
        if gapLocations(1,1) ~= 1
            %First candidate will be from the start of the array
            candidateStartFrame = 1;
            candidateStopFrame = gapLocations(1,1);
            diff = candidateStopFrame - candidateStartFrame;
            candidateEvents = [candidateStartFrame, diff];
        end
        for i =1 : size(gapLocations,1)-1
            candidateStartFrame = gapLocations(i,1)+gapLocations(i,2);
            candidateStopFrame = gapLocations(i+1,1)-1;
            diff = candidateStopFrame - candidateStartFrame;
            candidateEvents = [candidateEvents; candidateStartFrame, diff+1];
        end
        %handle the last gap
        if ~(gapLocations(end,1)+gapLocations(end,2) == size(totalIndices,2))
            candidateStartFrame = gapLocations(end,1)+gapLocations(end,2);
            if candidateStartFrame < length(totalIndices)
                candidateStopFrame = length(totalIndices);
                diff = candidateStopFrame - candidateStartFrame;
                candidateEvents = [candidateEvents; candidateStartFrame, diff];
            end
        end
    else % no gaps without leader/stroke
        candidateEvents = [candidateEvents; 1, length(indexedLightning)-1];
        
    end