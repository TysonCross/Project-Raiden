function output = findLightningEvents(imds, blankFramesToIgnore)
if nargin==1
    blankFramesToIgnore = 0;
end

output = findEvents(imds,1, blankFramesToIgnore);
end
