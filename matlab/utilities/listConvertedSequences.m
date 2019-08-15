function pathNames = listConvertedSequences(rootPath, imageSize)
% returns a list of folders that have been converted  
    y = imageSize(1);
    x = imageSize(2);
    rez = strcat(string(x),'x',string(y));
    pathNames = dirwalk(char(fullfile(rootPath,'data','resized',rez)));
    pathNames = erase(pathNames,char(fullfile(rootPath,'data','resized',rez,filesep)));
    pathNames = erase(pathNames,'image');
    pathNames = erase(pathNames,'label');
    pathNames = pathNames([~startsWith(pathNames,rootPath)]);
    pathNames = pathNames([~endsWith(pathNames,'/')]);
    pathNames = pathNames([strlength(pathNames)>17]);
end