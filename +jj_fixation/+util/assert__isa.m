function assert__isa(var, kind, var_name)
      
%   ASSERT__ISA -- Ensure a variable is of a given kind.
%
%     IN:
%       - `var` (/any/) -- Variable to check.
%       - `kind` (char) -- Expected class of `var`.
%       - `var_name` (char) |OPTIONAL| -- Optionally provide a more
%         descriptive name for the variable in case the assertion
%         fails.

if ( nargin < 4 ), var_name = 'input'; end;
assert( isa(var, kind), 'Expected %s to be a ''%s''; was a ''%s''.' ...
  , var_name, kind, class(var) );
end