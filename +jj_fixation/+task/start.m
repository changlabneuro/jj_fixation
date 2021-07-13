function err = start( func )

%   START -- Attempt to setup and run the task.
%
%     OUT:
%       - `err` (double, MException) -- 0 if successful; otherwise, the
%         raised MException, if setup / run fails.

try
  opts = jj_fixation.task.setup();
catch err
  jj_fixation.task.cleanup();
  jj_fixation.util.print_error_stack( err );
  return;
end

try
  err = 0;
  func( opts );
  jj_fixation.task.cleanup();
catch err
  jj_fixation.task.cleanup();
  jj_fixation.util.print_error_stack( err );
end

end