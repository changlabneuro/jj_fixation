function save( opts, flag )

%   SAVE -- Save the config file.
%
%     Optionally pass in '-default' as a second argument to save the config
%     as the default config.
%
%     IN:
%       - `opts` (struct) -- Options struct / config file.
%       - `flag` (char) |OPTIONAL|

if ( nargin == 1 )
  flag = ''; 
else
  assert( strcmp(flag, '-default'), 'Unrecognized flag ''%s''', flag );
end
savepath = fileparts( which('jj_fixation.config.save') );
if ( ~isempty(flag) )
  file = 'default.mat';
  msg = 'Default config file saved';
else
  file = 'config.mat';
  msg = 'Config file saved';
end
filename = fullfile( savepath, file );
save( filename, 'opts' );
disp( msg );

end