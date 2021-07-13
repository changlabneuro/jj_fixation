function opts = create(do_save)

%   CREATE -- Create the config file.
%
%     Set default values in this file; to edit them, load the config file
%     via opts = hww_gng.config.load(). Edit the loaded config file, then
%     save it with hww_gng.config.save( opts ).

if ( nargin < 1 ), do_save = true; end

% - STATES - %
STATES.sequence = { 'new_trial', 'fixation', 'reward', 'iti', 'error' };

% - SCREEN + WINDOW - %
SCREEN.index = 2;
SCREEN.bg_color = [ 0 0 0 ];
SCREEN.rect = [];
SCREEN.debug_index = 0;
SCREEN.debug_rect = [];
SCREEN.use_debug_window = 0;

% - IO - %
IO.repo_dir = jj_fixation.util.get_repo_dir();
IO.edf_file = 'txst.edf';
IO.data_file = 'txst.mat';
IO.edf_folder = fullfile( IO.repo_dir, 'jj_fixation', 'data' );
IO.data_folder = fullfile( IO.repo_dir, 'jj_fixation', 'data' );
IO.stim_path = fullfile( IO.repo_dir, 'jj_fixation', 'stimuli' );
IO.gui_fields.include = { 'data_file', 'edf_file' };

% - META - %
META.date = '';
META.session = '';
META.block = '';
META.monkey = '';
META.dose = '';
META.notes = '';

% - INTERFACE - %
KbName( 'UnifyKeyNames' );
INTERFACE.use_eyelink = false;
INTERFACE.is_master_arduino = true;
INTERFACE.IS_M1 = true;
INTERFACE.use_arduino = false;
INTERFACE.save_data = false;
INTERFACE.allow_overwrite = false;
INTERFACE.stop_key = KbName( 'escape' );
INTERFACE.rwd_key = KbName( 'r' );
INTERFACE.fixation_require_initial_fixation = true;
INTERFACE.gui_fields.exclude = { 'stop_key', 'rwd_key' };

% - STRUCTURE - %
STRUCTURE.streak_length = 4;

% - TIMINGS - %
time_in.task = Inf;
time_in.new_trial = 0;
time_in.initial_fixation = 2;
time_in.fixation = 2;
time_in.present_distractor = 2;
time_in.iti = 1;
time_in.error = .5;
time_in.error_initial_fixation = 0.5;
time_in.reward = .5;

fixations.fix_square = .5;

TIMINGS.time_in = time_in;
TIMINGS.fixations = fixations;

% - STIMULI - %

non_editable_properties = {{ 'placement', 'has_target', 'image_matrix' }};

STIMULI.setup.initial_fixation = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 75, 75 ] ...
  , 'color',            [ 255, 255, 255 ] ...
  , 'placement',        'center' ...
  , 'has_target',       true ...
  , 'target_duration',  fixations.fix_square ...
  , 'target_padding',   0 ...
  , 'max_eccentricity', 200 ...
  , 'max_padding',      50 ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.fix_square = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 75, 75 ] ...
  , 'color',            [ 255, 255, 255 ] ...
  , 'placement',        'center' ...
  , 'has_target',       true ...
  , 'target_duration',  fixations.fix_square ...
  , 'target_padding',   0 ...
  , 'max_eccentricity', 200 ...
  , 'max_padding',      50 ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.distractor = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 75, 75 ] ...
  , 'color',            [ 0, 0, 0 ] ...
  , 'initial_color',    [ 0, 0, 0 ] ...
  , 'final_color',      [ 255, 255, 255 ] ...
  , 'final_color_trial', 100 ...
  , 'placement',        'center' ...
  , 'has_target',       true ...
  , 'target_duration',  fixations.fix_square ...
  , 'target_padding',   0 ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.reward_cue = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 200, 200 ] ...
  , 'color',            [ 0, 255, 0 ] ...
  , 'placement',        'center' ...
  , 'has_target',       false ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.error_cue = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 400, 400 ] ...
  , 'color',            [ 0, 0, 255 ] ...
  , 'placement',        'center' ...
  , 'has_target',       false ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.error_initial_fixation_cue = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 400, 400 ] ...
  , 'color',            [ 0, 0, 255 ] ...
  , 'placement',        'center' ...
  , 'has_target',       false ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.sounds.error = get_sounds( fullfile(IO.stim_path, 'sounds', 'error'), '.wav' );
STIMULI.sounds.reward = get_sounds( fullfile(IO.stim_path, 'sounds', 'reward'), '.wav' );

% - SERIAL - %
SERIAL.port = 'COM4';
SERIAL.messages = struct();
SERIAL.channels = { 'A', 'B' };
SERIAL.gui_fields.include = { 'port', 'outputs', 'channels' };  

% - REWARDS - %
REWARDS.main = 200;
REWARDS.main_number = 1;
REWARDS.key_press = 200;

% - STORE - %
opts.STATES =     STATES;
opts.INTERFACE =  INTERFACE;
opts.SCREEN =     SCREEN;
opts.IO =         IO;
opts.META =       META;
opts.STRUCTURE =  STRUCTURE;
opts.TIMINGS =    TIMINGS;
opts.STIMULI =    STIMULI;
opts.SERIAL =     SERIAL;
opts.REWARDS =    REWARDS;

if ( do_save )
  jj_fixation.config.save( opts );
  jj_fixation.config.save( opts, '-default' );
end

end


function sounds = get_sounds(stimuli_path, ext)

sound_files = jj_fixation.util.dirstruct( stimuli_path, ext );
sound_files = { sound_files(:).name };
sounds.matrices = cell( size(sound_files) );
sounds.fs = cell( size(sound_files) );
for i = 1:numel(sound_files)
  [sounds.matrices{i}, sounds.fs{i}] = ...
    audioread( fullfile(stimuli_path, sound_files{i}) );
end
sounds.filenames = sound_files;

end