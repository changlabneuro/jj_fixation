function run_fixation(opts)

%   RUN -- Run the task based on the saved config file options.
%
%     IN:
%       - `opts` (struct)

IO =        opts.IO;
INTERFACE = opts.INTERFACE;
TIMER =     opts.TIMER;
TRACKER =   opts.TRACKER;
STRUCTURE = opts.STRUCTURE;
STIMULI =   opts.STIMULI;
IMAGES =    opts.IMAGES;
REWARDS =   opts.REWARDS;
WINDOW =    opts.WINDOW;
DEBUG_WINDOW = opts.DEBUG_WINDOW;
comm =      opts.SERIAL.comm;

cstate = 'new_trial';

first_entry = true;
first_trial = true;
last_key_press_reward_timer = nan;

DATA = struct();
PROGRESS = struct();
TRIAL_NUMBER = 0;
errors = struct( ...
    'broke_fixation', false ...
  , 'never_fixated', false ...
);

good_streak = 0;

n_success = 0;
n_errors = 0;

while ( true )
  
  %%  NEW TRIAL
  
  if ( strcmp(cstate, 'new_trial') )
    if ( first_entry )
      Screen( 'Flip', opts.WINDOW.index );
      maybe_flip( DEBUG_WINDOW );
      %   RECORD DATA
      if ( TRIAL_NUMBER > 0 )
        tn = TRIAL_NUMBER;
        DATA(tn).trial_number = tn;
        DATA(tn).errors = errors;
      end
      TRIAL_NUMBER = TRIAL_NUMBER + 1;
      TIMER.reset_timers( cstate );
      %   determine whether to move the fixation target
      any_errors = any( structfun(@(x) x, errors) );
      if ( any_errors )
        good_streak = 0;
      else
        good_streak = good_streak + 1;
      end
      should_relocate_fix_targ = ...
        first_trial || ...
        errors.never_fixated || ...
        good_streak == STRUCTURE.streak_length;
      
      if ( should_relocate_fix_targ )
        max_eccen = STIMULI.setup.fix_square.max_eccentricity;
        STIMULI.fix_square.randomize_from_center( max_eccen );
        good_streak = 0;
      end
      
      %   determine padding amt
      max_padding = STIMULI.setup.fix_square.max_padding;
      padding_increment = max_padding / STRUCTURE.streak_length;
      padding = max_padding - ( padding_increment * good_streak );
      STIMULI.fix_square.targets{1}.padding = padding;
      if ( isa(STIMULI.fix_square, 'Image') )
        images = IMAGES.fix_square;
        image_n = randperm( numel(images.matrices), 1 );
        STIMULI.fix_square.image = images.matrices{image_n};
      end
      
      %   display stats
      if ( ~any(structfun(@(x) x, errors)) )
        n_success = n_success + 1;
      else
        n_errors = n_errors + 1;
      end
      
      clc;
      fprintf( '\n Total trials: %d', TRIAL_NUMBER );
      fprintf( '\n Correct trials: %d', n_success );
      fprintf( '\n Error trials: %d', n_errors );
      
      %   reset progress time
      PROGRESS = structfun( @(x) NaN, PROGRESS, 'un', false );
      %   reset errors
      errors = structfun( @(x) false, errors, 'un', false );
      PROGRESS.new_trial = TIMER.get_time( 'task' );
      %   send eyelink new trial message
      TRACKER.send( sprintf('TRIAL__%d', TRIAL_NUMBER) );
      first_trial = false;
      first_entry = false;
    end
    if ( TIMER.duration_met('new_trial') )
      %   MARK: goto: new_trial
      if ( INTERFACE.fixation_require_initial_fixation )
        cstate = 'initial_fixation';
      else
        cstate = 'fixation';
      end
      
      first_entry = true;
    end
  end
  
  %%  initial_fixation
  
  if ( strcmp(cstate, 'initial_fixation') )
    if ( first_entry )
      Screen( 'Flip', opts.WINDOW.index );
      maybe_flip( DEBUG_WINDOW );
      TIMER.reset_timers( cstate );
      initial_fixation = STIMULI.initial_fixation;
      initial_fixation.reset_targets();
      did_look = false;
      did_show = false;
      first_entry = false;
    end
    
    initial_fixation.update_targets();
    
    if ( ~did_show )
      initial_fixation.draw();
      Screen( 'Flip', opts.WINDOW.index );
      maybe_draw_into( initial_fixation, DEBUG_WINDOW );
      maybe_flip( DEBUG_WINDOW );
      did_show = true;
    end
    
    ib = initial_fixation.in_bounds();
    
    if ( ib && ~did_look )
      did_look = true;
    end
    
    % error if fix broken
    if ( did_look && ~ib )
      errors.broke_fixation = true;
      cstate = 'error_initial_fixation';
      first_entry = true;
    end
    
    if ( initial_fixation.duration_met() )
      cstate = 'fixation';
      first_entry = true;
    elseif ( TIMER.duration_met('initial_fixation') )
      errors.never_fixated = true;
      cstate = 'error_initial_fixation';
      first_entry = true;
    end
  end 
  
  
  %%  FIXATION
  
  if ( strcmp(cstate, 'fixation') )
    if ( first_entry )
      TIMER.reset_timers( cstate );
      fix_square = STIMULI.fix_square;
      fix_square.reset_targets();
      log_progress = true;
      did_look = false;
      did_show = false;
      first_entry = false;
    end
    fix_square.update_targets();
    %   draw if not already drawn
    if ( ~did_show )
      fix_square.draw();
      Screen( 'Flip', WINDOW.index );
      maybe_draw_into( fix_square, DEBUG_WINDOW );
      maybe_flip( DEBUG_WINDOW );
      if ( opts.INTERFACE.use_eyelink )
        draw_eyelink_rect( fix_square );
      end
      did_show = true;
    end
    if ( log_progress )
      PROGRESS.fixation_on = TIMER.get_time( 'task' );
      log_progress = false;
    end
    if ( did_look && ~fix_square.in_bounds() )
      %   error -> looked then looked away
      %   MARK: goto: error
      cstate = 'error';
      first_entry = true;
      errors.broke_fixation = true;
      continue;
    end
    if ( fix_square.in_bounds() && ~did_look )
      %   first look
      did_look = true;
    end
    if ( fix_square.duration_met() )
      %   success
      %   MARK: goto iti
      cstate = 'reward';
      first_entry = true;
    end
    if ( TIMER.duration_met('fixation') && ~did_look )
      %   time allotted for state ellapsed without any looks to the target.
      %   MARK: goto: fixation
      cstate = 'error';
      errors.never_fixated = true;
      first_entry = true;
    end
  end
  
  %%  REWARD
  
  if ( strcmp(cstate, 'reward') )
    if ( first_entry )
      TIMER.reset_timers( cstate );
      Screen( 'Flip', WINDOW.index );
      maybe_flip( DEBUG_WINDOW );
      if ( INTERFACE.use_arduino )
        for j = 1:REWARDS.main_number
          comm.reward( 1, REWARDS.main );
        end
      end
      did_show = false;
      first_entry = false;
    end
    if ( ~did_show )
%       STIMULI.reward_cue.draw();
      Screen( 'Flip', WINDOW.index );
      maybe_flip( DEBUG_WINDOW );
      did_show = true;
    end
    if ( TIMER.duration_met('reward') )
      %   MARK: goto: new_trial
      cstate = 'iti';
      first_entry = true;
    end
  end    
  
  %%  ITI
  
  if ( strcmp(cstate, 'iti') )
    if ( first_entry )
      TIMER.reset_timers( cstate );
      Screen( 'Flip', WINDOW.index );
      maybe_flip( DEBUG_WINDOW );
      first_entry = false;
    end
    if ( TIMER.duration_met('iti') )
      %   MARK: goto: new_trial
      cstate = 'new_trial';
      first_entry = true;
    end
  end
  
  %%  ERROR_INITIAL_FIXATION
  
  if ( strcmp(cstate, 'error_initial_fixation') )
    if ( first_entry )
      TIMER.reset_timers( cstate );
      Screen( 'Flip', WINDOW.index );
      maybe_flip( DEBUG_WINDOW );
      did_show = false;
      first_entry = false;
    end
    if ( ~did_show )
      STIMULI.error_initial_fixation_cue.draw();
      sounds = STIMULI.sounds.error;
      sound( sounds.matrices{1}, sounds.fs{1} );
      maybe_draw_into( STIMULI.error_initial_fixation_cue, DEBUG_WINDOW );
      Screen( 'Flip', WINDOW.index );
      maybe_flip( DEBUG_WINDOW );
      did_show = true;
    end
    if ( TIMER.duration_met('error_initial_fixation') )
      %   MARK: goto: new_trial
      cstate = 'new_trial';
      first_entry = true;
    end
  end   
  
  %%  ERROR
  
  if ( strcmp(cstate, 'error') )
    if ( first_entry )
      TIMER.reset_timers( cstate );
      Screen( 'Flip', WINDOW.index );
      maybe_flip( DEBUG_WINDOW );
      did_show = false;
      first_entry = false;
    end
    if ( ~did_show )
      STIMULI.error_cue.draw();
      sounds = STIMULI.sounds.error;
      sound( sounds.matrices{1}, sounds.fs{1} );
      Screen( 'Flip', WINDOW.index );
      maybe_draw_into( STIMULI.error_cue, DEBUG_WINDOW );
      maybe_flip( DEBUG_WINDOW );
      did_show = true;
    end
    if ( TIMER.duration_met('error') )
      %   MARK: goto: new_trial
      cstate = 'new_trial';
      first_entry = true;
    end
  end   
  
  %%  EACH ITERATION
  
  if ( ~isempty(comm) )
    comm.update();
  end
  
  %   Quit if error in EyeLink
  err = TRACKER.check_recording();
  if ( err ~= 0 ), break; end;
  
  TRACKER.update_coordinates();
  
  % - Check if key is pressed
  [key_pressed, ~, key_code] = KbCheck();
  if ( key_pressed )
    % - Quit if stop_key is pressed
    if ( key_code(INTERFACE.stop_key) ), break; end;
    %   Deliver reward if reward key is pressed
    if ( key_code(INTERFACE.rwd_key) && INTERFACE.use_arduino && ...
        (isnan(last_key_press_reward_timer) || toc(last_key_press_reward_timer) > 0.25) )
      comm.reward( 1, REWARDS.key_press );
      last_key_press_reward_timer = tic;
    end
  end
  
  %   Quit if time exceeds total time
  if ( TIMER.duration_met('task') ), break; end;  
end

if ( opts.INTERFACE.save_data )
  TRACKER.shutdown();
else
%   TRACKER.stop_recording();
end

if ( INTERFACE.save_data )
  data = struct();
  data.DATA = DATA;
  data.opts = opts;
  save( fullfile(IO.data_folder, IO.data_file), 'data' );
end

end

function draw_eyelink_rect(stimulus)

jj_fixation.util.EyelinkFillRect( 0 );

bounds = stimulus.targets{1}.bounds + stimulus.targets{1}.padding;
size_x = bounds(3) - bounds(1);
center_x = bounds(1) + size_x/2;
size_y = bounds(4) - bounds(2);
center_y = bounds(2) + size_y/2;

% disp( bounds );
% disp( size_x );
% disp( center_x );
% disp( size_y );
% disp( center_y );

jj_fixation.util.EyelinkFillRect( round([center_x, center_y]), round(size_x/2), 3 );

end

function maybe_draw_into(stimulus, window)

if ( ~isempty(window) )
    curr_window_index = stimulus.window;
    stimulus.window = window.index;
    stimulus.draw();
    stimulus.window = curr_window_index;
end

end

function maybe_flip(window)
if ( ~isempty(window) )
    Screen( 'Flip', window.index );
end
end