function PCAnalyzor4(Deci,subject_list)

if ~isfield(Deci.Analysis,'Channels')
    
    Deci.Analysis.Channels = 'all';
    warning('Parameter for Channels not found, presuming all')
end

if ~isfield(Deci.Analysis,'Laplace')
    Deci.Analysis.Laplace = 0;
    warning('Parameter for Laplace not found, presuming not wanted')
end

if  isempty(Deci.Analysis.Freq) &&  ~Deci.Analysis.ERP
    error('No analysis step was called for.')
end

if ~isfield(Deci.Analysis.Freq,'Toi')
    Deci.Analysis.Toi = [-inf inf];
    warning('Parameter for Toi not found, presuming [-inf inf]')
end
% 
% if ~Deci.Analysis.ERP.do && ~Deci.Analysis.Freq.do
%     error('Must do either ERP or Freq')
% end


if ~isempty(Deci.Analysis.Version)
    
    Deci.Folder.Analysis = [Deci.Analysis.Version filesep 'Analysis'];
    mkdir(Deci.Folder.Analysis);
end

Deci.Analysis = Exist(Deci.Analysis,'DownSample',[]);

data = [];

if ~any([Deci.Analysis.Freq.do Deci.Analysis.ERP.do]) && Deci.Analysis.Extra.do
load([Deci.Folder.Definition filesep Deci.SubjectList{subject_list} '.mat'],'cfg');    

data =cfg;
data.condinfo{1} = data.trl(:,end-length(Deci.DT.Locks)+1:end);
data.condinfo{2} = data.event;
data.condinfo{3} = data.trialnum;
else
load([Deci.Folder.Artifact filesep Deci.SubjectList{subject_list}],'data');
end
condinfo = data.condinfo;

if ~strcmpi(Deci.Analysis.Channels,'all')
    cfg = [];
    cfg.channel = Deci.Analysis.Channels;
    
    data = ft_selectdata(cfg,data);
end


if isfield(data,'preart')
    pa = 1;
    preart = data.preart;
else
    pa = 0;
end

if Deci.Analysis.Laplace
    
    if ~exist([Deci.Folder.Raw  filesep Deci.SubjectList{subject_list} '.bvct'])
        error([Deci.SubjectList{subject_list} ' does not have bvct file']);
    end
    
    [elec.label, elec.elecpos] = CapTrakMake([Deci.Folder.Raw  filesep Deci.SubjectList{subject_list} '.bvct']);
    ecfg.elec = elec;
    data = ft_scalpcurrentdensity(ecfg, data);
end


for Cond = 1:length(Deci.Analysis.Conditions)
    
    TimerCond = clock;
    
    maxt = max(sum(ismember(condinfo{2},Deci.Analysis.Conditions{Cond}),2));
    info.alltrials = sum(ismember(condinfo{2},Deci.Analysis.Conditions{Cond}),2) == maxt;
    info.allnonnans = ~isnan(mean(condinfo{1},2)) & ~isnan(mean(condinfo{2},2));
    ccfg.trials =  info.alltrials & info.allnonnans;
    
    
    dat = ft_selectdata(ccfg,data);
    
    if ~isempty(Deci.Analysis.DownSample)
        dat = ft_resampledata(struct('resamplefs',Deci.Analysis.DownSample,'detrend','no'),dat);
    end
    
    if Deci.Analysis.ERP.do
        
        for Lock = 1:length(Deci.Analysis.Locks)
            
            mkdir([Deci.Folder.Analysis filesep 'Volt_Raw' filesep Deci.SubjectList{subject_list} filesep Deci.Analysis.LocksTitle{Lock} filesep num2str(Cond)]);
            
            cfg.offset = condinfo{1}(ccfg.trials,Deci.Analysis.Locks(Lock));
            cfg.toilim = Deci.Analysis.Freq.Toilim;
            
            dataplaceholder = ft_datashift2(cfg,dat);
            
            ecfg.latency = Deci.Analysis.ERP.Toi;
            
            for chan = 1:length(dataplaceholder.label)
                ecfg.channel = dataplaceholder.label(chan);
                erp = ft_selectdata(ecfg,dataplaceholder);
                erp.condinfo = condinfo;
                save([Deci.Folder.Analysis filesep 'Volt_Raw' filesep Deci.SubjectList{subject_list} filesep Deci.Analysis.LocksTitle{Lock} filesep Deci.Analysis.CondTitle{Cond} filesep dataplaceholder.label{chan}],'erp');
            end
            clear erp
        end
    end
    
    if Deci.Analysis.Extra.do
        
        info.subject_list = subject_list;
        info.Cond = Cond;
        
        dat.condinfo = condinfo;
        
        for funs = find(Deci.Analysis.Extra.Once)
            
            if Deci.Analysis.Extra.list(funs)
                feval(Deci.Analysis.Extra.Functions{funs},Deci,info,dat,Deci.Analysis.Extra.Params{funs}{:});
            end
        end
        
    end
            
    if Deci.Analysis.Freq.do
        
        dataplaceholder =dat;
        
        TimerLock = clock;
        for Lock = 1:length(Deci.Analysis.Locks)
            
            cfg.offset = condinfo{1}(ccfg.trials,Deci.Analysis.Locks(Lock));
            cfg.toilim = Deci.Analysis.Freq.Toilim;
            
            dat = ft_datashift2(cfg,dataplaceholder);
            
            if ~strcmp(Deci.Analysis.Freq.method,'hilbert')
                
                fcfg = Deci.Analysis.Freq;
                fcfg.output='fourier';
                fcfg.pad = 'maxperlen';
                fcfg.scc = 0;
                fcfg.keeptapers = 'no';
                fcfg.keeptrials = 'yes';
                fcfg.toi = Deci.Analysis.Freq.Toi(1):round(diff([data.time{1}(1) data.time{1}(2)]),5):Deci.Analysis.Freq.Toi(2);
                
                Fourier = rmfield(ft_freqanalysis(fcfg, dat),'cfg');
                Fourier.condinfo = condinfo;
                trllength = size(Fourier.fourierspctrm,1);
            else
                
                hcfg.bpfilter   = 'yes';
                hcfg.keeptrials = 'yes';
                
                fcfg = Deci.Analysis.Freq;
                fcfg.keeptrials = 'yes';
                fcfg.pad = 'maxperlen';
                fcfg.output='fourier';
                fcfg.keeptapers = 'no';
                fcfg.toi = Deci.Analysis.Freq.Toi(1):round(diff([data.time{1}(1) data.time{1}(2)]),5):Deci.Analysis.Freq.Toi(2);
                
                freqs = Deci.Analysis.Freq.foi;
                
                for foi = 1:length(freqs)
                    hcfg.bpfreq     = [freqs(foi)-fcfg.width freqs(foi)+fcfg.width];
                    evalc('hil = ft_preprocessing(hcfg,dat)');
                    fcfg.foi = freqs(foi);
                    evalc('Fo{foi} = ft_freqanalysis(fcfg, hil)');
                end
                
                acfg.parameter = 'fourierspctrm';
                acfg.appenddim = 'freq';
                
                Fourier = rmfield(ft_appendfreq(acfg,Fo{:}),'cfg');
                Fourier.condinfo = condinfo;
                Fourier.trialinfo = Fo{1}.trialinfo;
                trllength = size(Fourier.fourierspctrm,1);
            end
            
            if pa
                Fourier.preart   = preart;
            end
            
            Chan = Fourier.label;
            
            TimerChan = clock;

            for i = 1:length(Chan)
                
                
                
                dcfg = [];
                dcfg.channel = Chan(i);
                freq = ft_selectdata(dcfg,Fourier);
                freq.condinfo = Fourier.condinfo;
                freq.trials = ccfg.trials;
                
                warning('off', 'MATLAB:MKDIR:DirectoryExists');
                mkdir([Deci.Folder.Analysis filesep 'Freq_TotalPower' filesep Deci.SubjectList{subject_list}  filesep filesep Deci.Analysis.LocksTitle{Lock} filesep Deci.Analysis.CondTitle{Cond}]);
                mkdir([Deci.Folder.Analysis filesep 'Freq_ITPC' filesep  Deci.SubjectList{subject_list}  filesep filesep Deci.Analysis.LocksTitle{Lock} filesep Deci.Analysis.CondTitle{Cond}]);
                mkdir([Deci.Folder.Analysis filesep 'Freq_TotalPowerVar' filesep Deci.SubjectList{subject_list}  filesep filesep Deci.Analysis.LocksTitle{Lock} filesep Deci.Analysis.CondTitle{Cond}]);
                
                freqplaceholder = freq;
                
                freq = freqplaceholder;
                freq.dimord = 'chan_freq_time';
                freq.powspctrm      = permute(abs(mean(freq.fourierspctrm./abs(freq.fourierspctrm),1)),[2 3 4 1]);         % divide by amplitude
                
                freq  = rmfield(freq,'fourierspctrm');
                freq.trllength = trllength;
                save([Deci.Folder.Analysis filesep 'Freq_ITPC' filesep Deci.SubjectList{subject_list}  filesep Deci.Analysis.LocksTitle{Lock} filesep Deci.Analysis.CondTitle{Cond} filesep Chan{i}],'freq','-v7.3');
                
                
                freq = freqplaceholder;
                freq.powspctrm = permute(mean(abs(freq.fourierspctrm).^2 ,1),[2 3 4 1]);
                
                freq.dimord = 'chan_freq_time';
                freq.varspctrm = permute(mean(abs(freq.fourierspctrm).^2 ,1),[2 3 4 1])./permute(var(abs(freq.fourierspctrm).^2 ,1),[2 3 4 1]);
                freq  = rmfield(freq,'fourierspctrm');
                freq.trllength = trllength;
                save([Deci.Folder.Analysis filesep 'Freq_TotalPower' filesep Deci.SubjectList{subject_list}  filesep Deci.Analysis.LocksTitle{Lock} filesep Deci.Analysis.CondTitle{Cond} filesep Chan{i}],'freq','-v7.3');
                
                if Deci.Analysis.Extra.do
                    info.Channels = Chan;
                    info.ChanNum = i;
                    
                    for funs = find(~Deci.Analysis.Extra.Once)
                        
                        if Deci.Analysis.Extra.list(funs)
                            feval(Deci.Analysis.Extra.Functions{funs},Deci,info,freqplaceholder,Deci.Analysis.Extra.Params{funs}{:}); 
                        end
                    end
                end
            end
            
            %CFC Occurs
            
            %copied from PCAnalyzor2
            if Deci.Analysis.CFC.do
                
                
                
                
                for method = 1:length(Deci.Analysis.CFC.methods)
                    
                    Deci.Analysis.CFC.method = Deci.Analysis.CFC.methods{method};
                    cfc = ft_singlecfc(Deci.Analysis.CFC,Fourier);
                    cfc.method = Deci.Analysis.CFC.method;
                    mkdir([Deci.Folder.Analysis filesep 'CFC' filesep Deci.Analysis.CFC.method filesep Deci.SubjectList{subject_list}  filesep Deci.Analysis.LocksTitle{Lock}])
                    save([Deci.Folder.Analysis filesep 'CFC' filesep Deci.Analysis.CFC.method filesep Deci.SubjectList{subject_list}  filesep Deci.Analysis.LocksTitle{Lock} filesep Deci.Analysis.CondTitle{Cond}],'cfc','-v7.3');
                end
                
            end
            
            
            disp(['s:' num2str(subject_list) ' c:' num2str(Cond) ' Lock' num2str(Lock) ' time: ' num2str(etime(clock ,TimerChan))]);
        end
        
    end
    disp(['s:' num2str(subject_list) ' c:' num2str(Cond) ' Cond time: ' num2str(etime(clock ,TimerCond))]);
end
end


