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
