function fix=checkFix(el,target)% fix=checkFix(el,target)% check fixation position%% INPUT:%	el 		- Eyelink%	target	- desired fixation area%% by Hans Trukenbrod  (07.12.07)WaitSecs(.2);% first fixation in target regionfix=0;timeout=1;tstart=GetSecs;while ~fix && GetSecs-tstart<timeout		fix=checkFixation(el,target);endWaitSecs(.2);if fix==1	% second fixation for x ms in target region	timeout=.2;	tstart=GetSecs;	while fix && GetSecs-tstart < timeout		fix=checkFixation(el,target);		end	end	