function output = findEvents(imds, eventID, blankFramesToIgnore)
output = [];

strokeEntries = indexLabel(imds, eventID);
% ToDo: What if no strokes single stroke?
index = 1; % by def
output = [];
if numel(strokeEntries) == 1
    output = [strokeEntries(1) 1];
elseif numel(strokeEntries > 1)
    
    for i=1 : numel(strokeEntries)-1
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
            output = [output;[strokeEntries(i-(index-1)), ...
                lastOfEvent-firstOfEvent] ];
            index=1; % reset
        end
    end
    
end
% numel<1 gives output[]
end