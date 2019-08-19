%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                         FINDEVENTFRAMES.M
% The input to this function is the output of the semantic segmenter. Each frame
% is evaluated to determine if a label occurs in the frame.
% INPUT:
%        imds: The output label datastore produced by the semantic segmenter
%        label: The label value that should be checked for
%        before:(optional) value that determines up to which frame to check for the label
% OUTPUT:
%        occuranceFrames: The frame numbers where the label is present
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function occuranceFrames = findEventFrames(imds, label, before)
clear occuranceFrames;
occuranceFrames = [];
if ~exist('before','var')
    endVal = numel(imds.Files);
else
    endVal = before;
end
for i=1 : endVal
    tmp = imds.readimage(i);
    if any(tmp(:) == label) % stroke
        occuranceFrames = [occuranceFrames i]; %#ok<AGROW>
    end
end
end
