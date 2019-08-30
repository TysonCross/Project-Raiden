function [imdsSequence, pxdsSequence] = seperateSequences(imds, pxds)
 %#ok<*AGROW>
 % Assumption: all sequences are > 1 file;
 
    if ~numel(imds.Files)==numel(pxds.Files)
        error('Input image and label datastores must be the same size')
    end
    
    loadLabels;
    imdsList = sort(imds.Files);
    pxdsList = sort(pxds.Files);
    N = numel(imdsList);
    
    [folder, filename, ext] = fileparts(imdsList{1});
    baseFilename = split(filename, '.');
    previousSeq = fullfile(folder,baseFilename{1});
    imdsFiles = imdsList(1);
    pxdsFiles = pxdsList(1);
    jj = 1;
    
    for ii=2:N
        [folder, filename] = fileparts(imdsList{ii});
        baseFilename = split(filename, '.');
        currentSeq = fullfile(folder,baseFilename{1});
        if strcmp(currentSeq,previousSeq)
            imdsFiles = [ imdsFiles;imdsList(ii) ];
            pxdsFiles = [ pxdsFiles;pxdsList(ii) ];
        else
            imdsSequence{jj} = imageDatastore(imdsFiles);
            pxdsSequence{jj} = pixelLabelDatastore(pxdsFiles, ...
                labelNames,labelIDs_scalar);
            jj = jj + 1;
            imdsFiles = imdsList(ii);
            pxdsFiles = pxdsList(ii);
        end
        previousSeq = currentSeq;
    end
end