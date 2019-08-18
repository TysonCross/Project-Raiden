function displayConfiguration(opt)
    fieldNames = fieldnames(opt);
    for ii=1:size(fieldNames,1)
        if eval(['opt.',fieldNames{ii}])
            cprintf('green','%s is on \n',fieldNames{ii});
        end
    end
    for ii=1:size(fieldNames,1)
        if ~eval(['opt.',fieldNames{ii}])
            cprintf([0.9,0.2,0.2],'%s is off \n',fieldNames{ii});
        end
    end
end