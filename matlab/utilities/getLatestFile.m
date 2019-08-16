%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                           GETLATESTFILE.M
%
% This function returns the latest file from the passed folder argument
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function latestfile = getLatestFile(folder)

%Get the directory contents
dirc = dir(folder);

%Filter out all the folders.
dirc = dirc(find(~cellfun(@isfolder,{dirc(:).name})));

% Index the biggest number which is the latest file
[~, Index] = max([dirc(:).datenum]);

if ~isempty(Index)
    latestfile = dirc(Index).name;
else
    latestfile = '-1';
end

end