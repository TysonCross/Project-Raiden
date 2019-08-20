function output = getLightningIndices(imds)
% This function is a wrapper for indexLabel where the correct label for 
% lightning is substituted, and the return value is selected as 'logical'
% The return is an array which for each frame returns a binary value based
% on the presence of lightning.
%
% NOTE: Please see indexLabel for more information of the functionality

    output = indexLabel(imds,double(Label.leader), 'logical');
    
end
