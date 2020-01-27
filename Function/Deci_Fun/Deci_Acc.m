function out =  Deci_Acc(Deci,info,dat,params)

Acc_events = dat.events;
Total = nan([size(Acc_events,1) 1]);
Total(sum(ismember(Acc_events,params.Markers),2) == 1) = 1;
Total(sum(ismember(Acc_events,params.Markers(1)),2) == 1) = 0;

mkdir([Deci.Folder.Analysis filesep 'Extra' filesep 'Acc' filesep Deci.SubjectList{info.subject_list} ])
save([Deci.Folder.Analysis filesep 'Extra' filesep 'Acc' filesep Deci.SubjectList{info.subject_list} filesep Deci.Analysis.CondTitle{info.Cond}],'Total');
end