% ET Comp experiment
%LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 matlab

sca
clear all
%open screen
debug=true;
if debug
    commandwindow;
    PsychDebugWindowConfiguration;
end
% set up path environment

cfg = configureExperiment();

expName = input('\n \n WELCOME EXPERIMENTER! \n\n What is your name? \n >','s');
subject_id = input('\n subjectid: ');



% Initialize Sounddriver
InitializePsychSound(1);


%% Eyetracking setup
%setup eyetracker
eyetracking=false;
calibrate_eyelink = false;
calibrate_pupil = false;
requester = 0;
   if eyetracking == 1
    %EyelinkInit()
    %el = EyelinkInitDefaults(cfg.win);% win -> PTB window
    Pupil_started = input(sprintf('Has pupil capture been started an Manual Marker Calibration been selected? Check if Eyecam 1&2 are recorded! \n (1) - Confirm. \n >'));
    while Pupil_started ~= 1
        Pupil_started = input(sprintf('Has pupil capture been started an Manual Marker Calibration been selected? Check if Eyecam 1&2 are recorded! \n (1) - Confirm. \n >'));
    end
    zmq_request('init');
    requester = zmq_request('add_requester', 'tcp://localhost:50020');
    requester = int32(requester);
    reply = sendETNotifications('Connect Pupil', requester);
    sendETNotifications('R',requester)
    
    if ~isnan(reply)
        fprintf('Pupil Labs Connected');
    end
end

%setup eyelink
if eyetracking==1 && calibrate_eyelink == 1
    setup_eyetracker;
    %open log file
    Eyelink('OpenFile', sprintf('ETComp_s%u.EDF',subject_id));          %CHANGE file name ?
    sessionInfo = sprintf('%s %s','SUBJECTINDEX',num2str(subject_id));
    Eyelink('message','METAEX %s',sessionInfo);
    sendETNotifications(sprintf('R ETComp_s%u.EDF',subject_id),requester)
    
    %send first triggers
    send_trigger(0,eyetracking);
    send_trigger(200,eyetracking);
    
end

%%
% for block = 1:6
block = 1;
rand_block = select_randomization(cfg.rand, subject_id, block);
% at the beginning of each block : calibrate ADD pupil labs
if calibrate_eyelink
    fprintf('\n\nEYETRACKING CALIBRATION...')
    
    EyelinkDoTrackerSetup(el);
    fprintf('DONE\n\n')
end

if calibrate_pupil
    fprintf('\n\nEYETRACKING CALIBRATION...')
    
    sendETNotifications('notify',requester)
    fprintf('DONE\n\n')
end
[LastFlip] = Screen('Flip', cfg.win);

%% large grid

guidedGrid(cfg.large_grid_coord,cfg.screen_width,cfg.screen_height,cfg.win,rand_block.large, block,requester,eyetracking)
WaitSecs(0.1);                                                         

%% Smooth pursuit
%moving_dot(cfg.win,
%cfg.small_grid_randomization,cfg.screen_width,cfg.screen_height);
%% free viewing
% define size of image

% % display random images
for count = 1:3
    
    draw_target(cfg.screen_width/2, cfg.screen_height/2,20,'fixcross', cfg.win);
    LastFlip = flip_screen(cfg.screen_width,cfg.screen_height,cfg.win,0);
    
    displayPos =[cfg.screen_width/2-cfg.image_width/2,cfg.screen_height/2-cfg.image_height/2,cfg.screen_width/2+cfg.image_width/2,cfg.screen_height/2+cfg.image_height/2];
    Screen('DrawTexture',cfg.win,cfg.images(rand_block.freeviewing(count)), [0,0,cfg.image_width,cfg.image_height],[displayPos]);
    
    LastFlip = flip_screen(cfg.screen_width,cfg.screen_height,cfg.win, LastFlip + cfg.image_fixcross_time + rand(1)*0.2 - 0.1); % cfg.image_fixcross_time = 0.5s 
    sendETNotifications(eyetracking,requester,sprintf('FREEVIEW fixcross'))

    
    LastFlip = flip_screen(cfg.screen_width,cfg.screen_height,cfg.win, LastFlip + cfg.image_time); % cfg.image_time = 6s 
    sendETNotifications(eyetracking,requester,sprintf('FREEVIEW trial %d id %d block %d',count,rand_block.freeviewing(count),block))
    
    %   pause(2)
    % show stimulus for certain time
end
%% Microsaccades
draw_target(cfg.screen_width/2, cfg.screen_height/2,20,'fixcross', cfg.win);
LastFlip = flip_screen(cfg.screen_width,cfg.screen_height,cfg.win, LastFlip);
sendETNotifications(eyetracking,requester,sprintf('MICROSACC start block %d',block))

%pause(2) % what about screen correction time?
LastFlip = flip_screen(cfg.screen_width,cfg.screen_height,cfg.win, LastFlip);
sendETNotifications(eyetracking,requester,sprintf('MICROSACC stop block %d',block))

%% Blinks (beep)
playBeeps(cfg.blink_number,block,requester,eyetracking)

%% Pupil Dilation

for color_id = 1:25
    Screen('FillRect', cfg.win, [rand_block.pupildilation(color_id) rand_block.pupildilation(color_id) rand_block.pupildilation(color_id)]);
    draw_target(cfg.screen_width/2, cfg.screen_height/2,20,'fixcross', cfg.win);
    LastFlip = flip_screen(cfg.screen_width,cfg.screen_height,cfg.win, LastFlip + 2);
    
    sendETNotifications(eyetracking,requester,sprintf('DILATION lum %d block %d',color_id,block))
    
end
%% Small Grid Before
guidedGrid(cfg.small_grid_coord,cfg.screen_width,cfg.screen_height,cfg.win,subject_id,rand_block.smallBefore, block,requester,eyetracking);

% /net/store/nbp/projects/FaceViewEEG/stimset/stimset_uncontrolled

%% Yaw Head Motion
for count = 1:3

    
    displayPos =[cfg.screen_width/2-cfg.image_yaw_width/2,cfg.screen_height/2-cfg.image_yaw_height/2,cfg.screen_width/2+cfg.image_yaw_width/2,cfg.screen_height/2+cfg.image_yaw_height/2];
    Screen('DrawTexture',cfg.win,cfg.images_yaw(count), [0,0,cfg.image_yaw_width,cfg.image_yaw_height],[displayPos]);
    draw_target(cfg.screen_width/2, cfg.screen_height/2,20,'fixcross', cfg.win);

    LastFlip = flip_screen(cfg.screen_width,cfg.screen_height,cfg.win,0);

    LastFlip = flip_screen(cfg.screen_width,cfg.screen_height,cfg.win, LastFlip + cfg.image_time_faces); % cfg.image_fixcross_time = 0.5s 
    %sendETNotifications(eyetracking,requester,sprintf('FREEVIEW fixcross'))

    %sendETNotifications(eyetracking,requester,sprintf('FREEVIEW trial %d id %d block %d',count,rand_block.freeviewing(count),block))
    
    %   pause(2)
    % show stimulus for certain time
end
%% Roll Head Motion
rotation_angle = [0 45 -45]
for count = 1:3

    
    displayPos =[cfg.screen_width/2-cfg.image_yaw_width/2,cfg.screen_height/2-cfg.image_yaw_height/2,cfg.screen_width/2+cfg.image_yaw_width/2,cfg.screen_height/2+cfg.image_yaw_height/2];
    Screen('DrawTexture',cfg.win,cfg.images_roll(1), [0,0,cfg.image_yaw_width,cfg.image_yaw_height],[displayPos],rotation_angle(count));
    draw_target(cfg.screen_width/2, cfg.screen_height/2,20,'fixcross', cfg.win);

    LastFlip = flip_screen(cfg.screen_width,cfg.screen_height,cfg.win,0);

    LastFlip = flip_screen(cfg.screen_width,cfg.screen_height,cfg.win, LastFlip + cfg.image_time_faces); % cfg.image_fixcross_time = 0.5s 
    %sendETNotifications(eyetracking,requester,sprintf('FREEVIEW fixcross'))

    %sendETNotifications(eyetracking,requester,sprintf('FREEVIEW trial %d id %d block %d',count,rand_block.freeviewing(count),block))
    
    %   pause(2)
    % show stimulus for certain time
end
%% Small Grid After
guidedGrid(cfg.small_grid_coord,cfg.screen_width,cfg.screen_height,cfg.win,subject_id,rand.smallAfter, block,requester,eyetracking);

%end


%%
if eyetracking  % send experiment end trigger
    send_trigger(255,eyetracking)
end


ShowCursor;
KbQueueRelease(cfg.keyboardIndex);
Screen('Close') %cleans up all textures
DrawFormattedText(cfg.win, 'The experiment is complete! Thank you very much for your participation!', 'center', 'center',0, 60);
Screen('Flip', cfg.win)



% save eyetracking data
if eyetracking==1 && calibrate_eyelink
    fulledffile = sprintf('%s.EDF',outputname);
    sendETNotifications('r',requester)
    zmq_request('close');
    Eyelink('CloseFile');
    Eyelink('WaitForModeReady', 500);
    Eyelink('ReceiveFile',sprintf('ETComp_s%u.EDF',subject_id),fulledffile);
    Eyelink('WaitForModeReady', 500);
end