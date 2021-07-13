function [conf, missing] = reconcile(conf)

if ( nargin < 1 )
  conf = jj_fixation.config.load(); 
end

display = false;
missing = jj_fixation.config.diff( conf, display );

if ( isempty(missing) )
  return;
end

%   don't save
do_save = false;
created = jj_fixation.config.create( do_save );

for i = 1:numel(missing)
  current = missing{i};
  eval( sprintf('conf%s = created%s;', current, current) );
end

end