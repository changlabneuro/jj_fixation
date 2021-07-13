%{
    dirstruct -- function to retrieve a directory structure that contains
    either a) only files of kind <kind>, where <kind> is expected to be an
    extension (like '.csv') or b) only folders -- excluding '.' and '..'
    folders -- if <kind> is 'folders'
%}

function d = dirstruct(filepath,kind)

orig = cd;

try
    cd(filepath); cd(orig);
catch
    error('''%s'' is not a valid path',filepath);
end

d = dir(filepath);
names = {d(:).name};

if ~strcmp(kind,'folders')
    matches = cellfun(@(x) strncmpi(fliplr(x),fliplr(kind),length(kind)),names);
else %  otherwise, return folders except for '.' and '..'
    matches = cellfun(@(x) x == 1,{d(:).isdir}) & ...
        cellfun(@(x) isempty(strfind(x,'.')),names);
end

d = d(matches);

end