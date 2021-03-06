function ISPC_Plotting(Deci,params)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% by CTGill
% last edited 1/6/20
%
% ISPC_Plotting plots ISPC_time averaged across selected frequecys(see
% MikeXCohen, 2014).
%
% ISPC is first computed in sliding time segments within a trial and is
% then computed for each trial. Subsequently, ISPC is averaged across
% selected frequency bins and then plotted, giving a seperate [time x trial]
% plot for each frequency bin, for each subject, condition, and lock.
%
% If Plot_Grand_Average is selected, the average across all subjects for
% each plot is computed and plotted.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Load data

data{length(Deci.SubjectList),length(Deci.Plot.Extra.ISPC_Plotting.locks),length(Deci.Plot.Extra.ISPC_Plotting.cond)} = [];

for  subject = 1:length(Deci.SubjectList)
    for locks = 1:length(Deci.Plot.Extra.ISPC_Plotting.locks)
        for conditions = 1:length(Deci.Plot.Extra.ISPC_Plotting.cond)
            
            if Deci.Plot.Extra.ISPC_Plotting.Laplace
                load([Deci.Folder.Analysis filesep 'ISPC' filesep 'Laplacian' filesep Deci.SubjectList{subject}  filesep Deci.Plot.Extra.ISPC_Plotting.locks{locks} filesep Deci.Plot.Extra.ISPC_Plotting.cond{conditions} filesep [Deci.Plot.Extra.ISPC_Plotting.chan1{1} '_' Deci.Plot.Extra.ISPC_Plotting.chan2{1}] '.mat'],'ISPC_data');
            else
                load([Deci.Folder.Analysis filesep 'ISPC' filesep Deci.SubjectList{subject}  filesep Deci.Plot.Extra.ISPC_Plotting.locks{locks} filesep Deci.Plot.Extra.ISPC_Plotting.cond{conditions} filesep [Deci.Plot.Extra.ISPC_Plotting.chan1{1} '_' Deci.Plot.Extra.ISPC_Plotting.chan2{1}] '.mat'],'ISPC_data');
            end
            
                data{subject,locks,conditions} = ISPC_data;
            
            if Deci.Plot.Extra.ISPC_Plotting.Bsl_Subtracted
                if ~strcmpi(Deci.Plot.Extra.ISPC_Plotting.BslRef,Deci.Plot.Extra.ISPC_Plotting.locks{locks})
                    if Deci.Plot.Extra.ISPC_Plotting.Laplace
                        load([Deci.Folder.Analysis filesep 'ISPC' filesep 'Laplacian' filesep Deci.SubjectList{subject}  filesep Deci.Analysis.LocksTitle{1} filesep Deci.Plot.Extra.ISPC_Plotting.cond{conditions} filesep [Deci.Plot.Extra.ISPC_Plotting.chan1{1} '_' Deci.Plot.Extra.ISPC_Plotting.chan2{1}] '.mat'],'ISPC_data');
                    else
                        load([Deci.Folder.Analysis filesep 'ISPC' filesep Deci.SubjectList{subject}  filesep Deci.Analysis.LocksTitle{1} filesep Deci.Plot.Extra.ISPC_Plotting.cond{conditions} filesep [Deci.Plot.Extra.ISPC_Plotting.chan1{1} '_' Deci.Plot.Extra.ISPC_Plotting.chan2{1}] '.mat'],'ISPC_data');
                    end
                    baselineidx = dsearchn(ISPC_data.time',Deci.Plot.Extra.ISPC_Plotting.Bsl');
                    
                    for time_pts = 1:size(data{subject,locks,conditions}.phase_sync,2)
                        data{subject,locks,conditions}.ISPC_Bsl_Subtracted(:,time_pts,:) = bsxfun(@minus,squeeze(data{subject,locks,conditions}.phase_sync(:,time_pts,:)),squeeze(mean(ISPC_data.phase_sync(:,baselineidx(1):baselineidx(2),:),2)));
                    end
                else
                    baselineidx = dsearchn(ISPC_data.time',Deci.Plot.Extra.ISPC_Plotting.Bsl');
                    
                    for time_pts = 1:size(data{subject,locks,conditions}.phase_sync,2)
                        data{subject,locks,conditions}.ISPC_Bsl_Subtracted(:,time_pts,:) = bsxfun(@minus,squeeze(data{subject,locks,conditions}.phase_sync(:,time_pts,:)),squeeze(mean(ISPC_data.phase_sync(:,baselineidx(1):baselineidx(2),:),2)));
                    end
                end
            end
        end
    end
end

for fh = 1:length(Deci.Analysis.Connectivity.freq)
    switch Deci.Analysis.Connectivity.freq{fh}
        case 'theta'
            HF{fh} = [4 8];
        case 'beta'
            HF{fh} = [12.5 30];
        case 'alpha'
            HF{fh} =[8 12.5];
        case 'lowgamma'
            HF{fh} =[30 60];
    end
end

%% plots for individual subjects
if Deci.Plot.Extra.ISPC_Plotting.save_individual_sbj_plots
    for  subject = 1:length(Deci.SubjectList)
        for locks = 1:length(Deci.Plot.Extra.ISPC_Plotting.locks)
            for conditions = 1:length(Deci.Plot.Extra.ISPC_Plotting.cond)
                
                for f = 1:length(Deci.Analysis.Connectivity.freq)
                    cfg = [];
                    cfg.frequency = [HF{f}];
                    ISPC_freq_band_avg = ft_selectdata(cfg,data{subject,locks,conditions});
                                        
                    if Deci.Plot.Extra.ISPC_Plotting.Bsl_Subtracted
                        ISPC_freq_band_avg_BslSubtracted = squeeze(mean(ISPC_freq_band_avg.ISPC_Bsl_Subtracted,1));
                        
                        if Deci.Plot.Extra.ISPC_Plotting.Laplace
                            mkdir([Deci.Folder.Plot filesep 'ISPC' filesep 'Laplacian' filesep 'Bsl_Subtracted' filesep Deci.SubjectList{subject} filesep Deci.Plot.Extra.ISPC_Plotting.locks{locks} filesep Deci.Plot.Extra.ISPC_Plotting.cond{conditions} filesep [Deci.Plot.Extra.ISPC_Plotting.chan1{1} '_' Deci.Plot.Extra.ISPC_Plotting.chan2{1}]]);
                        else
                            mkdir([Deci.Folder.Plot filesep 'ISPC' filesep 'Bsl_Subtracted' filesep Deci.SubjectList{subject} filesep Deci.Plot.Extra.ISPC_Plotting.locks{locks} filesep Deci.Plot.Extra.ISPC_Plotting.cond{conditions} filesep [Deci.Plot.Extra.ISPC_Plotting.chan1{1} '_' Deci.Plot.Extra.ISPC_Plotting.chan2{1}]]);
                        end
                        
                        fig = figure;
                        contourf([1:size(ISPC_freq_band_avg_BslSubtracted,2)],data{subject,locks,conditions}.time,ISPC_freq_band_avg_BslSubtracted,'LineStyle','none');
                        ylabel('Time [s]');
                        xlabel('Trials');
                        title({['ISPC Bsl Subtracted - ' Deci.SubjectList{subject}(size(Deci.SubjectList{subject},2)-4:end) ' - ' Deci.Analysis.Connectivity.freq{f}]; [Deci.Plot.Extra.ISPC_Plotting.locks{locks} ' - ' Deci.Plot.Extra.ISPC_Plotting.cond{conditions}(1:2) Deci.Plot.Extra.ISPC_Plotting.cond{conditions}(4:end) ' - ' [Deci.Plot.Extra.ISPC_Plotting.chan1{1} '\_' Deci.Plot.Extra.ISPC_Plotting.chan2{1}]]});
                        colorbar
                        
                        if Deci.Plot.Extra.ISPC_Plotting.Laplace
                            savefig(fig,[Deci.Folder.Plot filesep 'ISPC' filesep 'Laplacian' filesep 'Bsl_Subtracted' filesep Deci.SubjectList{subject} filesep Deci.Plot.Extra.ISPC_Plotting.locks{locks} filesep Deci.Plot.Extra.ISPC_Plotting.cond{conditions} filesep [Deci.Plot.Extra.ISPC_Plotting.chan1{1} '_' Deci.Plot.Extra.ISPC_Plotting.chan2{1}] filesep sprintf('%s_ISPC.fig',Deci.Analysis.Connectivity.freq{f})]);
                        else
                            savefig(fig,[Deci.Folder.Plot filesep 'ISPC' filesep 'Bsl_Subtracted' filesep Deci.SubjectList{subject} filesep Deci.Plot.Extra.ISPC_Plotting.locks{locks} filesep Deci.Plot.Extra.ISPC_Plotting.cond{conditions} filesep [Deci.Plot.Extra.ISPC_Plotting.chan1{1} '_' Deci.Plot.Extra.ISPC_Plotting.chan2{1}] filesep sprintf('%s_ISPC.fig',Deci.Analysis.Connectivity.freq{f})]);
                        end
                        
                        close all;
                        
                    else
                        ISPC_freq_band_avg_nonNorm = squeeze(mean(ISPC_freq_band_avg.phase_sync,1));
                        
                        if Deci.Plot.Extra.ISPC_Plotting.Laplace
                            mkdir([Deci.Folder.Plot filesep 'ISPC' filesep 'Laplacian' filesep 'Non_Normalized' filesep Deci.SubjectList{subject} filesep Deci.Plot.Extra.ISPC_Plotting.locks{locks} filesep Deci.Plot.Extra.ISPC_Plotting.cond{conditions} filesep [Deci.Plot.Extra.ISPC_Plotting.chan1{1} '_' Deci.Plot.Extra.ISPC_Plotting.chan2{1}]]);
                        else
                            mkdir([Deci.Folder.Plot filesep 'ISPC' filesep 'Non_Normalized' filesep Deci.SubjectList{subject} filesep Deci.Plot.Extra.ISPC_Plotting.locks{locks} filesep Deci.Plot.Extra.ISPC_Plotting.cond{conditions} filesep [Deci.Plot.Extra.ISPC_Plotting.chan1{1} '_' Deci.Plot.Extra.ISPC_Plotting.chan2{1}]]);
                        end
                        
                        fig = figure;
                        contourf([1:size(ISPC_freq_band_avg_nonNorm,2)],data{subject,locks,conditions}.time,ISPC_freq_band_avg_nonNorm,'LineStyle','none');
                        ylabel('Time [s]');
                        xlabel('Trials');
                        title({['ISPC - ' Deci.SubjectList{subject}(size(Deci.SubjectList{subject},2)-4:end) ' - ' Deci.Analysis.Connectivity.freq{f}]; [Deci.Plot.Extra.ISPC_Plotting.locks{locks} ' - ' Deci.Plot.Extra.ISPC_Plotting.cond{conditions}(1:2) Deci.Plot.Extra.ISPC_Plotting.cond{conditions}(4:end) ' - ' [Deci.Plot.Extra.ISPC_Plotting.chan1{1} '\_' Deci.Plot.Extra.ISPC_Plotting.chan2{1}]]});
                        colorbar
                        
                        if Deci.Plot.Extra.ISPC_Plotting.Laplace
                            savefig(fig,[Deci.Folder.Plot filesep 'ISPC' filesep 'Laplacian' filesep 'Non_Normalized' filesep Deci.SubjectList{subject} filesep Deci.Plot.Extra.ISPC_Plotting.locks{locks} filesep Deci.Plot.Extra.ISPC_Plotting.cond{conditions} filesep [Deci.Plot.Extra.ISPC_Plotting.chan1{1} '_' Deci.Plot.Extra.ISPC_Plotting.chan2{1}] filesep sprintf('%s_ISPC.fig',Deci.Analysis.Connectivity.freq{f})]);
                        else
                            savefig(fig,[Deci.Folder.Plot filesep 'ISPC' filesep 'Non_Normalized' filesep Deci.SubjectList{subject} filesep Deci.Plot.Extra.ISPC_Plotting.locks{locks} filesep Deci.Plot.Extra.ISPC_Plotting.cond{conditions} filesep [Deci.Plot.Extra.ISPC_Plotting.chan1{1} '_' Deci.Plot.Extra.ISPC_Plotting.chan2{1}] filesep sprintf('%s_ISPC.fig',Deci.Analysis.Connectivity.freq{f})]);
                        end
                        
                        close all;
                    end
                end
            end
        end
    end
end

%% Grand Average Plots
if Deci.Plot.Extra.ISPC_Plotting.GrandAverage
    
    for locks = 1:length(Deci.Plot.Extra.ISPC_Plotting.locks)
        for conditions = 1:length(Deci.Plot.Extra.ISPC_Plotting.cond)
            
            max_trialNum = 0;
            for subject = 1:length(Deci.SubjectList)
                trial_num = size((data{subject,locks,conditions}.phase_sync),3);
                
                if (trial_num > max_trialNum)
                    max_trialNum = trial_num;
                end
            end
            
            
            if Deci.Plot.Extra.ISPC_Plotting.Bsl_Subtracted
                if Deci.Plot.Extra.ISPC_Plotting.Laplace
                    mkdir([Deci.Folder.Plot filesep 'ISPC' filesep 'Laplacian' filesep 'Bsl_Subtracted' filesep 'All_Sbj_Avg' filesep Deci.Plot.Extra.ISPC_Plotting.locks{locks} filesep Deci.Plot.Extra.ISPC_Plotting.cond{conditions} filesep [Deci.Plot.Extra.ISPC_Plotting.chan1{1} '_' Deci.Plot.Extra.ISPC_Plotting.chan2{1}]]);
                else
                    mkdir([Deci.Folder.Plot filesep 'ISPC' filesep 'Bsl_Subtracted' filesep 'All_Sbj_Avg' filesep Deci.Plot.Extra.ISPC_Plotting.locks{locks} filesep Deci.Plot.Extra.ISPC_Plotting.cond{conditions} filesep [Deci.Plot.Extra.ISPC_Plotting.chan1{1} '_' Deci.Plot.Extra.ISPC_Plotting.chan2{1}]]);
                end
                
                ISPC_Sum_Bsl_Subtracted = zeros(40,101,max_trialNum);
                for subject = 1:length(Deci.SubjectList)
                    temp_sync = data{subject,locks,conditions}.ISPC_Bsl_Subtracted;
                    new_num_trials = max_trialNum;
                    [x, y, z] = meshgrid(1:size(temp_sync,2),1:size(temp_sync,1),1:size(temp_sync,3));
                    [xq, yq, zq] = meshgrid(linspace(1,size(temp_sync,2),size(temp_sync,2)),linspace(1,size(temp_sync,1),size(temp_sync,1)),linspace(1,size(temp_sync,3),new_num_trials));
                    interp_sync{subject} = interp3(x,y,z,temp_sync,xq,yq,zq);
                    ISPC_Sum_Bsl_Subtracted = ISPC_Sum_Bsl_Subtracted + interp_sync{subject};
                end
                
                ISPC_grand_avg = ISPC_Sum_Bsl_Subtracted/length(Deci.SubjectList);
                ISPC_data.phase_sync = ISPC_grand_avg;
                
                for f = 1:length(Deci.Analysis.Connectivity.freq)
                    cfg = [];
                    cfg.frequency = [HF{f}];
                    ISPC_freq_band_avg = ft_selectdata(cfg,ISPC_data);
                    ISPC_freq_band_avg_Bsl_Subtracted = squeeze(mean(ISPC_freq_band_avg.phase_sync,1));
                    
                    fig = figure;
                    contourf([1:size(ISPC_freq_band_avg_Bsl_Subtracted,2)],ISPC_freq_band_avg.time,ISPC_freq_band_avg_Bsl_Subtracted,'LineStyle','none');
                    ylabel('Time [s]');
                    xlabel('Trials');
                    title({['ISPC - Bsl Subtracted - All Subject Avg - ' Deci.Analysis.Connectivity.freq{f}]; [Deci.Plot.Extra.ISPC_Plotting.locks{locks} ' - ' Deci.Plot.Extra.ISPC_Plotting.cond{conditions}(1:2) Deci.Plot.Extra.ISPC_Plotting.cond{conditions}(4:end) ' - ' [Deci.Plot.Extra.ISPC_Plotting.chan1{1} '\_' Deci.Plot.Extra.ISPC_Plotting.chan2{1}]]});
                    colorbar
                    
                    if Deci.Plot.Extra.ISPC_Plotting.Laplace
                        savefig(fig,[Deci.Folder.Plot filesep 'ISPC' filesep 'Laplacian' filesep 'Bsl_Subtracted' filesep 'All_Sbj_Avg' filesep Deci.Plot.Extra.ISPC_Plotting.locks{locks} filesep Deci.Plot.Extra.ISPC_Plotting.cond{conditions} filesep [Deci.Plot.Extra.ISPC_Plotting.chan1{1} '_' Deci.Plot.Extra.ISPC_Plotting.chan2{1}] filesep sprintf('All_Sbj_Avg_%s_ISPC.fig',Deci.Analysis.Connectivity.freq{f})]);
                    else
                        savefig(fig,[Deci.Folder.Plot filesep 'ISPC' filesep 'Bsl_Subtracted' filesep 'All_Sbj_Avg' filesep Deci.Plot.Extra.ISPC_Plotting.locks{locks} filesep Deci.Plot.Extra.ISPC_Plotting.cond{conditions} filesep [Deci.Plot.Extra.ISPC_Plotting.chan1{1} '_' Deci.Plot.Extra.ISPC_Plotting.chan2{1}] filesep sprintf('All_Sbj_Avg_%s_ISPC.fig',Deci.Analysis.Connectivity.freq{f})]);
                    end
                    close all;
                end
                
            else
                if Deci.Plot.Extra.ISPC_Plotting.Laplace
                    mkdir([Deci.Folder.Plot filesep 'ISPC' filesep 'Laplacian' filesep 'Non_Normalized' filesep 'All_Sbj_Avg' filesep Deci.Plot.Extra.ISPC_Plotting.locks{locks} filesep Deci.Plot.Extra.ISPC_Plotting.cond{conditions} filesep [Deci.Plot.Extra.ISPC_Plotting.chan1{1} '_' Deci.Plot.Extra.ISPC_Plotting.chan2{1}]]);
                else
                    mkdir([Deci.Folder.Plot filesep 'ISPC' filesep 'Non_Normalized' filesep 'All_Sbj_Avg' filesep Deci.Plot.Extra.ISPC_Plotting.locks{locks} filesep Deci.Plot.Extra.ISPC_Plotting.cond{conditions} filesep [Deci.Plot.Extra.ISPC_Plotting.chan1{1} '_' Deci.Plot.Extra.ISPC_Plotting.chan2{1}]]);
                end
                
                ISPC_Sum = zeros(40,101,max_trialNum);
                for subject = 1:length(Deci.SubjectList)
                    temp_sync = data{subject,locks,conditions}.phase_sync;
                    new_num_trials = max_trialNum;
                    [x, y, z] = meshgrid(1:size(temp_sync,2),1:size(temp_sync,1),1:size(temp_sync,3));
                    [xq, yq, zq] = meshgrid(linspace(1,size(temp_sync,2),size(temp_sync,2)),linspace(1,size(temp_sync,1),size(temp_sync,1)),linspace(1,size(temp_sync,3),new_num_trials));
                    interp_sync{subject} = interp3(x,y,z,temp_sync,xq,yq,zq);
                    ISPC_Sum = ISPC_Sum + interp_sync{subject};
                end
                
                ISPC_grand_avg = ISPC_Sum/length(Deci.SubjectList);
                ISPC_data.phase_sync = ISPC_grand_avg;
                
                for f = 1:length(Deci.Analysis.Connectivity.freq)
                    cfg = [];
                    cfg.frequency = [HF{f}];
                    ISPC_freq_band_avg = ft_selectdata(cfg,ISPC_data);
                    ISPC_freq_band_avg_nonNorm = squeeze(mean(ISPC_freq_band_avg.phase_sync,1));
                    
                    fig = figure;
                    contourf([1:size(ISPC_freq_band_avg_nonNorm,2)],ISPC_freq_band_avg.time,ISPC_freq_band_avg_nonNorm,'LineStyle','none');
                    ylabel('Time [s]');
                    xlabel('Trials');
                    title({['ISPC - All Subject Avg - ' Deci.Analysis.Connectivity.freq{f}]; [Deci.Plot.Extra.ISPC_Plotting.locks{locks} ' - ' Deci.Plot.Extra.ISPC_Plotting.cond{conditions}(1:2) Deci.Plot.Extra.ISPC_Plotting.cond{conditions}(4:end) ' - ' [Deci.Plot.Extra.ISPC_Plotting.chan1{1} '\_' Deci.Plot.Extra.ISPC_Plotting.chan2{1}]]});
                    colorbar
                    
                    if Deci.Plot.Extra.ISPC_Plotting.Laplace
                        savefig(fig,[Deci.Folder.Plot filesep 'ISPC' filesep 'Laplacian' filesep 'Non_Normalized' filesep 'All_Sbj_Avg' filesep Deci.Plot.Extra.ISPC_Plotting.locks{locks} filesep Deci.Plot.Extra.ISPC_Plotting.cond{conditions} filesep [Deci.Plot.Extra.ISPC_Plotting.chan1{1} '_' Deci.Plot.Extra.ISPC_Plotting.chan2{1}] filesep sprintf('All_Sbj_Avg_%s_ISPC.fig',Deci.Analysis.Connectivity.freq{f})]);
                    else 
                        savefig(fig,[Deci.Folder.Plot filesep 'ISPC' filesep 'Non_Normalized' filesep 'All_Sbj_Avg' filesep Deci.Plot.Extra.ISPC_Plotting.locks{locks} filesep Deci.Plot.Extra.ISPC_Plotting.cond{conditions} filesep [Deci.Plot.Extra.ISPC_Plotting.chan1{1} '_' Deci.Plot.Extra.ISPC_Plotting.chan2{1}] filesep sprintf('All_Sbj_Avg_%s_ISPC.fig',Deci.Analysis.Connectivity.freq{f})]);
                    end
                    close all;
                end
            end
        end
    end
end
end


