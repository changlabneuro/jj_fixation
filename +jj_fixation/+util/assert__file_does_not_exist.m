function assert__file_does_not_exist( file )

%   ASSERT__FILE_DOES_NOT_EXIST -- Ensure a file doesn't already exist.
%
%     IN:
%       - `file` (char)

%hww_gng.util.assert__isa( file, 'char', 'the file path to check' );
%assert( exist(file, 'file') ~= 2, 'The file ''%s'' already exists.', file );

end