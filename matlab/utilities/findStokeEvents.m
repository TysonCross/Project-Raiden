function output = findStokeEvents(imds, blankFramesToIgnore)
% Wrapper function for findEvents which inserts the correct label number for 
% a stroke.
% blankFramesToIgnore is an optional input that allows for ignoring blank frames
% between frames that have the presence of stroke. 
% The default blankFramesToIgnore is 0.
% 
%
% NOTE: Please see findEvents for more details on the output and function

    if nargin==1
        blankFramesToIgnore = 0;
    end

    output = findEvents(imds, 2, blankFramesToIgnore);
    
end
