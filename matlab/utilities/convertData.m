function convertData(projectPath, cachePath, imageSize, forceConvert, preProcess)
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
    for i = 1:numel(imageFolders)
        imds{i} = imageDatastore(imageFolders(i),...
            'FileExtensions','.tif');
        pxds{i} = pixelLabelDatastore(maskFolders(i),...
            labelNames, labelIDs,'FileExtensions','.tif');
    end
    
    if preProcess
        disp(['Preprocessing and resizing images & labels, ' ...
            'converting labels RGB -> categorical ...'])

        str = char(strcat('Processing images, resizing to ',{' '},rez));
        progressbar('Processing image sequences',str)
        outerProgressBar = true;
        for j = 1:numel(imageFolders)
            imds{j} = resizeProcessImages(imds{j}, imageSize, ...
                resizedImageFolders{j}, forceConvert, outerProgressBar);
            progressbar(j/numel(imageFolders),[])
        end

    else
        disp("Resizing images & labels, converting labels RGB -> categorical ...")

        str = char(strcat('Processing images, resizing to ',{' '},rez));
        progressbar('Processing image sequences',str)
        outerProgressBar = true;
        for j = 1:numel(imageFolders)
            imds{j} = resizeImages(imds{j}, imageSize, ...
                resizedImageFolders{j}, forceConvert, outerProgressBar);
            progressbar(j/numel(imageFolders),[])
        end
    end
    
    str = char(strcat('Converting labels to ',{' '},rez));
    progressbar('Resizing and converting label sequences',str)
    outerProgressBar = true;
    for j = 1:numel(imageFolders)
        pxds{j} = resizePixelLabels(pxds{j}, imageSize, ...
            resizedLabelFolders{j}, forceConvert, outerProgressBar);
        progressbar(j/numel(imageFolders),[])
    end
    progressbar(1)

    converted = listConvertedSequences(projectPath, imageSize)';
    if numel(converted)~=numel(sequences)
        cprintf([1,0,0],'Conversion failed for sequences: /%s', ...
            string(setdiff(sequences,converted)));
        disp('(Data was not saved to cache)');
        error('Conversion failed.');
    else
        disp("Data converted successfully")
        hashString = strcat(converted{:},rez);
        fingerprint = mlreportgen.utils.hash(hashString);
        save(fullfile(projectPath,'data','resized',rez, ...
            'fingerprint'),'fingerprint');
    end

    save(fullfile(cachePath,'metadata'), ...
    'resizedImageFolders','resizedLabelFolders', ...
    'labelIDs','labelIDs_scalar','labelNames', ...
    'sequences','rez');
    disp("Image metadata cached")
end

