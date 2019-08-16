%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                     CREATEEVENTS.M
% Create an array of events for a given input imds. each event has:
% Start: The frame where the event starts 
% Length: The number of frames for which the event persists
% Type: Stroke or attempted leader
% StrokeFrames: The frame numbers that have the stroke label
%
% INPUT: label data store
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function eventsCellArray = createEvents(imds)
    candidateEvents = getCandidateEvents (imds);
    strokeIndices = getStrokeIndices(imds);
    % assign length and start values
    for i=1:size(candidateEvents,1)
       eventsCellArray(i).start = candidateEvents(i,1);
       eventsCellArray(i).length = candidateEvents(i,2);
       % assign type
       strokeIndicesPerEvent = strokeIndices(eventsCellArray(i).start : ...
           eventsCellArray(i).start + eventsCellArray(i).length);
       if ~ any(strokeIndicesPerEvent)
            eventsCellArray(i).type = 'Attempted leader';
       else
           eventsCellArray(i).type = 'Attachment event';
           % assign stroke frames
           eventsCellArray(i).strokeFrames = find(strokeIndicesPerEvent);
       end
    end
end