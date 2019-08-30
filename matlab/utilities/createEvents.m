function eventsCellArray = createEvents(imds, minEventSize)
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
%
% Note: arrays are allowed to increase in size in this script.
%#ok<*AGROW>

if nargin == 1
    minEventSize = 1;
end

candidateEvents = getCandidateEvents(imds);
strokeIndices = indexLabel(imds, double(Label.stroke), 'logical');

% remove the 1 frame events (normally noise)
if ~isempty(candidateEvents)
    indices = candidateEvents(:,2)<= minEventSize;
    candidateEvents(indices,:) = [];
end
if ~isempty(candidateEvents) 
    for i=1:size(candidateEvents,1)
        eventsCellArray(i).start = candidateEvents(i,1);
        eventsCellArray(i).duration = candidateEvents(i,2);

        % For an event with a stroke, all the lightning frames before the 
        % stroke are used. For an attempted leader, the first half of the 
        % frames are used
        strokeIndicesPerEvent = strokeIndices(eventsCellArray(i).start : ...
            eventsCellArray(i).start + eventsCellArray(i).duration);
        
        if ~any(strokeIndicesPerEvent)
                        eventsCellArray(i).type = 'Attempted leader'; 
            earlyFrames = round((eventsCellArray(i).start + ...
                eventsCellArray(i).duration)/2);
            subIMDS = imds.subset(eventsCellArray(i).start:earlyFrames);
            eventsCellArray(i).direction = directionFromClusters(subIMDS);
        else
           eventsCellArray(i).type = 'Attachment event';
            % assign stroke frames
            endFrame = eventsCellArray(i).duration + eventsCellArray(i).start -2;
            indices = eventsCellArray(i).start+1:endFrame;
            subIMDS = imds.subset(indices);
            dir = directionFromClusters(subIMDS);
            eventsCellArray(i).direction = dir;
            eventsCellArray(i).strokes = num2cell(findEvents(subIMDS, 2, 0));
%             msg = strcat('Stroke frame: ', string(eventsCellArray(i).strokes{1}));
%             disp(msg)
%             msg = strcat('Stroke duration: ', string(eventsCellArray(i).strokes{2}));
%             disp(msg)
        end
    end
else
    eventsCellArray = [];
end

end