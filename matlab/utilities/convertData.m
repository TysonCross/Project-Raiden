function convertData(projectPath, imageSize, forceConvert, preProcess)
    disp("Converting images...")
    
    y = imageSize(1);
    x = imageSize(2);
    rez = strcat(string(x),'x',string(y));

    % get input image sequences
    loadSequences;
    resizedImageFolders = fullfile(projectPath,'data','resized', ...
        rez, sequences,'image');
    resizedLabelFolders = fullfile(projectPath,'data','resized', ...
        rez, sequences,'label');
    
    % create default datastores
    loadLabels;
    parfor i = 1:numel(imageFolders)
        imds{i} = imageDatastore(imageFolders(i),...
            'FileExtensions','.tif');
        pxds{i} = pixelLabelDatastore(maskFolders(i),...
            labelNames, labelIDs,'FileExtensions','.tif');
    end
    
    disp("Resizing images & labels, converting labels RGB -> categorical ...")
    
    str = char(strcat('Processing images, resizing to ',{' '},rez));
    progressbar('Processing image sequences',str)
    for j = 1:numel(imageFolders)
        imds{j} = resizeImages(imds{j}, imageSize, ...
            resizedImageFolders{j}, forceConvert, true, preProcess);
        progressbar(j/numel(imageFolders),[])
    end
    
    str = char(strcat('Converting labels to ',{' '},rez));
    progressbar('Resizing and converting label sequences',str)
    for j = 1:numel(imageFolders)
        pxds{j} = resizePixelLabels(pxds{j}, imageSize, ...
            resizedLabelFolders{j},opt.forceConvert, true);
        progressbar(j/numel(imageFolders),[])
    end
    progressbar(1)
    
    converted = listConvertedSequences(projectPath, imageSize)';
    if numel(converted)~=numel(sequences)
        cprintf([1,0,0],'Conversion failed for sequences: /%s',string(setdiff(sequences,converted));
        disp('(Data was not saved to cache)');
        error('Conversion failed.');
    else
        disp("Data converted successfully")
        hashString = strcat(converted{:},rez);
        fingerprint = mlreportgen.utils.hash(hashString);
        save(fullfile(projectPath,'data','resized',rez, ...
            'fingerprint'),'fingerprint');
    end
    
%     clear imds pxds resolutionList fingerprint newHash hashString
%     clear imageFolders maskFolders opt.forceConvert convertData

    save(fullfile(cachePath,'metadata'), ...
    'resizedImageFolders','resizedLabelFolders', ...
    'labelIDs','labelIDs_scalar','labelNames', ...
    'sequences','rez');
    disp("Image metadata cached")
end

