function output = findEvents(imds, eventID, blankFramesToIgnore)
% This function is the underlying function for any find* function and returns 
% the frames that contained the requested label. The blankFramesToIgnore option
% determines the number of frames between frames with labels to accept as part 
% of an event.
%
% INPUT:
%         IMDS: Pixel label datastore normally the output of semantic segmentor
%         EVENTID: The event ID to look for in a frame 
%         BLANKFRAMESTOIGNORE: The number of blank frames before the event is 
%                              deemed to have ended 
% OUTPUT: 
%         OUTPUT: array containing events, where the first column is the start
%                 frame and the second column is the frame duration
%
%                 eg, [startFrame frameDuration]
% Note:  numel<1 gives output[]
%#ok<*AGROW>

    strokeEntries = indexLabel(imds, eventID);
    index = 1;
    output = [];
    if numel(strokeEntries) == 1
        output = [strokeEntries(1) 1];
    elseif numel(strokeEntries) > 1

        for i=1:numel(strokeEntries)-1
            currentFrame = strokeEntries(i);
            offset = currentFrame+blankFramesToIgnore+1;
            % check if next in still part of sequence
            if ( strokeEntries(i+1) <=  offset )
                index=index+1;
                if i==(numel(strokeEntries)-1)
                    lastOfEvent = strokeEntries(i+1);
                    firstOfEvent = strokeEntries(i-(index-2)) ;
                    output = [output; ...
                        [ strokeEntries(i-(index-2)), ...
                        (lastOfEvent- firstOfEvent+1)] ]; 
                end
            else
                lastOfEvent = strokeEntries(i);
                firstOfEvent = strokeEntries(i-(index-1));
                output = [output; [strokeEntries(i-(index-1)), ...
                    lastOfEvent - firstOfEvent+1] ];
                index = 1; % reset
            end
        end
    end
    
end