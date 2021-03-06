function ISPC(Deci,info,Fourier,params)

if ismember(Deci.Analysis.CondTitle(info.Cond),Deci.Analysis.Connectivity.cond)
    
    if Deci.Analysis.Laplace
        mkdir([Deci.Folder.Analysis filesep 'ISPC' filesep 'Laplacian' filesep Deci.SubjectList{info.subject_list} filesep Deci.Analysis.LocksTitle{info.Lock} filesep Deci.Analysis.CondTitle{info.Cond}]);
    else
        mkdir([Deci.Folder.Analysis filesep 'ISPC' filesep Deci.SubjectList{info.subject_list} filesep Deci.Analysis.LocksTitle{info.Lock} filesep Deci.Analysis.CondTitle{info.Cond}]);
    end
    
    times2save = -.5:.02:1.5;
    time_window = linspace(1.5,3.5,length(Deci.Analysis.Freq.foi));
    
    %time in indicies
    times2save_idx = dsearchn(Fourier.time', times2save');
    
    %initialize
    %trial_avg_ispc = zeros(length(Deci.Analysis.Freq.foi),length(times2save));
    %ps = zeros(length(Deci.Analysis.Freq.foi),length(times2save));
    
    chan_idx = zeros(1,2);
    chan_idx(1) = find(strcmpi(Deci.Analysis.Connectivity.chan1,Fourier.label));
    chan_idx(2) = find(strcmpi(Deci.Analysis.Connectivity.chan2,Fourier.label));
    
    
    %fourier spectrum for each channel
    data1_spctrm = squeeze(Fourier.fourierspctrm(:,chan_idx(1),:,:));
    data2_spctrm = squeeze(Fourier.fourierspctrm(:,chan_idx(2),:,:));
    
    %phase angles for each channel
    phase_1 = angle(data1_spctrm);
    phase_2 = angle(data2_spctrm);
    clear data1_spctrm data2_spctrm
    
    %phase angle differences
    phase_angle_diffs = phase_1 - phase_2;
    clear phase_1 phase_2
    
    
    phase_sync = zeros(length(Deci.Analysis.Freq.foi),size(phase_angle_diffs,1),length(times2save));
    for fi = 1:length(Deci.Analysis.Freq.foi)
        
        %compute time window in indicies for this freq
        time_window_idx = round((1000/Deci.Analysis.Freq.foi(fi))*time_window(fi)/(1000/Deci.Analysis.DownSample));
        
        for ti = 1:length(times2save)
            
            %compute phase snychronization
            phase_sync_temp = abs(mean(exp(1i*phase_angle_diffs(:,fi,times2save_idx(ti)-time_window_idx:times2save_idx(ti)+time_window_idx)),3));
            phase_sync(fi,:,ti) = phase_sync_temp;
            
            
            %average over trials
            %trial_avg_ispc(fi,ti) = mean(phase_sync_temp);
        end
    end
    clear phase_angle_diffs
    
    phase_sync = permute(phase_sync,[1 3 2]);
    
    ISPC_data.phase_sync = phase_sync;
    ISPC_data.dimord = 'freq_time_trial';
    ISPC_data.chan1 = Deci.Analysis.Connectivity.chan1;
    ISPC_data.chan2 = Deci.Analysis.Connectivity.chan2;
    ISPC_data.time = times2save;
    ISPC_data.freq = Deci.Analysis.Freq.foi;
    ISPC_data.label = Fourier.label;
    %ISPC_data.times2save = times2save;
    %ISPC_data.avg_across_trials = trial_avg_ispc;
    
    if Deci.Analysis.Laplace
        save([Deci.Folder.Analysis filesep 'ISPC' filesep 'Laplacian' filesep Deci.SubjectList{info.subject_list} filesep Deci.Analysis.LocksTitle{info.Lock} filesep Deci.Analysis.CondTitle{info.Cond} filesep [Deci.Analysis.Connectivity.chan1{1} '_' Deci.Analysis.Connectivity.chan2{1}]],'ISPC_data','-v7.3');
    else
        save([Deci.Folder.Analysis filesep 'ISPC' filesep Deci.SubjectList{info.subject_list} filesep Deci.Analysis.LocksTitle{info.Lock} filesep Deci.Analysis.CondTitle{info.Cond} filesep [Deci.Analysis.Connectivity.chan1{1} '_' Deci.Analysis.Connectivity.chan2{1}]],'ISPC_data','-v7.3');
    end
    
    clear ISPC_data
end
end