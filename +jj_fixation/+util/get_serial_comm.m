function comm = get_serial_comm(conf)

if ( nargin < 1 ), conf = jj_fixation.config.load(); end

SERIAL = conf.SERIAL;

port = SERIAL.port; 
channels = SERIAL.channels; 
messages = struct();

comm = serial_comm.SerialManager( port, messages, channels );

end
