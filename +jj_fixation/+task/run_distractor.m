function run_distractor(opts)

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
REWARDS =   opts.REWARDS;
WINDOW =    opts.WINDOW;
DEBUG_WINDOW = opts.DEBUG_WINDOW;
comm =      opts.SERIAL.comm;

cstate = 'new_trial';

first_entry = true;
last_key_press_reward_timer = nan;

DATA = struct();
PROGRESS = struct();
TRIAL_NUMBER = 0;
errors = struct( ...
    'broke_fixation', false ...
  , 'never_fixated', false ...
  , 'looked_to_distractor', false ...
);

good_streak = 0;

%   setup colors
initial_distractor_color = zeros( 1, 1, 3 );
final_distractor_color = zeros( 1, 1, 3 );
initial_distractor_color(:, :, 1:3) = STIMULI.setup.distractor.initial_color;
final_distractor_color(:, :, 1:3) = STIMULI.setup.distractor.final_color;

final_distractor_color_hsv = rgb2hsv( final_distractor_color );
initial_distractor_color_hsv = rgb2hsv( initial_distractor_color );
current_brightness = 1;

while ( true )
  
  %%  NEW TRIAL
  
  if ( strcmp(cstate, 'new_trial') )
    if ( first_entry )
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
      %   determine whether to increment color
      should_increment_distractor_brightness = good_streak > 0;
      if ( should_increment_distractor_brightness )
        current_brightness = current_brightness + 1;
      end
      last_color_trial = STIMULI.setup.distractor.final_color_trial;
      current_brightness_factor = current_brightness / last_color_trial;
      current_distractor_color_hsv = ...
        (final_distractor_color_hsv - initial_distractor_color_hsv) * ...
        current_brightness_factor + initial_distractor_color_hsv;
      current_distractor_color = hsv2rgb( current_distractor_color_hsv );
      
      STIMULI.distractor.color = squeeze( current_distractor_color(:, :, 1:3) );
      
      fix_targ_size = STIMULI.fix_square.len;
      STIMULI.distractor.randomize_from_center( 200, fix_targ_size );
      %   reset progress time
      PROGRESS = structfun( @(x) NaN, PROGRESS, 'un', false );
      %   reset errors
      errors = structfun( @(x) false, errors, 'un', false );
      PROGRESS.new_trial = TIMER.get_time( 'task' );
      %   send eyelink new trial message
      TRACKER.send( sprintf('TRIAL__%d', TRIAL_NUMBER) );
      first_entry = false;
    end
    if ( TIMER.duration_met('new_trial') )
      %   MARK: goto: new_trial
      cstate = 'fixation';
      first_entry = true;
    end
  end
  
  %%  FIXATION
  
  if ( strcmp(cstate, 'fixation') )
    if ( first_entry )
      TIMER.reset_timers( cstate );
      fix_square = STIMULI.fix_square;
      distractor = STIMULI.distractor;
      fix_square.reset_targets();
      fix_square.put( 'center' );
      log_progress = true;
      did_look = false;
      did_show = false;
      first_entry = false;
    end
    fix_square.update_targets();
    distractor.update_targets();
    %   draw if not already drawn
    if ( ~did_show )
      fix_square.draw();
      distractor.draw();
      Screen( 'Flip', WINDOW.index );
      PROGRESS.fixation_on = TIMER.get_time( 'task' );
      if ( opts.INTERFACE.use_eyelink )
        draw_eyelink_rect( fix_square );
      end
      did_show = true;
    end
    if ( distractor.in_bounds() )
      %   MARK: goto: error
      cstate = 'error';
      first_entry = true;
      errors.looked_to_distractor = true;
    end
    if ( ~fix_square.in_bounds() && did_look && ~errors.looked_to_distractor )
      %   error -> looked then looked away
      %   MARK: goto: error
      cstate = 'error';
      first_entry = true;
      errors.broke_fixation = true;
    elseif ( fix_square.in_bounds() && ~did_look )
      %   first look
      did_look = true;
    end
    if ( fix_square.duration_met() )
      %   success
      %   MARK: goto reward
      cstate = 'reward';
      first_entry = true;
    end
    if ( TIMER.duration_met('fixation') && ~did_look )
      %   time allotted for state ellapsed without any looks to the target.
      %   MARK: goto: error
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
      if ( INTERFACE.use_arduino )
        comm.reward( 1, REWARDS.main );
      end
      did_show = false;
      first_entry = false;
    end
    if ( ~did_show )
%       STIMULI.reward_cue.draw();
      Screen( 'Flip', WINDOW.index );
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
      first_entry = false;
    end
    if ( TIMER.duration_met('iti') )
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
      did_show = false;
      first_entry = false;
    end
    if ( ~did_show )
%       STIMULI.error_cue.draw();
      sounds = STIMULI.sounds.error;
      sound( sounds.matrices{1}, sounds.fs{1} );
      Screen( 'Flip', WINDOW.index );
      did_show = true;
    end
    if ( TIMER.duration_met('error') )
      %   MARK: goto: new_trial
      cstate = 'new_trial';
      first_entry = true;
    end
  end   
  
  %%  EACH ITERATION
  
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

EyelinkFillRect( 0 );

bounds = stimulus.targets{1}.bounds + stimulus.targets{1}.padding;
size_x = bounds(3) - bounds(1);
center_x = bounds(1) + size_x/2;
size_y = bounds(4) - bounds(2);
center_y = bounds(2) + size_y/2;

disp( bounds );
disp( size_x );
disp( center_x );
disp( size_y );
disp( center_y );

EyelinkFillRect( round([center_x, center_y]), round(size_x/2), 3 );

end