function doConvertData = checkConversion(projectPath, imageSize, forceConvert)
if (forceConvert==false)
%     disp('Checking sequences...')
    
    loadSequences;
    y = imageSize(1);
    x = imageSize(2);
    rez = strcat(string(x),'x',string(y));
    
    % hashCheck:
    if (exist(fullfile(projectPath,'data','resized',rez,...
            'fingerprint.mat'),'file')) ...

        hashString = strcat(sequences{:},rez);
        newHash = mlreportgen.utils.hash(hashString);
        load(fullfile(projectPath,'data','resized',rez, ...
            'fingerprint.mat'),'fingerprint');
        if (fingerprint==newHash)
            doConvertData = false;
        else
            doConvertData = true;
        end
    else
        % hashCheck is missing, but maybe the sequences are correct
        cprintf([1,0.5,0], ['Warning :Hash file not found. Comparing ', ...
            'converted and specified sequences \n'])
        converted = listConvertedSequences(projectPath, imageSize);
        if length(sequences)==length(converted)
            converted = sort(converted);
            sequences = sort(sequences);
            for i=1:numel(converted)
                if strcmpi(converted(i),sequences(i))
                    if ~opt.forceConvert
                        fprintf(['Source and conversion folders ', ...
                            'match, data will not be converted. ', ...
                            '(Enable ''forceConvert'' to override) \n']);
                        doConvertData = false;
                        break
                    else
                        str = ['Source and conversion folders ', ...
                            'match but opt.forceConvert is on. ', ...
                            'Data will be force converted'];
                        cprintf([1,0.5,0], 'Warning: %s \n', str);
                        doConvertData = true;
                    end
                else
                    str = ['Source and conversion folders are ', ...
                        'different. New data will be converted'];
                    cprintf([1,0.5,0], 'Warning: %s \n', str);
                    doConvertData = true;
                end
            end
        else
            doConvertData = true;
        end
    end
else
    doConvertData = true;
end

end