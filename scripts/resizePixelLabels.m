function pxds = resizePixelLabels(pxds, labelFolder)
% Resize pixel label data to [360 480].

if ~exist(labelFolder,'dir')
    mkdir(labelFolder)
end

reset(pxds)
while hasdata(pxds)
% parfor r = 1:length(pxds.Files)
    % Read the pixel data.
    % [C,info] = pxds.readimage(r);
    [C,info] = read(pxds);
    [~, filename, ext] = fileparts(info.Filename);

    if ~exist(strcat(labelFolder,filename,ext), 'file') 
        % Convert from categorical to uint8.
        L = uint8(C);

        % Resize the data. Use 'nearest' interpolation to
        % preserve label IDs.
        L = imresize(L,[360 480],'nearest');

        % Write the data to disk.
        imwrite(L,strcat(labelFolder,filename,ext))
    end
end

classes = pxds.ClassNames;
labelIDs = 1:numel(classes);
pxds = pixelLabelDatastore(labelFolder,classes,labelIDs);
end