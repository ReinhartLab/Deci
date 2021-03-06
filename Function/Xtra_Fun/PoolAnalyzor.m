function PoolAnalyzor(Deci)
disp('----------------------');
display(['Starting Analyzor for Subject #' num2str(subject_list) ': ' Deci.SubjectList{subject_list}]);
display(' ')

%% Load Data
data = [];
info.subject_list = subject_list;

% Load Definition Data if only using Extra.Once
if Deci.Analysis.Behavioral
    load([Deci.Folder.Definition filesep Deci.SubjectList{subject_list} '.mat'],'cfg');
    data =cfg;
    data.condinfo{1} = data.trl(:,end-length(Deci.DT.Locks)+1:end);
    data.condinfo{2} = data.event;
    data.condinfo{3} = data.trialnum;
    data.preart = data.condinfo;
    display('Using Behavioral Data, Not EEG for current analysis')
else
    load([Deci.Folder.Artifact filesep Deci.SubjectList{subject_list}],'data');
end

if isfield(data,'condinfo')  %replacer starting 12/22, lets keep for ~4 months
    data.postart.locks = data.condinfo{1};
    data.postart.events = data.condinfo{2};
    data.postart.trlnum = data.condinfo{3};
    
    data.locks = data.preart{1};
    data.events = data.preart{2};
    data.trlnum = data.preart{3};
    
    data = rmfield(data,'condinfo');
    data = rmfield(data,'preart');
end

locks = data.locks;
events = data.events;
trlnum = data.trlnum;
postart.locks = data.postart.locks;
postart.events = data.postart.events;
postart.trlnum = data.postart.trlnum;

%% Laplace Transformation
if Deci.Analysis.Laplace
    if isempty(Deci.Analysis.LaplaceFile)
        
        [elec.label, elec.elecpos] = CapTrakMake([Deci.Folder.Raw  filesep Deci.SubjectList{subject_list} '.bvct']);
    else
        elec = ft_read_sens(Deci.Analysis.LaplaceFile);
    end
    ecfg.elec = elec;
    evalc('data = ft_scalpcurrentdensity(ecfg, data)');
    
    display('Laplace Transform Applied')
end

if ~ismember(Deci.Analysis.Channels,{'all','Reinhart-All'})
    cfg = [];
    cfg.channel = Deci.Analysis.Channels;
    evalc('data = ft_selectdata(cfg,data)');
    display('Channel Selection Applied')
end
%% Downsample
if ~isempty(Deci.Analysis.DownSample)
    rcfg = struct('resamplefs',Deci.Analysis.DownSample,'detrend','no');
    evalc('data = ft_resampledata(rcfg,data)');
    display('Downsampling Applied')
end

data.locks = locks;
data.events = events;
data.trlnum = trlnum;
data.postart.locks = postart.locks;
data.postart.events = postart.events;
data.postart.trlnum = postart.trlnum;
info.postart = data.postart;

%% HemifieldFlip
%check to see if postart is pull through selectdata
if Deci.Analysis.HemifieldFlip.do
    Hemifields = data.events(:,find(mean(ismember(data.events,Deci.Analysis.HemifieldFlip.Markers),1)));
    
    FlipCfg.trials  = ismember(Hemifields,Deci.Analysis.HemifieldFlip.Markers(2));
    evalc('FlipData = ft_selectdata(FlipCfg,data)');
    evalc('FlipData = hemifieldflip(FlipData)');
    
    nonFlipCfg.trials = ismember(Hemifields,Deci.Analysis.HemifieldFlip.Markers(1));
    evalc('NotFlipData = ft_selectdata(nonFlipCfg,data)');
    
    evalc('data = ft_appenddata([],FlipData,NotFlipData)');
    
    data.locks = locks([find(FlipCfg.trials);find(nonFlipCfg.trials)],:);
    data.events = events([find(FlipCfg.trials);find(nonFlipCfg.trials)],:);
    data.trlnum = trlnum([find(FlipCfg.trials);find(nonFlipCfg.trials)]);
    data.postart.locks = postart.locks([find(ismember(postart.trlnum,find(FlipCfg.trials)));find(ismember(postart.trlnum,find(nonFlipCfg.trials)))],:);
    data.postart.events = postart.events([find(ismember(postart.trlnum,find(FlipCfg.trials)));find(ismember(postart.trlnum,find(nonFlipCfg.trials)))],:);
    data.postart.trlnum = postart.trlnum([find(ismember(postart.trlnum,find(FlipCfg.trials)));find(ismember(postart.trlnum,find(nonFlipCfg.trials)))]);
    
    locks = data.locks;
    events = data.events;
    trlnum = data.trlnum;
    postart.locks = data.postart.locks;
    postart.events = data.postart.events;
    postart.trlnum = data.postart.trlnum;
    
    display('HemifieldFlip Applied')
end

if Deci.Analysis.Unique.do
    for funs = find(Deci.Analysis.Unique.list)
        if Deci.Analysis.Unique.list(funs)
            disp(['running Unique: ' Deci.Analysis.Unique.Functions{funs}])
            feval(Deci.Analysis.Unique.Functions{funs},Deci,info,data,Deci.Analysis.Unique.Params{funs}{:});
        end
    end
end

%% Loop through Conditions
for Cond = 1:length(Deci.Analysis.Conditions)
    info.Cond = Cond;
    display(' ')
    display(['---Starting Condition #' num2str(Cond) ': ' Deci.Analysis.CondTitle{Cond} '---'])
    display(' ')
    
    %% Find Relevant Trials from that Condition info
    
    if ~all(ismember(Deci.Analysis.Conditions{Cond},events))
        
        if isfield(Deci.DT,'Type')
            
            if ~strcmpi(Deci.DT.Type,'EEG_Polymerase')
                display(['Using unique Trial Def:' Deci.DT.Type])
            end
        end
        error('1 or More Marker Codes not found in events. If using own DT, make sure Step 4 contains updated DT.Markers field')
    end
    
    Deci.Analysis = Exist(Deci.Analysis,'UniqueConditions',[]);
    Deci.Analysis.UniqueConditions = Exist(Deci.Analysis.UniqueConditions,'do',false);
    
    if ~Deci.Analysis.UniqueConditions.do
    
    maxt = length(find(cellfun(@(c) any(ismember(Deci.Analysis.Conditions{Cond},c)), Deci.DT.Markers)));
    info.alltrials = find(sum(ismember(events,Deci.Analysis.Conditions{Cond}),2) == maxt);
    
    else
    info = feval(Deci.Analysis.UniqueConditions.Function,Deci,info,events,Deci.Analysis.UniqueConditions.Param);
    end
    
    %% ignore all locks with missing nans
    if Deci.Analysis.IgnoreNanLocks
        minamountofnans = min(mean(isnan(locks(info.alltrials,:)),2));
        info.nanlocks = mean(isnan(locks(info.alltrials,:)),2) ~= minamountofnans;
        
        if any(info.nanlocks)
            display(['ignoring ' num2str(length(find(info.nanlocks))) ' trials with missing locks'])
        end
    else
        info.nanlocks = logical(size(info.alltrials));
    end
    
    %% Reject Arts
    ccfg.trials =  info.alltrials(~info.nanlocks);
    if Deci.Analysis.ApplyArtReject
        ccfg.trials = ccfg.trials(ismember(trlnum(ccfg.trials),postart.trlnum));
        display('Applying Artifact Rejection')
        display(['Final trial count is ' num2str(length(ccfg.trials))])
    else
        display('Not Applying Artifact Rejection')
    end
    
    if Deci.Analysis.Behavioral
    dataplaceholder.events = data.event(ccfg.trials,:);
    dataplaceholder.trl = data.trl(ccfg.trials,:);
    dataplaceholder.trialnum = data.trialnum(ccfg.trials,:);
        
      
    else
    dataplaceholder = ft_selectdata(ccfg,data);
    end
    
    if isfield(data,'trial')
        if length(dataplaceholder.trial) < 40
            display('!!!Trial Count for this condition is < 40, which is abnormally low!!!')
        end
    end
    
    %% do Extra Analyses
    if Deci.Analysis.Extra.do
        for funs = find(Deci.Analysis.Extra.list)
            if Deci.Analysis.Extra.list(funs)
                disp(['running Extra: ' Deci.Analysis.Extra.Functions{funs}])
                feval(Deci.Analysis.Extra.Functions{funs},Deci,info,dataplaceholder,Deci.Analysis.Extra.Params{funs}{:});
            end
        end
    end
    %% Loop Through Locks
    
    if Deci.Analysis.Freq.do || Deci.Analysis.Connectivity.do || Deci.Analysis.ERP.do || Deci.Analysis.Source.do || Deci.Analysis.Freq.Extra.do
        
        for Lock = 1:length(Deci.Analysis.Locks)
            display(' ')
            display(['---Starting Lock #' num2str(Lock) ': ' Deci.Analysis.LocksTitle{Lock} '---'])
            display(' ')
            info.Lock = Lock;
            
            cfg.offset = locks(ccfg.trials,Deci.Analysis.Locks(Lock));
            
            if all(isnan(cfg.offset)) || isempty(cfg.offset)
                continue
            end
            
            cfg.toilim = Deci.Analysis.Toilim;
            evalc('dat = ft_datashift2(cfg,dataplaceholder)');
            
            for lockstd = 1:size(dat.trialinfo,2)
                lockers(lockstd)  =  mean(dat.trialinfo(:,Lock) - dat.trialinfo(:,lockstd));
            end
            info.lockers = lockers;
            
            %% Do ERP Analysis
            if Deci.Analysis.ERP.do
                mkdir([Deci.Folder.Analysis filesep 'Volt_Raw' filesep Deci.SubjectList{subject_list} filesep Deci.Analysis.LocksTitle{Lock} filesep Deci.Analysis.CondTitle{Cond}]);
                ecfg.latency = Deci.Analysis.Toi;
                
                for chan = 1:length(dat.label)
                    ecfg.channel = dat.label(chan);
                    erp = ft_selectdata(ecfg,dat);
                    evalc('erp = ft_timelockanalysis([],erp)');
                    erp.lockers = lockers;
                    erp.trllength = size(dat.trialinfo,1);
                    
                    mkdir([Deci.Folder.Analysis filesep 'Volt_ERP' filesep Deci.SubjectList{subject_list} filesep Deci.Analysis.LocksTitle{Lock} filesep Deci.Analysis.CondTitle{Cond}]);
                    save([Deci.Folder.Analysis filesep 'Volt_ERP' filesep Deci.SubjectList{subject_list} filesep Deci.Analysis.LocksTitle{Lock} filesep Deci.Analysis.CondTitle{Cond} filesep dat.label{chan}],'erp');
                end
                clear erp
            end
            
            %% Do Freq Analyses
            
            if Deci.Analysis.Freq.do || Deci.Analysis.Connectivity.do || Deci.Analysis.Freq.Extra.do
                
                if ~strcmp(Deci.Analysis.Freq.method,'hilbert')
                    fcfg = Deci.Analysis.Freq;
                    fcfg.output='fourier';
                    fcfg.pad = 'maxperlen';
                    fcfg.scc = 0;
                    fcfg.keeptapers = 'yes';
                    fcfg.keeptrials = 'yes';
                    fcfg.toi = Deci.Analysis.Toi(1):round(diff([data.time{1}(1) data.time{1}(2)]),5):Deci.Analysis.Toi(2);
                    fcfg.gpu = Deci.GCom;
                    fcfg.cpu = Deci.DCom;
                    
                    Fourier = dc_freqanalysis(fcfg, dat);
                    trllength = size(Fourier.fourierspctrm,1);
                else
                    display('Applying Hilbert Transformation')
                    fcfg = Deci.Analysis.Freq;
                    nyquist = data.fsample/2;
                    
                    freqs = Deci.Analysis.Freq.foi;
                    
                    tempfreq = [];
                    
                    for foi = 1:length(freqs)
                        
                        hcfg = [];
                        hcfg.bpfilter2 = 'yes';  %Modified implementation to work with MikexCohen's formula
                        hcfg.bpfreq =[freqs(foi)-fcfg.width(foi) freqs(foi)+fcfg.width(foi)];
                        hcfg.bpfiltord = round(fcfg.order*(data.fsample/hcfg.bpfreq(1)));
                        hcfg.bpfilttype = 'firls';
                        hcfg.transition_width = fcfg.transition_width;
                        hcfg.hilbert = 'complex';
                        
                        evalc('hil = ft_preprocessing(hcfg,dat)');
                        
                        rcfg.latency = [Deci.Analysis.Freq.Toi];
                        Fo = ft_selectdata(rcfg,hil);
                        
                        tempfreq{foi}.fourierspctrm = permute(cell2mat(permute(Fo.trial,[3 1 2])),[3 1 4 2]);
                        tempfreq{foi}.label = Fo.label;
                        tempfreq{foi}.freq = freqs(foi);
                        tempfreq{foi}.trialinfo = Fo.trialinfo;
                        tempfreq{foi}.time = Fo.time{1}';
                        tempfreq{foi}.dimord = 'rpt_chan_freq_time';
                        
                    end
                    
                    acfg.parameter = 'fourierspctrm';
                    acfg.appenddim = 'freq';
                    
                    Fourier = rmfield(ft_appendfreq(acfg,tempfreq{:}),'cfg');
                    Fourier.dimord = 'rpt_chan_freq_time';
                    trllength = size(Fourier.fourierspctrm,1);
                end
                
                info.trllen = trllength;
                Chan = Fourier.label;
                
                %% Loop Through Channels
                for i = 1:length(Chan)
                    info.Channels = Chan;
                    info.ChanNum = i;
                    
                    dcfg = [];
                    dcfg.channel = Chan(i);
                    freq = ft_selectdata(dcfg,Fourier);
                    
                    warning('off', 'MATLAB:MKDIR:DirectoryExists');
                    mkdir([Deci.Folder.Analysis filesep 'Freq_TotalPower' filesep Deci.SubjectList{subject_list}  filesep filesep Deci.Analysis.LocksTitle{Lock} filesep Deci.Analysis.CondTitle{Cond}]);
                    mkdir([Deci.Folder.Analysis filesep 'Freq_ITPC' filesep  Deci.SubjectList{subject_list}  filesep filesep Deci.Analysis.LocksTitle{Lock} filesep Deci.Analysis.CondTitle{Cond}]);
                    
                    freqplaceholder = freq;
                    if Deci.Analysis.Freq.do
                        freq = freqplaceholder;
                        freq.dimord = 'chan_freq_time';
                        freq.powspctrm      = permute(abs(mean(freq.fourierspctrm./abs(freq.fourierspctrm),1)),[2 3 4 1]);         % divide by amplitude
                        freq  = rmfield(freq,'fourierspctrm');
                        freq.trllength = trllength;
                        freq.lockers = lockers;
                        
                        save([Deci.Folder.Analysis filesep 'Freq_ITPC' filesep Deci.SubjectList{subject_list}  filesep Deci.Analysis.LocksTitle{Lock} filesep Deci.Analysis.CondTitle{Cond} filesep Chan{i}],'freq','-v7.3');
                        
                        
                        freq = freqplaceholder;
                        freq.powspctrm = permute(mean(abs(freq.fourierspctrm).^2 ,1),[2 3 4 1]);
                        freq.dimord = 'chan_freq_time';
                        freq  = rmfield(freq,'fourierspctrm');
                        freq.trllength = trllength;
                        freq.lockers = lockers;
                        save([Deci.Folder.Analysis filesep 'Freq_TotalPower' filesep Deci.SubjectList{subject_list}  filesep Deci.Analysis.LocksTitle{Lock} filesep Deci.Analysis.CondTitle{Cond} filesep Chan{i}],'freq','-v7.3');
                    end
                    
                    if Deci.Analysis.Freq.Extra.do
                        for funs = find(Deci.Analysis.Freq.Extra.list)
                            if Deci.Analysis.Freq.Extra.list(funs)
                                %JC 6/2/20: i'm editing this to also pass "dat" to the function
                                feval(Deci.Analysis.Freq.Extra.Functions{funs},Deci,info,freqplaceholder,Deci.Analysis.Freq.Extra.Params{funs}{:});
                            end
                        end
                    end
                end
                
                % Do Connectivity Analysis
                if Deci.Analysis.Connectivity.do
                    
                    display('Starting connectivity analysis');
                    
                    for funs = find(Deci.Analysis.Connectivity.list)
                        
                        for Conn = 1:length(Deci.Analysis.Connectivity.Sets)
                            
                            Current = Deci.Analysis.Connectivity.Sets{Conn};
                            chanl = Current{1};
                            chanh = Current{2};
                            
                            if isequal(chanl,{'Reinhart-All'})
                                chanl = dc_getchans('noeyes');
                            end
                            
                            if isequal(chanh,{'Reinhart-All'})
                                chanh = dc_getchans('noeyes');
                            end
                            
                            
                            
                            freqlow = Current{3};
                            freqhigh = Current{4};
                            conntype = Current{5};
                            
                            if ischar(chanl)
                                chanl = {chanl};
                            end
                            
                            if ischar(chanh)
                                chanh = {chanh};
                            end
                            
                            if ischar(freqlow)
                                freqlow = {freqlow};
                            end
                            
                            if ischar(freqhigh)
                                freqhigh = {freqhigh};
                            end
                            
                            if ischar(conntype)
                                conntype = {conntype};
                            end
                            
                            if isequal(chanl,chanh)
                                chancmb = [chanl; chanh]';
                            else
                                chancmb = [chanl chanh];
                                
                                if size(chancmb,2) ~= 1
                                chancmb = chancmb(combvec(1:length(chanl),[1:length(chanh)]+length(chanl)))';
                                end
                            end
                            
                            if isequal(freqlow,freqhigh)
                                freqcmb = [freqlow; freqhigh]';
                            else
                                freqcmb = [freqlow freqhigh];
                                freqcmb = freqcmb(combvec(1:length(freqlow),[1:length(freqhigh)]+length(freqlow)))';
                            end
                            
                            if isequal(size(freqcmb), [2 1])
                                freqcmb = freqcmb';
                            end
                            
                            for choicmb = 1:size(chancmb, 1)
                                
                                for foicmb = 1:size(freqcmb,1)
                                    
                                    for conoi = 1:length(conntype)
                                        
                                        LF = dc_findfreq(freqcmb(foicmb,1));
                                        HF = dc_findfreq(freqcmb(foicmb,2));
                                        
                                        %lcfg.latency = params.toi;
                                        lcfg.frequency = minmax(Fourier.freq(LF(1) <= Fourier.freq & LF(2) >= Fourier.freq));
                                        lcfg.channel = chancmb(choicmb,1);
                                        evalc('datalow = ft_selectdata(lcfg,Fourier)');
                                        freqs = datalow.freq;
                                        labels = datalow.label;
                                        
                                        cfg.resamplefs = Deci.Analysis.Connectivity.Params{funs}{:}.DownSample;
                                        evalc('datalow = ft_resampledata(cfg,datalow)');
                                        datalow.fourierspctrm = permute(cell2mat(permute(datalow.trial,[3 1 2])),[3 4 1 2]);
                                        datalow.freq = freqs;
                                        datalow.time = datalow.time{1};
                                        datalow.label = labels;
                                        datalow.dimord = 'rpttap_chan_freq_time';
                                        
                                        %hcfg.latency = params.toi;
                                        hcfg.frequency = minmax(Fourier.freq(HF(1) <= Fourier.freq & HF(2) >= Fourier.freq));
                                        hcfg.channel = chancmb(choicmb,2);
                                        evalc('datahigh = ft_selectdata(hcfg,Fourier)');
                                        freqs = datahigh.freq;
                                        labels = datahigh.label;
                                        
                                        cfg.resamplefs = Deci.Analysis.Connectivity.Params{funs}{:}.DownSample;
                                        evalc('datahigh = ft_resampledata(cfg,datahigh)');
                                        datahigh.fourierspctrm = permute(cell2mat(permute(datahigh.trial,[3 1 2])),[3 4 1 2]);
                                        datahigh.freq = freqs;
                                        datahigh.time = datahigh.time{1};
                                        datahigh.label = labels;
                                        datahigh.dimord = 'rpttap_chan_freq_time';
                                        
                                        if isequal(LF,HF) && ~isequal(chancmb(choicmb,1),chancmb(choicmb,2)) && ismember(conntype(conoi),{'plv','wpli_debiased','wpli','amplcorr', 'psi', 'powcorr','coh','powcorr_ortho'})
                                            
                                            conndata = ft_appendfreq(struct('parameter','fourierspctrm','appenddim','chan'),datalow,datahigh);
                                            conndata.cumtapcnt = Fourier.cumtapcnt;
                                            
                                            conncfg.method = conntype{conoi};
                                            conncfg.channelcmb = chancmb(choicmb,:);
                                            Deci.Analysis.Connectivity = Exist(Deci.Analysis.Connectivity, 'keeptrials','no');
                                            conncfg.keeptrials = Deci.Analysis.Connectivity.keeptrials;
                                            
                                            if ismember(conntype(conoi),{'coh'})
                                               conncfg.complex     = 'imag';
                                            else
                                                conncfg.complex     = 'abs';
                                            end
                                            
                                            if ismember(conntype(conoi),{'powcorr_ortho'})
                                            scfg.latency     = Deci.Analysis.Connectivity.toi;
                                            scfg.avgovertime = 'yes';
                                            
                                            conndata = ft_selectdata(scfg,conndata);
                                            conndata.dimord = 'rpttap_chan_freq';
                                            end
                                            
                                            evalc('conn = ft_connectivityanalysis(conncfg,conndata)');
                                            
                                            if ismember({'chancmb'},strsplit(conn.dimord,'_'))
                                            conn.([conntype{conoi} 'spctrm']) = permute(conn.([conntype{conoi} 'spctrm']),[2 3 1]);
                                            else
                                            conn.([conntype{conoi} 'spctrm']) = permute(conn.([conntype{conoi} 'spctrm'])(1,2,:,:),[3 4 1 2]);    
                                            end
                                            
                                            conn.dimord = 'freq_time';
                                            
                                            
                                            
                                            if Deci.Analysis.Connectivity.Zscore.do
                                                
                                                zdata = [];
                                                
                                                tic;
                                                for s = 1:Deci.Analysis.Connectivity.Zscore.Runs
                                                    datahigh.fourierspctrm = datahigh.fourierspctrm(randperm(size(datahigh.fourierspctrm,1)),:,:,:);
                                                    
                                                    conndata = ft_appendfreq(struct('parameter','fourierspctrm','appenddim','chan'),datalow,datahigh);
                                                    conndata.cumtapcnt = Fourier.cumtapcnt(:,LF(1) <= Fourier.freq & LF(2) >= Fourier.freq);
                                                    
                                                    conncfg.method = conntype{conoi};
                                                    conncfg.channelcmb = chancmb(choicmb,:);
                                                    evalc('surr = ft_connectivityanalysis(conncfg,conndata)');
                                                    
                                                    zdata(s,:,:) = surr.([conntype{conoi} 'spctrm']);
                                                    
                                                end
                                                
                                                disp(['Finished Zscore in ' num2str(toc) 's']);
                                                clear surr
                                                
                                                % z-score
                                                pscore = [];
                                                for f = 1:size(zdata,2)
                                                    for dim3 = 1:size(zdata,3)
                                                        pscore(f,dim3) = (conn.([conntype{conoi} 'spctrm'])(f, dim3) - mean(zdata(:,f, dim3),1)) ./ std(zdata(:,f, dim3),[],1);
                                                    end
                                                end
                                                
                                                conn.([conntype{conoi} 'spctrm']) = normcdf(-abs(pscore), 0, 1) .* 2; % p-value from z-score
                                                
                                            end
                                            
                                            
                                            conn.trllength = trllength;
                                            conn.lockers = lockers;
                                            
                                            
                                            mkdir([Deci.Folder.Analysis filesep 'Extra' filesep 'Conn' filesep Deci.SubjectList{info.subject_list} filesep Deci.Analysis.LocksTitle{info.Lock} filesep Deci.Analysis.CondTitle{info.Cond}]);
                                            save([Deci.Folder.Analysis filesep 'Extra' filesep 'Conn' filesep Deci.SubjectList{info.subject_list} filesep Deci.Analysis.LocksTitle{info.Lock} filesep Deci.Analysis.CondTitle{info.Cond} filesep strjoin([chancmb(choicmb,:) freqcmb(foicmb,:) conntype(conoi)],'_')],'conn','-v7.3');
                                            clear conn
                                            
                                        elseif ~isequal(LF,HF) && isequal(chancmb(choicmb,1),chancmb(choicmb,2)) && ismember(conntype(conoi),{'mi','erpac','mvl','nmcoupling'})
                                            
                                            if isequal(conntype{conoi},'nmcoupling')
                                                conncfg.method = 'plv';
                                            else
                                                conncfg.method = conntype{conoi};
                                            end
                                            
                                            Deci.Analysis.Connectivity = Exist(Deci.Analysis.Connectivity, 'keeptrials','no');
                                            conncfg.keeptrials = Deci.Analysis.Connectivity.keeptrials;
                                            
                                            evalc('conn = ft_crossfrequencyanalysis(conncfg,datalow,datahigh)');
                                            
                                            conn.crsspctrm = permute(conn.crsspctrm,[2 3 4 1]);
                                            conn.dimord = conn.dimord(6:end);
                                            
                                            if Deci.Analysis.Connectivity.Zscore.do
                                                
                                                zdata = [];
                                                for s = 1:Deci.Analysis.Connectivity.Zscore.Runs
                                                    
                                                    datahigh.fourierspctrm = datahigh.fourierspctrm(randperm(size(datahigh.fourierspctrm,1)),:,:,:);
                                                    
                                                    evalc('surr = ft_crossfrequencyanalysis(conncfg,datalow,datahigh)');
                                                    
                                                    zdata(s,:,:,:) = surr.crsspctrm;
                                                end
                                                clear surr
                                                
                                                % z-score
                                                pscore = conn.crsspctrm;  %edited by JC 4/29/20 to accomodate mi without time var
                                                
                                                for dim1 = 1:size(conn.crsspctrm,1)
                                                    for dim2 = 1:size(conn.crsspctrm,2)
                                                        
                                                        if size(conn.crsspctrm,3) == 1
                                                           pscore(dim1,dim2) = (conn.crsspctrm(dim1,dim2) - mean(zdata(:,:,dim1,dim2),1)) ./ std(zdata(:,:,dim1, dim2),[],1);
                                                                       
                                                        else
                                                            
                                                            for dim3 = 1:size(conn.crsspctrm,3)
                                                                
                                                                if size(conn.crsspctrm,4) > 1
                                                                    for dim4 = 1:size(conn.crsspctrm,4)
                                                                        pscore(dim1,dim2,dim3,dim4) = (conn.crsspctrm(dim1,dim2) - mean(zdata(:,:,dim1,dim2),1)) ./ std(zdata(:,:,dim1, dim2),[],1);
                                                                        
                                                                    end
                                                                    
                                                                else
                                                                    pscore(dim1,dim2,dim3) = (conn.crsspctrm(dim1,dim2,dim3) - mean(zdata(:,dim1,dim2,dim3),1)) ./ std(zdata(:,dim1,dim2, dim3),[],1);
                                                                    
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                                
                                                conn.crsspctrm = normcdf(-abs(pscore), 0, 1) .* 2; % p-value from z-score
                                            
                                            end
                                            
                                            conn.trllength = trllength;
                                            conn.lockers = lockers;
                                            
                                            mkdir([Deci.Folder.Analysis filesep 'Extra' filesep 'Conn' filesep Deci.SubjectList{info.subject_list} filesep Deci.Analysis.LocksTitle{info.Lock} filesep Deci.Analysis.CondTitle{info.Cond}]);
                                            save([Deci.Folder.Analysis filesep 'Extra' filesep 'Conn' filesep Deci.SubjectList{info.subject_list} filesep Deci.Analysis.LocksTitle{info.Lock} filesep Deci.Analysis.CondTitle{info.Cond} filesep strjoin([chancmb(choicmb,:) freqcmb(foicmb,:) conntype(conoi)],'_')],'conn','-v7.3');
                                            clear conn
                                        else
                                            continue;
                                            %error('parameters for connectivity cannot be computed.')
                                        end
                                        
                                        %                                         %lcfg.latency = params.toi;
                                        %                                         lcfg.frequency = minmax(Fourier.freq(LF(1) <= Fourier.freq & LF(2) >= Fourier.freq));
                                        %                                         lcfg.channel = chancmb(choicmb,1);
                                        %                                         evalc('datalow = ft_selectdata(lcfg,Fourier)');
                                        %                                         freqs = datalow.freq;
                                        %                                         labels = datalow.label;
                                        %
                                        %                                         cfg.resamplefs = Deci.Analysis.Connectivity.Params{funs}{:}.DownSample;
                                        %                                         evalc('datalow = ft_resampledata(cfg,datalow)');
                                        %                                         datalow.fourierspctrm = permute(cell2mat(permute(datalow.trial,[3 1 2])),[3 4 1 2]);
                                        %                                         datalow.freq = freqs;
                                        %                                         datalow.time = datalow.time{1};
                                        %                                         datalow.label = labels;
                                        %                                         datalow.dimord = 'rpt_chan_freq_time';
                                        %
                                        %                                         %hcfg.latency = params.toi;
                                        %                                         hcfg.frequency = minmax(Fourier.freq(HF(1) <= Fourier.freq & HF(2) >= Fourier.freq));
                                        %                                         hcfg.channel = chancmb(choicmb,2);
                                        %                                         evalc('datahigh = ft_selectdata(hcfg,Fourier)');
                                        %                                         freqs = datahigh.freq;
                                        %                                         labels = datahigh.label;
                                        %
                                        %                                         cfg.resamplefs = Deci.Analysis.Connectivity.Params{funs}{:}.DownSample;
                                        %                                         evalc('datahigh = ft_resampledata(cfg,datahigh)');
                                        %                                         datahigh.fourierspctrm = permute(cell2mat(permute(datahigh.trial,[3 1 2])),[3 4 1 2]);
                                        %                                         datahigh.freq = freqs;
                                        %                                         datahigh.time = datahigh.time{1};
                                        %                                         datahigh.label = labels;
                                        %                                         datahigh.dimord = 'rpt_chan_freq_time';
                                        %
                                        %                                         Deci.Analysis.Connectivity.Params{funs}{:}.Current = [chancmb(choicmb,:) freqcmb(foicmb,:) conntype(conoi)];
                                        %
                                        %                                         time_window = Deci.Analysis.Connectivity.Params{funs}{:}.window; %linspace(1.5,3.5,length(Deci.Analysis.Freq.foi));
                                        %                                         Deci.Analysis.Connectivity.Params{funs}{:}.time_window = time_window(ismember(Fourier.freq,datalow.freq));
                                        %
                                        %                                         Deci.Analysis.Connectivity.Params{funs}{1}.SaveDir = strjoin([chancmb(choicmb,:) freqcmb(foicmb,:) conntype(conoi)],'_');
                                        %
                                        %                                         feval(Deci.Analysis.Connectivity.Functions{funs},Deci,info,datalow,datahigh,Deci.Analysis.Connectivity.Params{funs}{:});
                                    end
                                end
                            end
                        end
                    end
                end
                
            end
            
            if Deci.Analysis.Source.do
                for funs = find(Deci.Analysis.Source.list)
                    
                    switch Deci.Analysis.Source.Params{funs}{:}.datatype
                        case 'time'
                            input = dat;
                        case 'freq'
                            input = Fourier;
                    end
                    feval(Deci.Analysis.Source.Functions{funs},Deci,info,input,Deci.Analysis.Source.Params{funs}{:});
                end
            end
            
            clear Fourier
        end
    end
end
end


