function opts = setup()

%   SETUP -- Prepare to run the task based on the saved config file.
%
%     Opens windows, starts EyeTracker, initializes Arduino, etc.
%
%     OUT:
%       - `opts` (struct) -- Config file, with additional parameters
%         appended.

opts = jj_fixation.config.load();

IO =        opts.IO;
INTERFACE = opts.INTERFACE;
TIMINGS =   opts.TIMINGS;
STIMULI =   opts.STIMULI;
SERIAL =    opts.SERIAL;

KbName( 'UnifyKeyNames' );

addpath( genpath(fullfile(IO.repo_dir, 'ptb_helpers')) );
addpath( genpath(fullfile(IO.repo_dir, 'serial_comm')) );

%jj added
IO.stimuli_path = fullfile( IO.repo_dir, 'jj_fixation', 'stimuli' );


if ( INTERFACE.save_data && ~INTERFACE.allow_overwrite )
  jj_fixation.util.assert__file_does_not_exist( fullfile(IO.data_folder, IO.data_file) );
  jj_fixation.util.assert__file_does_not_exist( fullfile(IO.edf_folder, IO.edf_file) );
end

% - SCREEN + WINDOW - %
SCREEN = ScreenManager();

index = opts.SCREEN.index;
bg_color = opts.SCREEN.bg_color;
rect = opts.SCREEN.rect;

WINDOW = SCREEN.open_window( index, bg_color, rect );

DEBUG_WINDOW = [];
if ( opts.SCREEN.use_debug_window )
  DEBUG_WINDOW = SCREEN.open_window( ...
      opts.SCREEN.debug_index, bg_color, opts.SCREEN.debug_rect );
end

% - TRACKER - %
TRACKER = EyeTracker( IO.edf_file, IO.edf_folder, WINDOW.index );
TRACKER.bypass = ~INTERFACE.use_eyelink;
TRACKER.init();

% - TIMERS - %
TIMER = Timer();
TIMER.register( TIMINGS.time_in );

% - STIMULI - %

IMAGES = struct();

stim_fs = fieldnames( STIMULI.setup );
for i = 1:numel(stim_fs)
  stim = STIMULI.setup.(stim_fs{i});
  if ( ~isstruct(stim) ), continue; end;
  if ( ~isfield(stim, 'class') ), continue; end
  switch ( stim.class )
    case 'Rectangle'
      stim_ = WINDOW.Rectangle( stim.size );
    case 'Image'
      subdir = stim.image_file;
      current_images = get_images( fullfile(IO.stimuli_path, subdir), 'jpg' );
      IMAGES.(stim_fs{i}) = current_images;
      stim_ = WINDOW.Image( stim.size, current_images.matrices{1} );
  end
  stim_.color = stim.color;
  stim_.put( stim.placement );
  if ( stim.has_target )
    duration = stim.target_duration;
    padding = stim.target_padding;
    stim_.make_target( TRACKER, duration );
    stim_.targets{1}.padding = padding;
  end
  STIMULI.(stim_fs{i}) = stim_;
end

% - SERIAL - %
if ( INTERFACE.use_arduino )
  SERIAL.comm = jj_fixation.util.get_serial_comm( opts );
  SERIAL.comm.start();
else
  SERIAL.comm = [];
end

% - STORE - %
opts.SCREEN =     SCREEN;
opts.WINDOW =     WINDOW;
opts.DEBUG_WINDOW = DEBUG_WINDOW;
opts.TRACKER =    TRACKER;
opts.TIMER =      TIMER;
opts.STIMULI =    STIMULI;
opts.IMAGES =     IMAGES;
opts.SERIAL =     SERIAL;

end

function images = get_images(stimuli_path, ext)

imgs = shared_utils.io.dirstruct( stimuli_path, ext );
imgs = { imgs(:).name };
images.matrices = cellfun( @(x) imread(fullfile(stimuli_path, x)) ...
  , imgs, 'un', false );
images.filenames = imgs;

end