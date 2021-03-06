function Artifactor_CG(Deci)


for subject_list = 1:length(Deci.SubjectList)
    
    if Deci.Art.do
        

%% load Data
        data = [];
        cfg = [];
        load([Deci.Folder.Preproc filesep Deci.SubjectList{subject_list} '.mat']);
        
        if isfield(data,'condinfo')  
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
        
        
        
%         condinfo = data.condinfo;
%         preart   = data.preart;
%         ica = cfg;
        
%% Do ICA
        feedback = 'no';
        cfg.feedback = feedback;
        cfg.demean = 'no';
        data_ica = rmfield(ft_componentanalysis(cfg, data),'cfg');
        
        figure;
        cfg.component = [1:20];
        cfg.viewmode = 'component';
        
        clear cfg.method
        cfg.channel = 'all';
        
        cfg.component = [];
        
        comps = [data_ica.trial{:}];
        eyes = [data.trial{:}];
        eyechan = eyes(ismember(data.label,Deci.ICA.eog),:);
        
        for eye = 1:size(eyechan,1)
            for comp = 1:size(comps,1)
                [compcorr, p] = corrcoef(eyechan(eye,:),comps(comp,:));
                corr(eye,comp,1) = compcorr(1,2);
                corr(eye,comp,2) = p(1,2);
            end
            
            component{eye} = find(abs(corr(eye,:,1)) >= Deci.ICA.cutoff);
        end
        
        possiblecorrupt = max(abs(exp(zscore(cfg.unmixing'))),[],1) > 1100;
        possiblecorrupt = possiblecorrupt | [max(abs(1./exp(zscore(cfg.unmixing'))),[],1) > 1100];
        
        
        if ~Deci.ICA.Automatic
             disp('Manual ICA Rejection')
                cfg.component = [1:length(data_ica.label)];
                cfg.viewmode = 'component';
                cfg.layout    = Deci.Layout.eye; % specify the layout file that should be used for plotting
                
                cfg.channelcolormap = zeros(4,3);
                cfg.channelcolormap(3,:) = [1 0 0];
                cfg.channelcolormap(2,:) = [0 0 1];
                cfg.channelcolormap(1,:) = [1 0 1];
                
                cfg.colorgroups = ones(length(data_ica.label),1)+3;
                cfg.colorgroups(unique([component{:}]),1) = cfg.colorgroups(unique([component{:}]),1) - 1;
                cfg.colorgroups(possiblecorrupt,1) = cfg.colorgroups(possiblecorrupt,1) - 2;
                
                disp(['Found ' num2str(length(find(cfg.colorgroups == 1))) ' eye-correlated components']);
                
                cfg.channel = 'all';
                fakeUI = figure;
                select_labels(fakeUI,[],sort(cellfun(@(c)c(10:end), data_ica.label, 'un', 0)));
                fakeUI.Visible =  'off';
                evalc('ft_databrowser(cfg,data_ica)');
                suptitle(Deci.SubjectList{subject_list});
                waitfor(findall(0,'Name','Select Labels'),'BeingDeleted','on');
                
                if isempty(fakeUI.UserData)
                    cfg.component = [];
                else
                    cfg.component = find(ismember(cellfun(@(c)c(10:end),data_ica.label, 'un', 0),fakeUI.UserData));
                end
                close(fakeUI)
                corr = [];

        else
            cfg.component = unique([component{:}]);
        end
        
        cfg.demean = 'yes';
        data = ft_rejectcomponent(cfg, data_ica);
        
        
%% Interpolation
        if isfield(Deci.Art,'interp')
            Deci.Art.interp.method = 'spline';
            load('elec1010_neighb.mat','neighbours');
            Deci.Art.interp.neighbours = neighbours;
            
            
            if exist([Deci.SubjectList{subject_list} '.bvct']) == 2
                [elec.label, elec.elecpos] = CapTrakMake([Deci.Folder.Raw  filesep Deci.SubjectList{subject_list} '.bvct']);
            else
                elec = ft_read_sens('standard_1020.elc');
            end
            Deci.Art.interp.elec = elec;
            display('Laplace Interpolation Applied')
            
            nonrepairs.channel = data.label(~ismember(data.label,elec.label));
            nonrepairs = ft_selectdata(nonrepairs,data);
            [data_interp] = ft_channelrepair(Deci.Art.interp, data);
            
            data = ft_appenddata([],nonrepairs,data_interp);
        end
        
        
%% Manual Trial Rejection
        
        if Deci.Art.Manual_Trial_Rejection
            cfg =[];
            cfg.method = 'trial';
            tcfg.toilim = [abs(nanmax(locks,[],2)/1000)+Deci.Art.crittoilim(1) abs(nanmin(locks,[],2)/1000)+Deci.Art.crittoilim(2)];

            cfg.viewmode = 'vertical';
            artf = ft_databrowser(cfg,ft_redefinetrial(tcfg,data));
            
            datacomp_rej = ft_rejectartifact(artf,ft_redefinetrial(tcfg,data));
            
            postart.locks = postart.locks(ismember(postart.trlnum,find(datacomp_rej.saminfo)),:);
            postart.events = postart.events(ismember(postart.trlnum,find(datacomp_rej.saminfo)),:);
            postart.trlnum = postart.trlnum(ismember(postart.trlnum,find(datacomp_rej.saminfo)));
                      
            cfg = [];
            cfg.trials = postart.trlnum;
            data_copy = ft_selectdata(cfg,data);
            
            display(' ')
            display('---Manual Trial Rejection Applied---')
            display(['Rejected ' num2str(length(find(~logical(datacomp_rej.saminfo)))) ' trials'])
            display(' ')
            pause(.05);
            
        else
            data_copy = data;
        end

%% Artifact Reject
        cfg =[];
        cfg.method = 'summary';
        cfg.layout    = Deci.Layout.eye; % specify the layout file that should be used for plotting
        cfg.eog = Deci.Art.eog;
        cfg.keepchannel = 'yes';
        tcfg.toilim = [abs(nanmax(locks,[],2)/1000)+Deci.Art.crittoilim(1) abs(nanmin(locks,[],2)/1000)+Deci.Art.crittoilim(2)];
        cfg.channel = 'all';
        cfg.keepchannel = 'no';
        
        data_rej = ft_rejectvisual(cfg,ft_redefinetrial(tcfg,data_copy));
        
        if Deci.Art.ShowArt
            Summary_artifacts = ~data_rej.saminfo;
            SAcfg.trials = Summary_artifacts;
            SAcfg.viewmode = 'vertical';
            evalc('savedtrls = ft_databrowser(SAcfg,ft_selectdata(SAcfg,ft_redefinetrial(tcfg,data)))');
            
            evalc('datacomp_saved = ft_rejectartifact(savedtrls,ft_selectdata(SAcfg,ft_redefinetrial(tcfg,data)))');
            
            savedtrls = find(Summary_artifacts);
            savedtrls =  savedtrls(~logical(datacomp_saved.saminfo));
            Summary_artifacts(savedtrls) = 0;
            data_rej.saminfo = ~Summary_artifacts;
        end
        
        postart.locks = postart.locks(ismember(postart.trlnum,find(data_rej.saminfo)),:);
        postart.events = postart.events(ismember(postart.trlnum,find(data_rej.saminfo)),:);
        postart.trlnum = postart.trlnum(ismember(postart.trlnum,find(data_rej.saminfo)));
        
        display(' ')
        disp('---Trial Summary Rejection Applied---')
        disp(['Rejected ' num2str(length(find(~logical(data_rej.saminfo)))) ' trials'])
        display(' ')
        pause(.05);
        
        
        if ~isempty(Deci.Art.RT)
            RT_Art = [locks(:,Deci.Art.RT.locks(2)) - locks(:,Deci.Art.RT.locks(1))] < Deci.Art.RT.minlength;
            RT_Nans = isnan([locks(:,Deci.Art.RT.locks(2)) - locks(:,Deci.Art.RT.locks(1))]);
            
            postart.locks = postart.locks(ismember(postart.trlnum,trlnum(~RT_Art)),:);
            postart.events = postart.events(ismember(postart.trlnum,trlnum(~RT_Art)),:);
            postart.trlnum = postart.trlnum(ismember(postart.trlnum,trlnum(~RT_Art)));
            
            display(' ')
            disp('---Reaction Time Rejection Applied---')
            disp(['Rejected ' num2str(length(find(RT_Art))) ' trials'])
            disp(['Remaining ' num2str(length(postart.trlnum)) ' trials'])
            disp(['Remaining ' num2str([length(postart.trlnum)/length(trlnum)]*100) '% trials'])
            display(' ')
            pause(.05);
        end
        
        
%         if Deci.Art.AddComponents
%             cfg =[];
%             cfg.viewmode = 'vertical';
%             
%             scfg.trials = condinfo{3};
%             
%             data_ica     = rmfield(ft_componentanalysis(ica, data),'cfg');
%             data_comp = ft_selectdata(scfg,data_ica);
%             
%             tcfg.toilim = [abs(nanmax(condinfo{1},[],2)/1000)+Deci.Art.crittoilim(1) abs(nanmin(condinfo{1},[],2)/1000)+Deci.Art.crittoilim(2)];
%             
%             artf = ft_databrowser(cfg,ft_redefinetrial(tcfg,data_comp));
%             
%             datacomp_rej = ft_rejectartifact(artf,ft_redefinetrial(tcfg,data_comp));
%             
%             condinfo{1} = condinfo{1}(logical(datacomp_rej.saminfo),:);
%             condinfo{2} = condinfo{2}(logical(datacomp_rej.saminfo),:);
%             if length(condinfo) > 2
%                 condinfo{3} = condinfo{3}(logical(datacomp_rej.saminfo));
%             end
%         end
%         
        if ~isempty(Deci.Art.More)
            evalc('data = ft_preprocessing(Deci.Art.More,data)');
            disp('Additional Preprocessing');
        end
        
        if any(~ismember(data.label(~ismember(data.label,data_rej.label)),cfg.eog))
            rej_chan = data.label(~ismember(data.label,data_rej.label));
            interp_chan = rej_chan(~ismember(rej_chan,cfg.eog));
            
            TempDeci = Deci;
            TempDeci.Art.interp.missingchannel = interp_chan;
            TempDeci.PP.More.channel = data.label(~ismember(data.label,interp_chan));
            TempDeci.SubjectList = Deci.SubjectList(subject_list);
            TempDeci.Step = 2;
            TempDeci.Proceed = 0;
            TempDeci.PCom               = false;                                                      % Activates Parallel Computing for PP and Analysis only
            TempDeci.GCom               = false; 
            TempDeci.DCom               = false;
            
            Deci_Backend_CG(TempDeci);
            
            TempDeci.Step = 3;
            Deci_Backend_CG(TempDeci);
        else

            data.locks = locks;
            data.events = events;
            data.trlnum = trlnum;
            data.postart = postart;
            mkdir([Deci.Folder.Artifact])
            save([Deci.Folder.Artifact filesep Deci.SubjectList{subject_list}],'data','-v7.3')
            data = rmfield(data,'trial');
            %save([Deci.Folder.Artifact filesep Deci.SubjectList{subject_list} '_info'],'data','-v7.3')
        end
        
    else
        mkdir([Deci.Folder.Artifact])
        
        load([Deci.Folder.Preproc filesep Deci.SubjectList{subject_list} '.mat']);
        
        data = rmfield(rmfield(data,'unmixing'),'topolabel');
        save([Deci.Folder.Artifact filesep Deci.SubjectList{subject_list}],'data','-v7.3')
        
        
        data = [];
        load([Deci.Folder.Preproc filesep Deci.SubjectList{subject_list} '.mat']);
        data = rmfield(data,'trial');
        save([Deci.Folder.Artifact filesep Deci.SubjectList{subject_list} '_info'],'data','-v7.3')
    end
end

