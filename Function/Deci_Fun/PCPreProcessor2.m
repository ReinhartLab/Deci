function PCPreProcessor2(Deci,subject_list)

disp('----------------------');
disp(['Starting PreProcessor for ' Deci.SubjectList{subject_list}]);
tic;
feedback  = 'none';


%Load and Set-up
cfg = load([Deci.Folder.Definition filesep Deci.SubjectList{subject_list}]);
cfg = cfg.cfg;

cfg.datafile = filesyntax(cfg.datafile);
cfg.headerfile = filesyntax(cfg.headerfile);
cfg.dataset = filesyntax(cfg.dataset);

cfg.feedback = feedback;

fullcfg = rmfield(cfg,'trl');
trialcfg = cfg;
evalc('data_eeg = ft_preprocessing(fullcfg)');


if ~isempty(Deci.PP.HBP)
    cfg =[];
    cfg.hpfreq = Deci.PP.HBP;
    cfg.hpfilter      = 'yes';
    cfg.feedback = feedback;
    evalc('data_eeg = ft_preprocessing(cfg,data_eeg)');
    disp('Highbandpass Filter');
end

if ~isempty(Deci.PP.Detrend)
    cfg =[];
    cfg.detrend = 'yes';
    cfg.feedback = feedback;
    evalc('data_eeg = ft_preprocessing(cfg,data_eeg)');
    disp('Detrended');
end

cfg = [];
cfg.trl = trialcfg.trl;
evalc('data_eeg = ft_redefinetrial(cfg,data_eeg)');

condinfo = {data_eeg.trialinfo trialcfg.event trialcfg.trialnum};


if ~isempty(Deci.PP.ScalingFactor)
    disp('Data Scaled');
    data_eeg.trial = cellfun(@(c) c*Deci.PP.ScalingFactor,data_eeg.trial,'un',0);
end

if ~isempty(Deci.PP.Imp)
    Imp = strsplit(Deci.PP.Imp,':');
    
    if ~ismember(Imp{2},data_eeg.label)
        error('invalid Implicit channels for reference')
    end
    cfg = [];
    cfg.reref = 'yes';
    cfg.channel  = 'all';
    cfg.implicitref = Imp{1};
    cfg.refchannel = Imp;
    cfg.feedback = feedback;
    evalc('data_eeg = ft_preprocessing(cfg,data_eeg)');
    disp('Implicit Rereference');
end

if ~isempty(Deci.PP.Ocu)
    Ocu = cellfun(@(c) strsplit(c,':'), strsplit(Deci.PP.Ocu,','),'UniformOutput',false);
    allOcu = [Ocu{:}];
    
    cfg = [];
    
    if ~all(ismember(allOcu,data_eeg.label))
        error('invalid ocular channels for reference')
    end
    
    for i = 1:length(Ocu)
        cfg.channel = Ocu{i};
        cfg.refchannel = Ocu{i}(1);
        cfg.feedback = feedback;
        evalc('data_eog(i) = ft_preprocessing(cfg,data_eeg)');
        Hcfg.channel = Ocu{i}(2);
        cfg.feedback = feedback;
        evalc('data_eog(i)   = ft_preprocessing(Hcfg, data_eog(i))'); % nothing will be done, only the selection of the interesting channel
    end
    
    cfg.channel = [{'all'} arrayfun(@(c) strjoin(['-' c],''),allOcu,'un',0)] ;
    cfg.feedback = feedback;
    evalc('data_noeog = ft_selectdata(cfg,data_eeg)');
    
    arraydata = arrayfun(@(c) {c},[data_noeog, data_eog]);
    clear data_noeog data_eog
    cfg.feedback = feedback;
    evalc('data_eeg = ft_appenddata([],arraydata{:})');
    clear arraydata
    disp('Ocular Rereference');
end

if ~isempty(Deci.PP.Demean)
    cfg = [];
    cfg.demean = 'yes';
    cfg.baselinewindow = Deci.PP.Demean;
    cfg.feedback = feedback;
    evalc('data_eeg = ft_preprocessing(cfg,data_eeg)');
    disp('Baseline Correction');
end

if Deci.PP.CleanLabels
    
    if ~isempty( data_eeg.label(strcmp(data_eeg.label,'OL')))
        data_eeg.label(strcmp(data_eeg.label,'OL')) = {'PO7'};
    end
    if  ~isempty( data_eeg.label(strcmp(data_eeg.label,'OR')))
        data_eeg.label(strcmp(data_eeg.label,'OR')) = {'PO8'};
    end
    if ~isempty( data_eeg.label(strcmp(data_eeg.label,'T3')))
        data_eeg.label(strcmp(data_eeg.label,'T3')) = {'T7'};
    end
    if  ~isempty( data_eeg.label(strcmp(data_eeg.label,'T4')))
        data_eeg.label(strcmp(data_eeg.label,'T4')) = {'T8'};
    end
    if ~isempty( data_eeg.label(strcmp(data_eeg.label,'T5')))
        data_eeg.label(strcmp(data_eeg.label,'T5')) = {'P7'};
    end
    if  ~isempty( data_eeg.label(strcmp(data_eeg.label,'T6')))
        data_eeg.label(strcmp(data_eeg.label,'T6')) = {'P8'};
    end
    if  ~isempty( data_eeg.label(strcmp(data_eeg.label,'VEM')))
        data_eeg.label(strcmp(data_eeg.label,'VEM')) = {'BVEOG'};
    end
    if  ~isempty( data_eeg.label(strcmp(data_eeg.label,'HEM')))
        data_eeg.label(strcmp(data_eeg.label,'HEM')) = {'RHEOG'};
    end
    if  ~isempty( data_eeg.label(strcmp(data_eeg.label,'LM')))
        data_eeg.label(strcmp(data_eeg.label,'LM')) = {'TP9'};
    end
    if  ~isempty( data_eeg.label(strcmp(data_eeg.label,'RM')))
        data_eeg.label(strcmp(data_eeg.label,'RM')) = {'TP10'};
    end
    
    if  ~isempty( data_eeg.label(strcmp(data_eeg.label,'32')))
        rm32.channel = data_eeg.label(~strcmp(data_eeg.label,'32'));
        data_eeg = ft_selectdata(rm32,data_eeg);
    end
    
    
end

if ~isempty(Deci.PP.DownSample)
    data_eeg = ft_resampledata(struct('resamplefs',Deci.PP.DownSample,'detrend','no'),data_eeg);
end

if ~isempty(Deci.PP.More)
    cfg = Deci.PP.More;
    cfg.feedback = feedback;
    evalc('data_eeg = ft_preprocessing(cfg,data_eeg)');
    disp('Additional Preprocessing');
end

data = data_eeg;
data.condinfo = condinfo;

disp(['Finished PreProcessor at ' num2str(toc)]);
disp('----------------------');

    %% ICA
       disp(['Starting ICA at ' num2str(toc)]);
       
       
        if ~isempty(find(cellfun(@(c) any(any(isnan(c))), data.trial) == 1)) && Deci.Art.RejectNans
            nantrials = find(cellfun(@(c) any(any(isnan(c))), data.trial) == 1);
            
            cfg = [];
            
            cfg.trials = logical(ones([size(data.trial)]));
            cfg.trials(nantrials) = false;
            
            data = ft_selectdata(cfg,data);
            warning(['Found trial(s) containing nan in rawdata for ' Deci.SubjectList{subject_list} '. Revise Data and then use .RejectNans']);
        elseif ~isempty(find(cellfun(@(c) any(any(isnan(c))), data.trial) == 1)) && ~Deci.Art.RejectNans
            
            error(['Found trial(s) containing nan in rawdata for ' Deci.SubjectList{subject_list} '. Revise Data and then use .RejectNans']);
            
        end
        
        condinfo = data.condinfo;
        preart   = condinfo;
        cfg = [];
        
        cfg.bpfilter = 'yes';
        cfg.bpfreq = [1 30];
        data_bp = ft_preprocessing(cfg,data);

        cfg = [];
        cfg.method  = 'runica';
        cfg.numcomponent= 20;
        cfg.feedback = feedback;
        cfg.demean     = 'no';
        data_musc = ft_componentanalysis(cfg, data_bp);
        
        cfg           = [];
        cfg.numcomponent= 20;
        cfg.unmixing  =data_musc.unmixing;
        cfg.topolabel = data_musc.topolabel;
        cfg.feedback = feedback;
        cfg.demean     = 'no';
        data_muscfree     = rmfield(ft_componentanalysis(cfg, data),'cfg');
        
        figure;
        cfg.component = [1:20];
        cfg.viewmode = 'component';
        
        clear cfg.method
        cfg.channel = 'all';
        
        comps = [data_musc.trial{:}];
        eyes = [data_eeg.trial{:}];
        eyechan = eyes(ismember(data_eeg.label,allOcu),:);
        
        
        cfg.component = [];
        for eye = 1:size(eyechan,1)
            for comp = 1:size(comps,1)
                compcorr = corrcoef(eyechan(eye,:),comps(comp,:));
                corr(eye,comp) = compcorr(1,2);
            end
            
            cfg.component(eye) = find(max(corr(eye,:)) == corr(eye,:));
        end
        
        
%         for p = 1:size(pow,1)
%            pspectrum(pow(p,:),1000, 'FrequencyLimits',[0 100]);
%            hold on
%         end
%         
        cfg.demean = 'yes';
        data = ft_rejectcomponent(cfg, data_muscfree);
        
        data.condinfo = condinfo;
        data.preart = preart;
        
        data = rmfield(data,'cfg');
        
        mkdir([Deci.Folder.Artifact])
        save([Deci.Folder.Artifact filesep Deci.SubjectList{subject_list}],'data','-v7.3')
        data = rmfield(data,'trial');
        save([Deci.Folder.Artifact filesep Deci.SubjectList{subject_list} '_info'],'data','corr','-v7.3');

end