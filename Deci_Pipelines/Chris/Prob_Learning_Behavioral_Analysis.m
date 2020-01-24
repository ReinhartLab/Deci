%Prob_Learning_Behavioral_Analysis
%
% by CTGill
% last edited 1/23/20
%
% Prob_Learning_Behavioral_Analysis.m assess the percentage of optimal
% responses made by each subject per block per condition and determines whether
% each subject has achieved threshold performance in each stimulus
% condition. Threshold performance is established for each stimulus condition
% independently by averaging performance across the final 3 blocks.
% Threshold performance level is set as 60% optimal responses.
%
% Bar plots are generated and saved for each subject showing performance
% across all six blocks.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
clear;
clc;

plot_figs = false;
save_figs = false;
save_sbjPerformance_data = false;
display_group_stats = true;

pt = 'C:\Users\CTGill\Documents\Probablistic_Learning\ProcessedData\Definition';
dirlist = dir('C:\Users\CTGill\Documents\Probablistic_Learning\RawData_new\*.eeg');
Subject_List = {dirlist(~[dirlist.isdir]).name}';

save_fig_pt = 'C:\Users\CTGill\Documents\Probablistic_Learning\ProcessedData\Plot\Behv_performance\percent_corr_bar_graphs';
save_data_pt = 'C:\Users\CTGill\Documents\Probablistic_Learning\ProcessedData\Behavioral_Performance';

%% loop through all subjects
for sbj = 1 :size(Subject_List,1)
    load([pt filesep Subject_List{sbj}(1:end-4) '.mat'])%load sbj data
    
    %keep relevant markers
    cond_info = cfg.event(:,1:6);
    cond_info(:,7) = cfg.event(:,15);
    
    %determine response time 
    rt = (cfg.trl(:,4)-cfg.trl(:,5))/1000;
    
    %define block ends
    Blk_ends = [60,120,180,240,300,360];
    
    %split trial data up into blocks
    for i = 1 : 6
        if i == 1
            Blk{i} = cond_info(1:Blk_ends(i),:);
        else
            Blk{i} = cond_info(Blk_ends(i-1)+1:Blk_ends(i),:);
        end
    end
    
    %track total number of optimal responses per stim type for each sbj
    ab_opt_total = 0;
    cd_opt_total = 0;
    ef_opt_total = 0;
    
    %these are for assessing whether subjects achieved threshold
    %performance in each of the three stimulus condititions.
    %threshold performance is based on average performance over the last 3
    %blocks
    ab_thresh_count = 0;
    cd_thresh_count = 0;
    ef_thresh_count = 0;
    
    ab_thresh_corr = 0;
    cd_thresh_corr = 0;
    ef_thresh_corr = 0;
    
    
    %loop through each block
    for blk = 1:6
        ab_blk_count = 0;
        cd_blk_count = 0;
        ef_blk_count = 0;
        ab_blk_opt = 0;
        cd_blk_opt = 0;
        ef_blk_opt = 0;
        
        %loop through trials and count the number of each stim condition
        %and the number of optimal responses per stim condition
        for trl = 1:60
            if Blk{blk}(trl,1) == 14
                ab_blk_count = ab_blk_count + 1;
                if Blk{blk}(trl,7) == 300
                    ab_blk_opt = ab_blk_opt + 1;
                end
            elseif Blk{blk}(trl,1) == 15
                cd_blk_count = cd_blk_count + 1;
                if Blk{blk}(trl,7) == 300
                    cd_blk_opt = cd_blk_opt + 1;
                end
            else
                ef_blk_count = ef_blk_count + 1;
                if Blk{blk}(trl,7) == 300
                    ef_blk_opt = ef_blk_opt + 1;
                end
            end
        end
        
        %calculate percent optimal responses per stim condition per block
        Blk_perf{blk}.AB_percent_corr = ab_blk_opt/ab_blk_count;
        Blk_perf{blk}.CD_percent_corr = cd_blk_opt/cd_blk_count;
        Blk_perf{blk}.EF_percent_corr = ef_blk_opt/ef_blk_count;
        
        %calculate the total number of optimal responses across all blocks
        ab_opt_total = ab_opt_total + ab_blk_opt;
        cd_opt_total = cd_opt_total + cd_blk_opt;
        ef_opt_total = ef_opt_total + ef_blk_opt;
        
        %calculate the number of optimal responses across the last 3 blocks
        %for each stim condition in order to determine if sbj achieves
        %threshold performance
        if blk > 3
            ab_thresh_count = ab_thresh_count + ab_blk_count;
            cd_thresh_count = cd_thresh_count + cd_blk_count;
            ef_thresh_count = ef_thresh_count + ef_blk_count;
            
            ab_thresh_corr = ab_thresh_corr + ab_blk_opt;
            cd_thresh_corr = cd_thresh_corr + cd_blk_opt;
            ef_thresh_corr = ef_thresh_corr + ef_blk_opt;
        end
    end
    
    %create data struct for saving behavioral performance
    Sbj_Behv_data.Sbj = Subject_List{sbj}(1:end-4);
    Sbj_Behv_data.Blk_performance = Blk_perf;
    Sbj_Behv_data.All_Blk_avg.ab_avg_opt_resp = ab_opt_total/120;
    Sbj_Behv_data.All_Blk_avg.cd_avg_opt_resp = cd_opt_total/120;
    Sbj_Behv_data.All_Blk_avg.ef_avg_opt_resp = ef_opt_total/120;
    Sbj_Behv_data.thresh_performance.AB = ab_thresh_corr/ab_thresh_count;
    Sbj_Behv_data.thresh_performance.CD = cd_thresh_corr/cd_thresh_count;
    Sbj_Behv_data.thresh_performance.EF = ef_thresh_corr/ef_thresh_count;
    Sbj_Behv_data.RT = rt;
    
    %Determine whether threshold was met for each stim condition
    if ((ab_thresh_corr/ab_thresh_count) >= .6)
        Sbj_Behv_data.AB_thresh_met = 1;
    else
        Sbj_Behv_data.AB_thresh_met = 0;
    end
    
    if ((cd_thresh_corr/cd_thresh_count) >= .6)
        Sbj_Behv_data.CD_thresh_met = 1;
    else
        Sbj_Behv_data.CD_thresh_met = 0;
    end
    
    if ((ef_thresh_corr/ef_thresh_count) >= .6)
        Sbj_Behv_data.EF_thresh_met = 1;
    else
        Sbj_Behv_data.EF_thresh_met = 0;
    end
    
    
    %assign subject to behavioral performance group based on the number of
    %stim conditions in which thresh performance was met
    Sbj_Behv_data.Behav_performance_group = Sbj_Behv_data.AB_thresh_met + Sbj_Behv_data.CD_thresh_met + Sbj_Behv_data.EF_thresh_met;
    
    
    %save data
    if save_sbjPerformance_data
        save([save_data_pt filesep 'Behv_Performance_data_' Subject_List{sbj}(1:end-4)],'Sbj_Behv_data');
    end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plotting
   
    if plot_figs == 1
        X=[Sbj_Behv_data.Blk_performance{1,1}.AB_percent_corr,Sbj_Behv_data.Blk_performance{1,1}.CD_percent_corr,Sbj_Behv_data.Blk_performance{1,1}.EF_percent_corr;...
            Sbj_Behv_data.Blk_performance{1,2}.AB_percent_corr,Sbj_Behv_data.Blk_performance{1,2}.CD_percent_corr,Sbj_Behv_data.Blk_performance{1,2}.EF_percent_corr;...
            Sbj_Behv_data.Blk_performance{1,3}.AB_percent_corr,Sbj_Behv_data.Blk_performance{1,3}.CD_percent_corr,Sbj_Behv_data.Blk_performance{1,3}.EF_percent_corr;...
            Sbj_Behv_data.Blk_performance{1,4}.AB_percent_corr,Sbj_Behv_data.Blk_performance{1,4}.CD_percent_corr,Sbj_Behv_data.Blk_performance{1,4}.EF_percent_corr;...
            Sbj_Behv_data.Blk_performance{1,5}.AB_percent_corr,Sbj_Behv_data.Blk_performance{1,5}.CD_percent_corr,Sbj_Behv_data.Blk_performance{1,5}.EF_percent_corr;...
            Sbj_Behv_data.Blk_performance{1,6}.AB_percent_corr,Sbj_Behv_data.Blk_performance{1,6}.CD_percent_corr,Sbj_Behv_data.Blk_performance{1,6}.EF_percent_corr;...
            Sbj_Behv_data.thresh_performance.AB,Sbj_Behv_data.thresh_performance.CD,Sbj_Behv_data.thresh_performance.EF];
        
        fig = figure;
        bar(X)
        ylabel('Percent Correct');
        xlabel('Block numer');
        ylim([0 1])
        title([Subject_List{i}(size(Subject_List{i},2)-8:end-4) ' - Behv Performance']);
        xlim=get(gca,'xlim');
        xticks([1 2 3 4 5 6 7])
        xticklabels({'1','2','3','4','5','6','Thresh'})
        hold on;
        plot(xlim,[.6 .6], 'r--','LineWidth',2)
        a = annotation('textbox', [0.9, 0.625, 0, 0], 'string', 'Thresh');
        a.Color = 'red';
        
%         prompt = 'Press Enter to continue ';
%         x = input(prompt);
        
        if save_figs == true
            savefig(fig,[save_fig_pt filesep sprintf('%s_behv_performance.fig',Subject_List{sbj}(1:end-4))]);
        end
        close all
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% display group stats
if display_group_stats == 1
    pt = 'C:\Users\CTGill\Documents\Probablistic_Learning\ProcessedData\Behavioral_Performance';
    
    group1_count = 0; %combination of subjects who reached thresh performance on either 0 or 1 stim conditions. 
    group2_count = 0; %number of sbjs who reached thresh performance on 2 of the stim conditions
    group3_count = 0; %number of sbjs who reached thresh performance on 3 of the stim conditions
    
    AB_count = 0; %number of sbjs who reached thresh performance on AB stim condition
    CD_count = 0; %number of sbjs who reached thresh performance on CD stim condition
    EF_count = 0; %number of sbjs who reached thresh performance on EF stim condition
    
    for sbj = 1 :size(Subject_List,1)
        load([pt filesep ['Behv_Performance_data_' Subject_List{sbj}(1:end-4) '.mat']])%load sbj data
        
        if Sbj_Behv_data.Behav_performance_group == 0 || Sbj_Behv_data.Behav_performance_group == 1
            group1_count = group1_count + 1;
        end
        if Sbj_Behv_data.Behav_performance_group == 2
            group2_count = group2_count + 1;
        end
        if Sbj_Behv_data.Behav_performance_group == 3
            group3_count = group3_count + 1;
        end
        
        if Sbj_Behv_data.AB_thresh_met == 1
            AB_count = AB_count + 1;
        end
        if Sbj_Behv_data.CD_thresh_met == 1
            CD_count = CD_count + 1;
        end
        if Sbj_Behv_data.EF_thresh_met == 1
            EF_count = EF_count + 1;
        end
    end
    
    disp(['Group 1 count = ' num2str(group1_count)])
    disp(['Group 2 count = ' num2str(group2_count)])
    disp(['Group 3 count = ' num2str(group3_count)])
    
    disp([num2str(AB_count) ' subjects achieved threshold performance in AB stim condition.'])
    disp([num2str(CD_count) ' subjects achieved threshold performance in CD stim condition.'])
    disp([num2str(EF_count) ' subjects achieved threshold performance in EF stim condition.'])
end