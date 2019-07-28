function pxds = convertCategorical(pxds, labelFolders)

    reset(pxds);
    N = length(pxds.Files);
    parfor_progress(N)
    parfor r = 1:N
        [img, info] = pxds.readimage(r);
        [maskPath, fileName, ext] = fileparts(info.Filename);
        str = 'mask';
        
        maskPathIdx = strfind(maskPath, str);
        labelPath = strcat(maskPath(1:maskPathIdx-1),"label",maskPath(maskPathIdx+length(str):end));
        
        maskIdx = strfind(fileName, str);
        fileName = strcat(fileName(1:maskIdx-1),"label",fileName(maskIdx+length(str):end));
      
        parfor_progress;
        if ~exist(strcat(labelPath,filesep,fileName,ext), 'file')
            if ~exist(labelPath,'dir')
                mkdir(labelPath)
            end
            q = uint8(img)
            imwrite(q,fullfile(labelPath,strcat(fileName,ext))); 
        end 
    end 
    
    parfor_progress(0);
    classNames = pxds.ClassNames;
    labelIDs_Scalar = 1:numel(classNames);
    pxds = pixelLabelDatastore(labelFolders,...
        classNames,labelIDs_Scalar,'FileExtensions','.tif');
    
end