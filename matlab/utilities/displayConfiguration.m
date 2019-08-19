function displayConfiguration(opt, networkType, rez, networkName, logFile)
    
    cprintf('White', 'Network: \t %s \n', networkName);
    cprintf('White', 'Topology: \t %s \n', networkType);
    cprintf('White', 'Input size: \t %s (3 channels) \n', rez);

    fieldNames = fieldnames(opt);
    for ii=1:size(fieldNames,1)
        if eval(['opt.',fieldNames{ii}])
            cprintf([0.2,0.7,0],'%s \t on \n',fieldNames{ii});
        end
    end
    for ii=1:size(fieldNames,1)
        if ~eval(['opt.',fieldNames{ii}])
            cprintf([0.5,0.5,0.5],'%s \t off \n',fieldNames{ii});
        end
    end
end