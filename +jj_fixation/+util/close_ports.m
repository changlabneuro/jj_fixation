function close_ports()

ports = instrfind;
if ( isempty(ports) ), return; end;
fclose( ports );

end