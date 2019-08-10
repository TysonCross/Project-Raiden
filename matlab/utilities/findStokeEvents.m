function output = findStokeEvents(imds, blankFramesToIgnore)
if nargin==1
    blankFramesToIgnore = 0;
end

output = findEvents(imds, 2, blankFramesToIgnore);
end
