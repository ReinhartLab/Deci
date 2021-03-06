function dc_connectivity(Deci,info,datalow,datahigh,params)

Current = params.Current;
chanl = Current{1};
chanh = Current{2};
freqlow = Current{3};
freqhigh = Current{4};
conne = Current{5};

time_window = params.time_window;
toi = find(datalow.time >= round(params.toi(1),4) & datalow.time <= round(params.toi(2),4));

switch conne
    case 'plv'
        
        if isequal(datahigh.label,datalow.label)
            return
        end
        
        plv = nan([size(freqcmb,1) length(toi)]);
        
        for foicmb = 1:size(freqcmb,1)
            
            if ~isequal(datalow.freq,datahigh.freq)
               dc_error(Deci,'datalow and datahigh must have same freq ranges for ispc'); 
            end
            
            phase_low = angle(datalow.fourierspctrm(:,:,freqcmb(foicmb,1),toi));
            phase_high = angle(datahigh.fourierspctrm(:,:,freqcmb(foicmb,2),toi));
            %display('ispc only uses freqlow')
            
            %phase angle differences
            phase_angle_diffs = phase_low - phase_high;
            
            %compute phase snychronization
            plv(freqcmb(foicmb,1),:) = abs(mean(exp(1i*phase_angle_diffs),1));

        end
        
        %conn.param(:,1,:) = nanmean(ispc,2);
        conn.param = plv;
        
        clear ispc phase_angle_diffs phase_low phase_high
        
        conn.dimord = 'freq_time';
        conn.chanlow = datalow.label;
        conn.chanhigh = datahigh.label;
        conn.time = datalow.time(toi);
        conn.freqlow = datalow.freq;
        conn.freqhigh = datahigh.freq;
        
        conn.lockers = info.lockers;
        conn.trllen = info.trllen;
        
        mkdir([Deci.Folder.Analysis filesep 'Extra' filesep 'Conn' filesep Deci.SubjectList{info.subject_list} filesep Deci.Analysis.LocksTitle{info.Lock} filesep Deci.Analysis.CondTitle{info.Cond}]);
        save([Deci.Folder.Analysis filesep 'Extra' filesep 'Conn' filesep Deci.SubjectList{info.subject_list} filesep Deci.Analysis.LocksTitle{info.Lock} filesep Deci.Analysis.CondTitle{info.Cond} filesep params.SaveDir],'conn','-v7.3');
        clear conn
        
        
    case 'penplv'
        
        if isequal(datahigh.freq,datalow.freq) && isequal(datahigh.label,datalow.label)
            return
        else
            
            for foi_low = 1:size(datalow.fourierspctrm,3)
                time_window_idx = round((1000/datalow.freq(foi_low))*time_window(foi_low)/(1000*mean(diff(datalow.time))));
                
                for foi_high = 1:size(datahigh.fourierspctrm,3)
                    
                    phase_low = angle(datalow.fourierspctrm(:,1,foi_low,:));
                    phase_high    = abs(datahigh.fourierspctrm(:,1,foi_high,:));
                    phase_high(isnan(phase_high(:))) = 0;
                    phase_high   = angle(hilbert(phase_high));
                    
                    phase_angle_diffs = phase_low - phase_high;
                    
                    for ti = 1:length(toi)
                        plv(:,foi_low,foi_high,ti) = abs(mean(exp(1i*phase_angle_diffs(:,:,:,toi(ti)-time_window_idx:toi(ti)+time_window_idx)),4));
                    end
                end
            end
        end
        
        %conn.param(:,1,1,:) = permute(nanmean(nanmean(plv,2),3),[1 4 2 3]);
        conn.param = plv;
         
        clear plv phase_low phase_high phase_angle_diffs
        
        conn.dimord = 'rpt_freqlow_freqhigh_time';
        conn.chanlow = datalow.label;
        conn.chanhigh = datahigh.label;
        conn.time = datalow.time(toi);
        %conn.freqlow = mean(datalow.freq,2);
        %conn.freqhigh = mean(datahigh.freq,2);
        conn.freqlow = datalow.freq;
        conn.freqhigh = datahigh.freq;
        
        if params.rmvtrls
            conn.dimord = 'freqlow_freqhigh_time';
            conn.param = permute(nanmean(conn.param,1),[2 3 4 1]);
        end
        
        conn.lockers = info.lockers;
        conn.trllen = info.trllen;
        mkdir([Deci.Folder.Analysis filesep 'Extra' filesep 'Conn' filesep Deci.SubjectList{info.subject_list} filesep Deci.Analysis.LocksTitle{info.Lock} filesep Deci.Analysis.CondTitle{info.Cond}]);
        save([Deci.Folder.Analysis filesep 'Extra' filesep 'Conn' filesep Deci.SubjectList{info.subject_list} filesep Deci.Analysis.LocksTitle{info.Lock} filesep Deci.Analysis.CondTitle{info.Cond} filesep params.SaveDir],'conn','-v7.3');
        clear conn
        
    case 'mvl'
        
        for foi_low = 1:size(datalow.fourierspctrm,3)
            time_window_idx = round((1000/datalow.freq(foi_low))*time_window(foi_low)/(1000*mean(diff(datalow.time))));
            
            for foi_high = 1:size(datahigh.fourierspctrm,3)
                
                phaselow = angle(datalow.fourierspctrm(:,1,foi_low,:));
                amphigh    = abs(datahigh.fourierspctrm(:,1,foi_high,:));
                
                for ti = 1:length(toi)
                    
                    mvl(:,foi_low,foi_high,ti) = abs(mean(amphigh(:,:,:,toi(ti)-time_window_idx:toi(ti)+time_window_idx).*exp(1i*phaselow(:,:,:,toi(ti)-time_window_idx:toi(ti)+time_window_idx)),4));
                    
                end
            end
        end
        
        %conn.param(:,1,1,:) = permute(nanmean(nanmean(mvl,2),3),[1 4 2 3]);
        conn.param = mvl;
        clear mvl phaselow amphigh
        
        conn.dimord = 'rpt_freqlow_freqhigh_time';
        conn.chanlow = datalow.label;
        conn.chanhigh = datahigh.label;
        conn.time = datalow.time(toi);
        %conn.freqlow = mean(datalow.freq,2);
        %conn.freqhigh = mean(datahigh.freq,2);
        conn.freqlow = datalow.freq;
        conn.freqhigh = datahigh.freq;
        
        if params.rmvtrls
            conn.dimord = 'freqlow_freqhigh_time';
            conn.param = permute(nanmean(conn.param,1),[2 3 4 1]);
        end
        
        conn.lockers = info.lockers;
        conn.trllen = info.trllen;
        mkdir([Deci.Folder.Analysis filesep 'Extra' filesep 'Conn' filesep Deci.SubjectList{info.subject_list} filesep Deci.Analysis.LocksTitle{info.Lock} filesep Deci.Analysis.CondTitle{info.Cond}]);
        save([Deci.Folder.Analysis filesep 'Extra' filesep 'Conn' filesep Deci.SubjectList{info.subject_list} filesep Deci.Analysis.LocksTitle{info.Lock} filesep Deci.Analysis.CondTitle{info.Cond} filesep params.SaveDir],'conn','-v7.3');
        clear conn
        
    case 'pac'
        
        nbin = 21;
        
        for foi_low = 1:size(datalow.fourierspctrm,3)
            time_window_idx = round((1000/datalow.freq(foi_low))*time_window(foi_low)/(1000*mean(diff(datalow.time))));
            
            for foi_high = 1:size(datahigh.fourierspctrm,3)
                
                phaselow = angle(datalow.fourierspctrm(:,1,foi_low,:));
                amphigh    = abs(datahigh.fourierspctrm(:,1,foi_high,:));
                
                for ti = 1:length(toi)
                    
                    [~,bin] = histc(phaselow(:,:,:,toi(ti)-time_window_idx:toi(ti)+time_window_idx), linspace(-pi,pi,nbin));  % binned low frequency phase
                    binamp = zeros(size(amphigh(:,:,:,toi(ti)-time_window_idx:toi(ti)+time_window_idx),1),nbin);      % binned amplitude
                    
                    for k = 1:nbin-1
                        idx = bin == k ;
                        pacdata(k) = squeeze(mean(mean(amphigh(idx),4),1));
                    end
                    
                    Q =ones(nbin-1,1)/[nbin-1];
                    P = pacdata/ nansum(pacdata);
                    
                    pac(foi_low,foi_high,ti) = nansum(P.* log2(P./Q'))./log2(nbin-1);
                end
            end
        end
        %conn.param(1,1,:) = permute(nanmean(nanmean(pac,1),2),[3 2 1]);
        conn.param = pac;
        clear pac phaselow amphigh
        
        conn.dimord = 'freqlow_freqhigh_time';
        conn.chanlow = datalow.label;
        conn.chanhigh = datahigh.label;
        conn.time = datalow.time(toi);
        %conn.freqlow = mean(datalow.freq,2);
        %conn.freqhigh = mean(datahigh.freq,2);
        conn.freqlow = datalow.freq;
        conn.freqhigh = datahigh.freq;
        
        conn.lockers = info.lockers;
        conn.trllen = info.trllen;
        mkdir([Deci.Folder.Analysis filesep 'Extra' filesep 'Conn' filesep Deci.SubjectList{info.subject_list} filesep Deci.Analysis.LocksTitle{info.Lock} filesep Deci.Analysis.CondTitle{info.Cond}]);
        save([Deci.Folder.Analysis filesep 'Extra' filesep 'Conn' filesep Deci.SubjectList{info.subject_list} filesep Deci.Analysis.LocksTitle{info.Lock} filesep Deci.Analysis.CondTitle{info.Cond} filesep params.SaveDir],'conn','-v7.3');
        clear conn
        
    case 'cs_cl'
        
        for foi_low = 1:size(datalow.fourierspctrm,3)
            time_window_idx = round((1000/datalow.freq(foi_low))*time_window(foi_low)/(1000*mean(diff(datalow.time))));
            
            for foi_high = 1:size(datahigh.fourierspctrm,3)
                
                phaselow = angle(datalow.fourierspctrm(:,1,foi_low,:));
                amphigh    = abs(datahigh.fourierspctrm(:,1,foi_high,:));
                
                
                for ti = 1:length(toi)
                    
                    pha = circ_ang2rad(phaselow(:,:,:,toi(ti)-time_window_idx:toi(ti)+time_window_idx));
                    amp =  amphigh(:,:,:,toi(ti)-time_window_idx:toi(ti)+time_window_idx);
                    cs_cl(foi_low,foi_high,ti) = circ_corrcl(pha(:),amp(:));
                    
                end
            end
        end
        
        %conn.param(1,1,:) = permute(nanmean(nanmean(cs_cl,1),2),[3 1 2]);
        conn.param = cs_cl;
        clear cs_cl phaselow amphigh
        
        conn.dimord = 'freqlow_freqhigh_time';
        conn.chanlow = datalow.label;
        conn.chanhigh = datahigh.label;
        conn.time = datalow.time(toi);
        %conn.freqlow = mean(datalow.freq,2);
        %conn.freqhigh = mean(datahigh.freq,2);
        conn.freqlow = datalow.freq;
        conn.freqhigh = datahigh.freq;
        
        conn.lockers = info.lockers;
        conn.trllen = info.trllen;
        mkdir([Deci.Folder.Analysis filesep 'Extra' filesep 'Conn' filesep Deci.SubjectList{info.subject_list} filesep Deci.Analysis.LocksTitle{info.Lock} filesep Deci.Analysis.CondTitle{info.Cond}]);
        save([Deci.Folder.Analysis filesep 'Extra' filesep 'Conn' filesep Deci.SubjectList{info.subject_list} filesep Deci.Analysis.LocksTitle{info.Lock} filesep Deci.Analysis.CondTitle{info.Cond} filesep params.SaveDir],'conn','-v7.3');
        clear conn
    case 'cs_cc'
        
        if isequal(datahigh.freq,datalow.freq) && isequal(datahigh.label,datalow.label)
            return
        else
            
            
            for foi_low = 1:size(datalow.fourierspctrm,3)
                time_window_idx = round((1000/datalow.freq(foi_low))*time_window(foi_low)/(1000*mean(diff(datalow.time))));
                
                for foi_high = 1:size(datahigh.fourierspctrm,3)
                    
                    phaselow = angle(datalow.fourierspctrm(:,1,foi_low,:));
                    phasehigh = angle(datahigh.fourierspctrm(:,1,foi_high,:));
                    
                    for ti = 1:length(toi)
                        
                        phalow = circ_ang2rad(phaselow(:,:,:,toi(ti)-time_window_idx:toi(ti)+time_window_idx));
                        phahigh = circ_ang2rad(phasehigh(:,:,:,toi(ti)-time_window_idx:toi(ti)+time_window_idx));
                        
                        cs_cl(foi_low,foi_high,ti) = circ_corrcc(phalow(:),phahigh(:));
                        
                    end
                end
            end
        end
        
        %conn.param(1,1,:) = permute(nanmean(nanmean(cs_cl,1),2),[3 1 2]);
        conn.param = cs_cl;
        clear cs_cl phaselow amphigh
        
        conn.dimord = 'rpt_freqlow_freqhigh';
        conn.chanlow = datalow.label;
        conn.chanhigh = datahigh.label;
        conn.time = datalow.time(toi);
        %conn.freqlow = mean(datalow.freq,2);
        %conn.freqhigh = mean(datahigh.freq,2);
        conn.freqlow = datalow.freq;
        conn.freqhigh = datahigh.freq;
        
        conn.lockers = info.lockers;
        conn.trllen = info.trllen;
        mkdir([Deci.Folder.Analysis filesep 'Extra' filesep 'Conn' filesep Deci.SubjectList{info.subject_list} filesep Deci.Analysis.LocksTitle{info.Lock} filesep Deci.Analysis.CondTitle{info.Cond}]);
        save([Deci.Folder.Analysis filesep 'Extra' filesep 'Conn' filesep Deci.SubjectList{info.subject_list} filesep Deci.Analysis.LocksTitle{info.Lock} filesep Deci.Analysis.CondTitle{info.Cond} filesep params.SaveDir],'conn','-v7.3');
        clear conn
end




end
