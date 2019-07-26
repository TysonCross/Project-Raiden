function pxds = convertCategorical(pxds)
      parfor r = 1:length(pxds.Files)
          [img, info] = pxds.readimage(r);
          
          [maskpath, filename, ext] = fileparts(info.Filename); 
     % testing:
     maskpath = 
          maskIdx = strfind(filename, "mask");
          filename = strcat(filename(1:maskIdx-1),"label",filename(maskIdx+4:end));
          if ~exist(strcat(maskpath,filename,ext), 'file')
              q = uint8(img)
              imwrite(q,fullfile(maskpath,strcat(filename,ext))); 
          end 
      end 
end