function output = findLightningEvents(imds, blankFramesToIgnore)
% Wrapper function for findEvents which inserts the correct label number for 
% lightning.
% blankFramesToIgnore is an optional input that allows for ignoring blank frames
% between frames that have the presence of lightning. 
% The default blankFramesToIgnore is 0.
% 
%
% NOTE: Please see findEvents for more details on the output and function

    if nargin==1
        blankFramesToIgnore = 0;
    end

    output = findEvents(imds, 1, blankFramesToIgnore);
    
end
