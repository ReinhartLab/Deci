function dc_connectivity(Deci,info,Fourier,params)

%% Freqs
for fl = 1:length(params.freqlow)
    switch params.freqlow{fl}
        case 'theta'
            LF(:,fl) = [4 8];
        case 'beta'
            LF(:,fl) = [12.5 30];
        case 'alpha'
            LF(:,fl) =[8 12.5];
        case 'lowgamma'
            LF(:,fl) =[30 55];
        case 'highgamma'
            LF(:,fl) = [55 80];
    end
end

for fh = 1:length(params.freqhigh)
    switch params.freqhigh{fh}
        case 'theta'
            HF(:,fh) = [4 8];
        case 'beta'
            HF(:,fh) = [12.5 30];
        case 'alpha'
            HF(:,fh) =[8 12.5];
        case 'lowgamma'
            HF(:,fh) =[30 55];
        case 'highgamma'
            HF(:,fh) = [55 80];
    end
end

flow = find(Fourier.freq >= round(LH(1),4) & Fourier.freq <= round(LF(2),4));
fhoi = find(Fourier.freq >= round(HF(1),4) & Fourier.freq <= round(HF(2),4));

%% Channels
chanlow = find(ismember(params.chanlow,Fourier.label));
chanhigh = find(ismember(params.chanhigh,Fourier.label));

%% Time
toi = find(Fourier.time >= round(params.toi(1),4) & Fourier.time <= round(params.toi(2),4));
time_window = params.window; %linspace(1.5,3.5,length(Deci.Analysis.Freq.foi));

%% fourier spectrum for Chan/Freq

for conne = 1:length(params.type)
    
    for cl = 1:length(chanlow)
        for ch = 1:length(chanhigh)
            
            switch params.type{conne}
                case 'ispc'
                    
                    data_low = Fourier.fourierspctrm(:,chanlow(cl),flow,:);
                    data_high = Fourier.fourierspctrm(:,chanhigh(ch),flow,:);
                    display('ispc only uses freqlow')
                    
                    phase_low = angle(data_low);
                    phase_high = angle(data_high);
                    
                    %phase angle differences
                    phase_angle_diffs = phase_low - phase_high;
                    
                    for fi = 1:length(flow)
                        
                        %compute time window in indicies for this freq
                        time_window_idx = round((1000/flow(fi))*time_window(fi)/(mean(diff(Fourier.time))));
                        
                        for ti = 1:length(toi)
                            %compute phase snychronization
                            conn.param(:,fi,ti) = abs(mean(exp(1i*phase_angle_diffs(:,fi,toi(ti)-time_window_idx:toi(ti)+time_window_idx)),4));
                        end
                    end
                    
                    conn.dimord = 'rpt_freq_time';
                    conn.chanlow = Fourier.label(chanlow(cl));
                    conn.chanhigh = Fourier.label(chanhigh(ch));
                    conn.time = Fourier.time(toi);
                    conn.freqlow = Fourier.freq(flow);
                    if params.rmvtrls && params.rmvfreqs
                        conn.dimord = 'time';
                        conn.param = permute(nanmean(nanmean(conn.param,1),2),[3 2 1]);
                    elseif params.rmvtrls
                        conn.dimord = 'freq_time';
                        conn.param = permute(nanmean(conn.param,1),[2 3 1]);
                    elseif params.rmvfreqs
                        conn.dimord = 'rpt_time';
                        conn.param = permute(nanmean(conn.param,2),[1 3 2]);
                    end
                    
                case 'plv'
                    
                    data_low = Fourier.fourierspctrm(:,chanlow(cl),flow,:);
                    data_high = Fourier.fourierspctrm(:,chanhigh(ch),flow,:);
                    
                    phase_low = angle(data_low);
                    data_high    = abs(data_high);
                    data_high(isnan(data_high(:))) = 0;
                    phase_high   = angle(hilbert(data_high));
                    
                    for fli = 1:length(flow)
                        %compute time window in indicies for this freq
                        time_window_idx = round((1000/flow(fli))*time_window(fli)/(mean(diff(Fourier.time))));
                        
                        for fhi = 1:length(fhow)
                            phase_angle_diffs = phase_low(:,:,fli,:) - phase_high(:,:,fhi,:);
                            
                            for ti = 1:length(toi)
                                conn.param(:,fli,fhi,ti) = abs(mean(exp(1i*phase_angle_diffs(:,fli,toi(ti)-time_window_idx:toi(ti)+time_window_idx)),4));
                            end
                        end
                    end
                    
                    conn.dimord = 'rpt_freqlow_freqhigh_time';
                    conn.chanlow = Fourier.label(chanlow(cl));
                    conn.chanhigh = Fourier.label(chanhigh(ch));
                    conn.time = Fourier.time(toi);
                    conn.freqlow = Fourier.freq(flow);
                    if params.rmvtrls && params.rmvfreqs
                        conn.dimord = 'time';
                        conn.param = permute(nanmean(nanmean(nanmean(conn.param,1),2),3),[4 3 2 1]);
                    elseif params.rmvtrls
                        conn.dimord = 'freqlow_freqhigh_time';
                        conn.param = permute(nanmean(conn.param,1),[2 3 4 1]);
                    elseif params.rmvfreqs
                        conn.dimord = 'rpt_time';
                        conn.param = permute(nanmean(nanmean(conn.param,2),3),[1 4 3 2]);
                    end
                    
                case 'mvl'
                    
                    data_low = Fourier.fourierspctrm(:,chanlow(cl),flow,:);
                    data_high = Fourier.fourierspctrm(:,chanhigh(ch),flow,:);
                    
                    phaselow = angle(data_low);
                    amphigh    = abs(data_high);
                    
                    for fli = 1:length(flow)
                        %compute time window in indicies for this freq
                        time_window_idx = round((1000/flow(fli))*time_window(fli)/(mean(diff(Fourier.time))));
                        
                        for fhi = 1:length(fhow)
                            for ti = 1:length(toi)
                                conn.param(:,fli,fhi,ti) =   mean(amphigh(:,ch,fhi,toi(ti)-time_window_idx:toi(ti)+time_window_idx).*exp(1i*phaselow(:,cl,fli,toi(ti)-time_window_idx:toi(ti)+time_window_idx)),4);
                            end
                        end
                    end
                    
                    conn.dimord = 'rpt_freqlow_freqhigh_time';
                    conn.chanlow = Fourier.label(chanlow(cl));
                    conn.chanhigh = Fourier.label(chanhigh(ch));
                    conn.time = Fourier.time(toi);
                    conn.freqlow = Fourier.freq(flow);
                    if params.rmvtrls && params.rmvfreqs
                        conn.dimord = 'time';
                        conn.param = permute(nanmean(nanmean(nanmean(conn.param,1),2),3),[4 3 2 1]);
                    elseif params.rmvtrls
                        conn.dimord = 'freqlow_freqhigh_time';
                        conn.param = permute(nanmean(conn.param,1),[2 3 4 1]);
                    elseif params.rmvfreqs
                        conn.dimord = 'rpt_time';
                        conn.param = permute(nanmean(nanmean(conn.param,2),3),[1 4 3 2]);
                    end
                    
                case 'pac'
                    
                    nbin = 20;
                    
                    data_low = Fourier.fourierspctrm(:,chanlow(cl),flow,:);
                    data_high = Fourier.fourierspctrm(:,chanhigh(ch),flow,:);
                    
                    phaselow = angle(data_low);
                    amphigh    = abs(data_high);
                    
                    for fli = 1:length(flow)
                        %compute time window in indicies for this freq
                        time_window_idx = round((1000/flow(fli))*time_window(fli)/(mean(diff(Fourier.time))));
                        
                        for fhi = 1:length(fhow)
                            for ti = 1:length(toi)
                                
                                for trl = 1:size(phaselow,1)
                                    
                                    [~,bin] = histc(phaselow(trl,cl,fli,toi(ti)-time_window_idx:toi(ti)+time_window_idx), linspace(-pi,pi,nbin));  % binned low frequency phase
                                    binamp = zeros(size(amphigh(trl,ch,fhi,toi(ti)-time_window_idx:toi(ti)+time_window_idx),1),nbin);      % binned amplitude
                                    
                                    for k = 1:nbin
                                        idx = bin == k ;
                                        pacdata(k) = mean(amphigh(:,:,:,idx),4);
                                    end
                                    Q =ones(nbin,1)/nbin;  
                                    P = pac/ nansum(pac);  
                                    
                                    conn.param(:,fli,fhi,ti) = nansum(P.* log2(P./Q))./log2(nbin);

                                end
                            end
                        end
                    end
                    
                    conn.dimord = 'rpt_freqlow_freqhigh_time';
                    conn.chanlow = Fourier.label(chanlow(cl));
                    conn.chanhigh = Fourier.label(chanhigh(ch));
                    conn.time = Fourier.time(toi);
                    conn.freqlow = Fourier.freq(flow);
                    if params.rmvtrls && params.rmvfreqs
                        conn.dimord = 'time';
                        conn.param = permute(nanmean(nanmean(nanmean(conn.param,1),2),3),[4 3 2 1]);
                    elseif params.rmvtrls
                        conn.dimord = 'freqlow_freqhigh_time';
                        conn.param = permute(nanmean(conn.param,1),[2 3 4 1]);
                    elseif params.rmvfreqs
                        conn.dimord = 'rpt_time';
                        conn.param = permute(nanmean(nanmean(conn.param,2),3),[1 4 3 2]);
                    end
                    
                case 'cs_cl'

                    data_low = Fourier.fourierspctrm(:,chanlow(cl),flow,:);
                    data_high = Fourier.fourierspctrm(:,chanhigh(ch),flow,:);
                    
                    phaselow = angle(data_low);
                    amphigh    = abs(data_high);
                     
                    for fli = 1:length(flow)
                        %compute time window in indicies for this freq
                        time_window_idx = round((1000/flow(fli))*time_window(fli)/(mean(diff(Fourier.time))));
                        
                        for fhi = 1:length(fhow)
                            for ti = 1:length(toi)
                                for trl = 1:size(phaselow,1)
                                    
                                    pha = circ_ang2rad(phaselow(trl,cl,fli,toi(ti)-time_window_idx:toi(ti)+time_window_idx));
                                    amp =  amphigh(trl,cl,fli,toi(ti)-time_window_idx:toi(ti)+time_window_idx);
                                    conn.param(trl,fli,fhi) = circ_corrcl(squeeze(pha),squeeze(amp));
                                    
                                end
                            end
                        end
                    end

                    conn.dimord = 'rpt_freqlow_freqhigh';
                    conn.chanlow = Fourier.label(chanlow(cl));
                    conn.chanhigh = Fourier.label(chanhigh(ch));
                    conn.time = Fourier.time(toi);
                    conn.freqlow = Fourier.freq(flow);
                    
                    if params.rmvtrls && params.rmvfreqs
                        conn.dimord = '';
                        conn.param = nanmean(nanmean(nanmean(conn.param,1),2),3);
                    elseif params.rmvtrls
                        conn.dimord = 'freqlow_freqhigh';
                        conn.param = permute(nanmean(conn.param,1),[2 3 1]);
                    elseif params.rmvfreqs
                        conn.dimord = 'rpt';
                        conn.param = permute(nanmean(nanmean(conn.param,2),3),[1 3 2]);
                    end
                    
                case 'cs_cc'      
                    
                    data_low = Fourier.fourierspctrm(:,chanlow(cl),flow,:);
                    data_high = Fourier.fourierspctrm(:,chanhigh(ch),flow,:);
                    
                    phaselow = angle(data_low);
                    phasehigh = angle(data_high);
                    
                    for fli = 1:length(flow)
                        %compute time window in indicies for this freq
                        time_window_idx = round((1000/flow(fli))*time_window(fli)/(mean(diff(Fourier.time))));
                        
                        for fhi = 1:length(fhow)
                            for ti = 1:length(toi)
                                for trl = 1:size(phaselow,1)
                                    
                                    phalow = circ_ang2rad(phaselow(trl,cl,fli,toi(ti)-time_window_idx:toi(ti)+time_window_idx));
                                    phahigh = circ_ang2rad(phasehigh(trl,ch,fhi,toi(ti)-time_window_idx:toi(ti)+time_window_idx));
 
                                    conn.param(trl,fli,fhi) = circ_corrcc(squeeze(phalow),squeeze(phahigh));  
                                end
                            end
                        end
                    end
                    
                    conn.dimord = 'rpt_freqlow_freqhigh';
                    conn.chanlow = Fourier.label(chanlow(cl));
                    conn.chanhigh = Fourier.label(chanhigh(ch));
                    conn.time = Fourier.time(toi);
                    conn.freqlow = Fourier.freq(flow);
                    
                    if params.rmvtrls && params.rmvfreqs
                        conn.dimord = '';
                        conn.param = nanmean(nanmean(nanmean(conn.param,1),2),3);
                    elseif params.rmvtrls
                        conn.dimord = 'freqlow_freqhigh';
                        conn.param = permute(nanmean(conn.param,1),[2 3 1]);
                    elseif params.rmvfreqs
                        conn.dimord = 'rpt';
                        conn.param = permute(nanmean(nanmean(conn.param,2),3),[1 3 2]);
                    end
                      
            end
            
            mkdir([Deci.Folder.Analysis filesep params.type{conne} filesep Deci.SubjectList{info.subject_list} filesep Deci.Analysis.LocksTitle{info.Lock} filesep Deci.Analysis.CondTitle{info.Cond}]);
            save([Deci.Folder.Analysis filesep params.type{conne} filesep Deci.SubjectList{info.subject_list} filesep Deci.Analysis.LocksTitle{info.Lock} filesep Deci.Analysis.CondTitle{info.Cond} filesep [Fourier.label(chanlow(cl)) '_' Fourier.label(chanhigh(ch))]],'conn','-v7.3');
            
        end
    end
    
end

end