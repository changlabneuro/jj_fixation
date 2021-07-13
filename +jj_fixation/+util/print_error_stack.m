function print_error_stack( err )

if ( ~isa(err, 'MException') ), return; end;

stack = err.stack;
max_line_chars = 0;
for i = 1:numel(stack)
  max_line_chars = max( max_line_chars, numel(num2str(stack(i).line)) );
end

fprintf( '\n\n\nError traceback:\n' );
for i = numel(stack):-1:1
  extra_spaces = max_line_chars - numel( num2str(stack(i).line) );
  if ( extra_spaces == 0 )
    extra_spaces = '';
  else extra_spaces = repmat( ' ', 1, extra_spaces );
  end
  fprintf( '\n - %d,%s %s', stack(i).line, extra_spaces, stack(i).name );
end

fprintf( '\n\n - Message: %s\n\n\n', err.message );

end