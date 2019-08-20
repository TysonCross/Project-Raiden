%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                     CREATEEVENTS.M
% Create an array of events for a given input imds. each event has:
% Start: The frame where the event starts 
% Length: The number of frames for which the event persists
% Type: Stroke or attempted leader
% StrokeFrames: The frame numbers that have the stroke label
%
% INPUT: 
%       imds = label data store
%       minEventSize = the smallest event duration to consider
% OUTPUT:
%       event > which can be dot referenced to obtain the metrics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Allow arrays to increase in size as there are very few intances of this.
%#ok<*AGROW>
function eventsCellArray = createEvents(imds, minEventSize)
    if nargin == 1
        minEventSize = 1;
    end
    candidateEvents = getCandidateEvents (imds);
    strokeIndices = getStrokeIndices(imds);
    % remove the 1 frame events (normally noise)
    indices = candidateEvents(:,2)<= minEventSize;
    candidateEvents(indices,:) = [];
    if ~isempty(candidateEvents) 
        for i=1:size(candidateEvents,1)
   
            eventsCellArray(i).start = candidateEvents(i,1);
            eventsCellArray(i).duration = candidateEvents(i,2);
            % assign type

% For an event with a stroke the all lightning frames before the
% stroke are used. For an attempted leader the first 50 percent are of
% interest.
            strokeIndicesPerEvent = strokeIndices(eventsCellArray(i).start : ...
                eventsCellArray(i).start + eventsCellArray(i).duration);
            if ~ any(strokeIndicesPerEvent)
                eventsCellArray(i).type = 'Attempted leader'; 
                earlyFrames = ...
                 round((eventsCellArray(i).start+eventsCellArray(i).duration)/2);
                subIMDS = imds.subset(eventsCellArray(i).start:earlyFrames);
                [~,dir] = directionFromClusters(subIMDS);
                eventsCellArray(i).direction = dir;
            else
                eventsCellArray(i).type = 'Attachment event';
                % assign stroke frames
                indices = eventsCellArray(i).start:eventsCellArray(i).duration;
                subIMDS = imds.subset(indices);
                dir = directionFromClusters(subIMDS);
                eventsCellArray(i).direction = dir;
                %eventsCellArray(i).strokes = num2cell(findStokeEvents(subEventDS),2);
                
            end
        end
    end
end