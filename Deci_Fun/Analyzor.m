function Analyzor(Deci)

if ~isfield(Deci.Analysis,'ArtifactReject')
    Deci.Analysis.ArtifactReject = 0;
    Warning('Parameter for ArtifactReject not found, presuming not wanted')
end

if ~isfield(Deci.Analysis,'Channels')
    Deci.Analysis.Channels = 'all';
    Warning('Parameter for Channels not found, presuming all')
end


if ~isfield(Deci.Analysis,'Laplace')
    Deci.Analysis.Laplace = 0;
    Warning('Parameter for Laplace not found, presuming not wanted')
end


if  isempty(Deci.Analysis.Freq) &&  ~Deci.Analysis.ERP
    error('No analysis step was called for.')
end


for subject_list = 1:length(Deci.SubjectList)
    
    data = [];
    load([Deci.Folder.Preproc filesep Deci.SubjectList{subject_list}]);
    
    
    if Deci.Analysis.Laplace
        [elec.label, elec.elecpos] = elec_1020select(data.label);
        ecfg.elec = elec;
        data = ft_scalpcurrentdensity(ecfg, data);
    end
    
    trialevents = unique(data.trialinfo,'stable');
    
    for Cond = 1:length(trialevents)
        
        
        if Deci.Analysis.ArtifactReject
            
            if exist([Deci.Folder.Artifact filesep Deci.SubjectList{subject_list} filesep num2str(Cond) '.mat']) == 2
                artifacts = [];
                load([Deci.Folder.Artifact filesep Deci.SubjectList{subject_list} filesep num2str(Cond) '.mat'],'artifacts');
            else
                error(['artifacts not found for ' Deci.SubjectList{subject_list}]);
            end
        else
            artifacts = logical(ones([1 length(find(data.trialinfo==trialevents(Cond)))]))';
        end
        
        cfg = [];
        cfg.trials = find(data.trialinfo==trialevents(Cond));
        cfg.trials = cfg.trials(artifacts);
        
        redefine = 0;
        if exist([Deci.Folder.Version  filesep 'Redefine' filesep Deci.SubjectList{subject_list}  '.mat']) == 2
           redefine = 1; 
           retrl = [];
           load([Deci.Folder.Version  filesep 'Redefine' filesep Deci.SubjectList{subject_list}  '.mat']);
        end
        
        
        if Deci.Analysis.ERP
            
            if redefine
                cfg.offset = retrl;
                cfg.shift =  Deci.Analysis.Redefine.ERPToi;
                datatime = ft_datashift(cfg,data);
            else
                datatime = data;
            end
            
            cfg.vartrllength = 2;
            time =  ft_timelockanalysis(cfg, datatime);
            clear datatime;
            
            mkdir([Deci.Folder.Analysis filesep 'Volt_ERP' filesep Deci.SubjectList{subject_list}])
            label = rmfield(time,'avg');
            save([Deci.Folder.Analysis filesep 'Volt_ERP' filesep Deci.SubjectList{subject_list} filesep num2str(Cond)],'time','label');
            
        end
        
        if ~isempty(Deci.Analysis.Freq)
            
            if ~isfield(Deci.Analysis.Freq,'Toi')
                Deci.Analysis.Toi = [-inf inf];
                Warning('Parameter for Toi not found, presuming [-inf inf]')
            end
            
            fcfg = Deci.Analysis.Freq;
            fcfg.toi = Deci.Analysis.Freq.Toi(1):round(diff([data.time{1}(1) data.time{1}(2)]),5):Deci.Analysis.Freq.Toi(2);
            fcfg.output='fourier';
            fcfg.pad = 'maxperlen';
            fcfg.scc = 0;
            fcfg.keeptapers = 'no';
            fcfg.keeptrials = 'yes';
            fcfg.trials = cfg.trials;
            
            Analysis = 1;
            
           if redefine
               
               retrl1 = retrl(find(data.trialinfo==trialevents(Cond)));
               retrl1 = retrl1(artifacts);
               
                begtim  = min(retrl1) + Deci.Analysis.Freq.Toi(1);
                endtim  = max(retrl1) + Deci.Analysis.Freq.Toi(2);
                fcfg.toi = [begtim:diff([data.time{1}(1) data.time{1}(2)]):endtim];
                
                Fourier = rmfield(ft_freqanalysis(fcfg, data),'cfg');
  
                
                fcfg.toi = [Deci.Analysis.Redefine.Bsl(1):diff([data.time{1}(1) data.time{1}(2)]):Deci.Analysis.Redefine.Bsl(2)];
                bsl = rmfield(ft_freqanalysis(fcfg, data),'cfg');
                bsl.powspctrm = permute(mean(mean(abs(bsl.fourierspctrm).^2 ,1),4),[2 3 1]);
                bsl.dimord = 'chan_freq_time';
                bsl = rmfield(bsl,'fourierspctrm');
                bsl.freq = bsl.oldfoi;

                
                if Deci.Analysis.Freq.Redefine ~= 2
                shift_cfg.latency = Deci.Analysis.Freq.Toi(1):diff([data.time{1}(1) data.time{1}(2)]):Deci.Analysis.Freq.Toi(2);
                shift_cfg.offset = retrl1;
                shift_cfg.parameter = 'fourierspctrm';
                shift_cfg.keeptrials = 'no';
                Fourier = ft_freqshift(shift_cfg, Fourier);
                Analysis = 0;
                end
                
                mkdir([Deci.Folder.Version  filesep 'Redefine' filesep 'BSL' filesep Deci.SubjectList{subject_list}]);
                save([Deci.Folder.Version  filesep 'Redefine' filesep 'BSL' filesep Deci.SubjectList{subject_list} filesep num2str(Cond)],'bsl');
                clear bsl;
            else
                
                Fourier = rmfield(ft_freqanalysis(Ifcfg, data),'cfg');
           end
            
            
           if Analysis
               Fourier.freq = Fourier.oldfoi;
               
               if ischar(Deci.Analysis.Channels)
                   Chan = Fourier.label;
               elseif all(ismember(Deci.Analysis.Channels,Fourier.label))
                   Chan = Deci.Analysis.Channels;
               else
                   error('Wrong Channel Selection in Analyis');
               end
               
               for i = 1:length(Chan)
                   
                   dcfg = [];
                   dcfg.channel = Chan(i);
                   freqplaceholder = ft_selectdata(dcfg,Fourier);
                   
                   
                   mkdir([Deci.Folder.Analysis filesep 'Freq_TotalPower' filesep Deci.SubjectList{subject_list} filesep num2str(Cond)]);
                   mkdir([Deci.Folder.Analysis filesep 'Freq_ITPC' filesep Deci.SubjectList{subject_list} filesep num2str(Cond)]);
                   
                   label = freqplaceholder;
                   label = rmfield(label,'fourierspctrm');
                   label.label = Chan;
                   label.dimord = 'chan_freq_time';
                   
                   freq = freqplaceholder;
                   freq.dimord = 'chan_freq_time';
                   freq.powspctrm      = permute(abs(mean(freq.fourierspctrm./abs(freq.fourierspctrm),1)),[2 3 4 1]);         % divide by amplitude
                   freq  = rmfield(freq,'fourierspctrm');
                   save([Deci.Folder.Analysis filesep 'Freq_ITPC' filesep Deci.SubjectList{subject_list} filesep num2str(Cond) filesep Chan{i}],'freq','label','-v7.3');
                   
                   freq = freqplaceholder;
                   freq.powspctrm = permute(mean(abs(freq.fourierspctrm).^2 ,1),[2 3 4 1]);
                   freq.dimord = 'chan_freq_time';
                   freq  = rmfield(freq,'fourierspctrm');
                   save([Deci.Folder.Analysis filesep 'Freq_TotalPower' filesep Deci.SubjectList{subject_list} filesep num2str(Cond) filesep Chan{i}],'freq','label','-v7.3');
                   
               end
               figure
               ft_singleplotTFR([],freq);
               
           end
        end
    end
    
    clear data
    
end

end


