function Deci_Corr(Deci,params)
%% Load Data

if isequal(params.Channel,'all')
    params.Channel = [{'AF3'  } {'AF4'  } {'AF7'  } ...
        {'AF8'  } {'AFz'  } {'C1'   } {'C2'   } {'C3'   } {'C4'   } {'C5'   } ...
        {'C6'   } {'CP1'  } {'CP2'  } {'CP3'  } {'CP4'  } {'CP5'  } {'CP6'  } ...
        {'CPz'  } {'Cz'   } {'F1'   } {'F2'   } {'F3'   } {'F4'   } {'F5'   } ...
        {'F6'   } {'F7'   } {'F8'   } {'FC1'  } {'FC2'  } {'FC3'  } {'FC4'  } ...
        {'FC5'  } {'FC6'  } {'FCz'  } {'FT7'  } {'FT8'  } {'Fz'   } {'O1'   } ...
        {'O2'   } {'Oz'   } {'P1'   } {'P2'   } {'P3'   } {'P4'   } {'P5'   } ...
        {'P6'   } {'P7'   } {'P8'   } {'PO3'  } {'PO4'  } {'PO7'  } {'PO8'  } ...
        {'POz'  } {'Pz'   } {'T7'   } {'T8'   } {'TP10' } {'TP7'  } {'TP8'  } ...
        {'TP9'  } ] ;
end


for subject_list = 1:length(Deci.SubjectList)
    for Conditions = 1:length(Deci.Plot.CondTitle)
        switch params.Freq
            case 'Magnitude'
                for Channel = 1:length(params.Channel)
                    load([Deci.Folder.Analysis filesep 'Extra' filesep 'Simp' filesep 'Mag' filesep Deci.SubjectList{subject_list}  filesep Deci.Plot.Lock filesep Deci.Plot.CondTitle{Conditions} filesep params.Channel{Channel}], 'Mag')
                    
                    Corr{Channel} = Mag;
                end
                
            case 'Phase'
                for Channel = 1:length(params.Channel)
                    load([Deci.Folder.Analysis filesep 'Extra' filesep 'Simp' filesep 'Pha' filesep Deci.SubjectList{subject_list}  filesep Deci.Plot.Lock filesep Deci.Plot.CondTitle{Conditions} filesep params.Channel{Channel} ], 'Pha')
                    Corr{Channel} = Pha;
                end
        end
        
        acfg.parameter = 'powspctrm';
        acfg.appenddim = 'chan';
        Subjects{subject_list,Conditions} = rmfield(ft_appendfreq(acfg,Corr{:}),'cfg');
        
    end
    
end

%% BSL
for Conditions = 1:size(Subjects,2)
    for subject_list = 1:size(Subjects,1)
        
        if ~strcmpi(Deci.Plot.BslRef,Deci.Plot.Lock)
            
            switch params.Freq
                case 'Magnitude'
                    for Channel = 1:length(params.Channel)
                        load([Deci.Folder.Analysis filesep 'Extra' filesep 'Simp' filesep 'Mag' filesep Deci.SubjectList{subject_list}  filesep Deci.Plot.BslRef filesep Deci.Plot.CondTitle{Conditions} filesep params.Channel{Channel}], 'Mag')
                        
                        BCorr{Channel} = Mag;
                    end
                    
                case 'Phase'
                    for Channel = 1:length(params.Channel)
                        load([Deci.Folder.Analysis filesep 'Extra' filesep 'Simp' filesep 'Pha' filesep Deci.SubjectList{subject_list}  filesep Deci.Plot.BslRef filesep Deci.Plot.CondTitle{Conditions} filesep params.Channel{Channel}], 'Pha')
                        BCorr{Channel} = Pha;
                    end
            end
            
            acfg.parameter = 'powspctrm';
            acfg.appenddim = 'chan';
            Bsl{subject_list,Conditions} = rmfield(ft_appendfreq(acfg,BCorr{:}),'cfg');
            
            ccfg.latency = Deci.Plot.Freq.Bsl;
            ccfg.avgovertime = 'yes';
            
            toi1 = round(Bsl{subject_list,Conditions}.time,4) >= Deci.Plot.Freq.Bsl(1) & round(Bsl{subject_list,Conditions}.time,4) <= Deci.Plot.Freq.Bsl(2);
            
            Bsl{subject_list,Conditions}.powspctrm =  Bsl{subject_list,Conditions}.powspctrm(:,:,:,toi1);
            Bsl{subject_list,Conditions}.time = Bsl{subject_list,Conditions}.time(toi1);
            bsl = ft_selectdata(ccfg, Bsl{subject_list,Conditions});
            bsl = repmat(bsl.powspctrm,[1 1 1 size(Subjects{subject_list,Conditions}.powspctrm ,4)]);
            
        else
            ccfg.latency = Deci.Plot.Freq.Bsl;
            ccfg.avgovertime = 'yes';
            
            toi1 = round(Subjects{subject_list,Conditions}.time,4) >= Deci.Plot.Freq.Bsl(1) & round(Subjects{subject_list,Conditions}.time,4) <= Deci.Plot.Freq.Bsl(2);
            Bsl{subject_list,Conditions} =Subjects{subject_list,Conditions};
            Bsl{subject_list,Conditions}.powspctrm =  Bsl{subject_list,Conditions}.powspctrm(:,:,:,toi1);
            Bsl{subject_list,Conditions}.time = Bsl{subject_list,Conditions}.time(toi1);
            bsl = ft_selectdata(ccfg, Bsl{subject_list,Conditions});
            bsl = repmat(bsl.powspctrm,[1 1 1 size(Subjects{subject_list,Conditions}.powspctrm ,4)]);
        end
        
        
        switch Deci.Plot.Freq.BslType
            case 'none'
                
            case 'absolute'
                Subjects{subject_list,Conditions}.powspctrm =  Subjects{subject_list,Conditions}.powspctrm - bsl;
            case 'relative'
                Subjects{subject_list,Conditions}.powspctrm=  Subjects{subject_list,Conditions}.powspctrm ./ bsl;
            case 'relchange'
                Subjects{subject_list,Conditions}.powspctrm = ( Subjects{subject_list,Conditions}.powspctrm - bsl) ./ bsl;
            case 'db'
                Subjects{subject_list,Conditions}.powspctrm = 10*log10( Subjects{subject_list,Conditions}.powspctrm ./ bsl);
        end
    end
end


%%

for Var = 1:length(params.Variable)
    for Conditions = 1:length(Deci.Plot.CondTitle)
        for subject_list = 1:length(Deci.SubjectList)
            
            
            
            
            Variable = load([Deci.Folder.Analysis filesep 'Extra' filesep params.Variable{Var} filesep Deci.SubjectList{subject_list} filesep Deci.Analysis.CondTitle{Conditions}],params.Variable{Var});
            
            Type = fieldnames(Variable);
            
            if length(Variable.(Type{1})) ~= size(Subjects{subject_list,Conditions}.powspctrm,1)
                
                corrs = 1:length(Variable.(Type{1}));
                
                if iscell(Variable.(Type{1}))
                    
                    if length(Variable.(Type{1}){1}) ~= size(Subjects{subject_list,Conditions}.powspctrm,1)
                        error('mismatch in trial count with Extra parameter')
                    end
                    
                end
                
                if isfield(params,'Varnum')
                    
                    corrs = params.Varnum;
                end
                
            else
                
                corrs = 1;
            end
            
            if iscell(Variable.(Type{1}))
                parameter = Variable.(Type{1}){corrs};
            else
                parameter = Variable.(Type{1});
            end
            
            parameter = zscore(parameter);
            
            R = [];
            P = [];
            Beta = [];
            
            for fois = 1:length(Subjects{subject_list,Conditions}.freq)
                for tois = 1:length(Subjects{subject_list,Conditions}.time)
                    for chns = 1:length(Subjects{subject_list,Conditions}.label)
                        switch params.Freq
                            
                            case 'Magnitude'
                                
                                [r,p] = corrcoef(zscore(Subjects{subject_list,Conditions}.powspctrm(:,chns,fois,tois)),parameter);
                                
                                R(chns,fois,tois) = r(1,2);
                                P(chns,fois,tois) = p(1,2);
                                
                                if params.Regression
                                    LM = fitlm(parameter,zscore(Subjects{subject_list,Conditions}.powspctrm(:,chns,fois,tois))');
                                    Beta(chns,fois,tois) = LM.Coefficients.Estimate(2);
                                end
                                
                            case 'Phase'
                                [R(chns,fois,tois),P(chns,fois,tois)] =  circ_corrcl(Subjects{subject_list,Conditions}.powspctrm(:,chns,fois,tois), parameter);
                                
                                if params.Regression
                                    LM = CircularRegression(parameter,Subjects{subject_list,Conditions}.powspctrm(:,chns,fois,tois));
                                    Beta(chns,fois,tois) = LM(2);
                                end
                        end
                    end
                end
            end
            
            extracorr.label = Subjects{subject_list,Conditions}.label;
            extracorr.freq = Subjects{subject_list,Conditions}.freq;
            extracorr.time = Subjects{subject_list,Conditions}.time;
            extracorr.dimord =  'chan_freq_time';
            
            extracorr.powspctrm = R;
            R = extracorr;
            
            RSub{subject_list,Conditions,Var}= R;
            
            extracorr.powspctrm = P;
            P = extracorr;
            
            if params.Regression
                extracorr.powspctrm = Beta;
                Beta = extracorr;
            end
            
            mkdir([Deci.Folder.Analysis filesep 'Extra' filesep 'Corr' filesep params.Freq '_' Type{1} filesep Deci.SubjectList{subject_list}  filesep   Deci.Plot.BslRef '_' Deci.Plot.Lock])
            save([Deci.Folder.Analysis filesep 'Extra' filesep 'Corr' filesep params.Freq '_' Type{1} filesep Deci.SubjectList{subject_list}  filesep   Deci.Plot.BslRef '_' Deci.Plot.Lock filesep Deci.Analysis.CondTitle{Conditions}],'R','P','Beta');
            
            
        end
        RVar{Conditions,Var} = rmfield(ft_freqgrandaverage(struct('parameter','powspctrm','keepindividual','yes'),RSub{:,Conditions,Var}),'cfg');
        
    end
end

for param = 1:size(RVar,2)
    
    RCond = RVar(:,param)';
    
    %%
    
    if ~isempty(Deci.Plot.Math)
        for conds = 1:length(Deci.Plot.Math)
            scfg.parameter = 'powspctrm';
            scfg.operation = Deci.Plot.Math{conds};
            MathData = ft_math(scfg,RCond{:});
            RCond{size(RCond,2)+1} = MathData;
        end
    end
    
    %% stats
    neighbours       = load('easycap_neighbours','neighbours');
    Deci.Plot.Stat.neighbours = neighbours.neighbours;
    Deci.Plot.Stat.ivar = 1;
    Deci.Plot.Stat.uvar = 2;
    Deci.Plot.Stat.tail = 1;
    Deci.Plot.Stat.statistic = 'depsamplesFmultivariate';
    
    for conds = 1:length(Deci.Plot.Draw)
        design = [];
        
        for subcond = 1:length(Deci.Plot.Draw{conds})
            for subj = 1:length(Deci.SubjectList)
                design(1,subj+length(Deci.SubjectList)*[subcond-1]) =  subcond;
                design(2,subj+length(Deci.SubjectList)*[subcond-1]) = subj;
            end
            
        end
        
        Deci.Plot.Stat.design = design;
        
        [RCondStat{conds}] = ft_freqstatistics(Deci.Plot.Stat, RCond{Deci.Plot.Draw{conds}});
        RCondStat{conds}.mask = double(RCondStat{conds}.mask);
        RCondStat{conds}.mask(RCondStat{conds}.mask == 0) = .2;
        
    end
    
    for subcond = 1:size(RCond,2)
        RCond{subcond}.powspctrm = squeeze(nanmean(RCond{subcond}.powspctrm));
        RCond{subcond}.dimord = 'chan_freq_time';
    end
    
    %% draw
    
    for cond = 1:length(Deci.Plot.Draw)
        
        for subj = 1:size(RCond,1)
            
            if params.Square
                Corrsquare(subj) = figure;
                suptitle([Deci.Plot.Title{cond} ' '  params.Freq '_' params.Variable{param}]);
                
                ButtonH=uicontrol('Parent', Corrsquare(subj),'Style','pushbutton','String','p Mask','Position',[10 75 45 25],'Visible','on','Callback',@pmask);
                ButtonH.UserData = @ones;
            end
            
            % Topo plot with lines for connections, Time has a Dial
            if params.Topo
                Corrtopo(subj)  = figure;
                suptitle([Deci.Plot.Title{cond} ' '  params.Freq '_' params.Variable{param}]);
                
                ButtonH=uicontrol('Parent', Corrtopo(subj),'Style','pushbutton','String','p Mask','Position',[10 75 45 25],'Visible','on','Callback',@pmask);
                ButtonH.UserData = @ones;
            end
            
            
            for subcond = 1:length(Deci.Plot.Draw{cond})
                
                
                RCond{subcond}.mask = RCondStat{cond}.mask;
                
                
                if params.Topo
                    set(0, 'CurrentFigure', Corrtopo(subj) )
                    Corrtopo(subj).Visible = 'on';
                    
                    ctopo(subj,subcond)    =  subplot(length(Deci.Plot.Draw{cond}),1,subcond);
                    
                    Crosscfg =[];
                    Crosscfg.layout = Deci.Layout.Noeye;
                    Crosscfg.toi = 1;
                    Crosscfg.foi = 1;
                    
                    title([Deci.SubjectList{subj} ' Cond '  num2str(cond)],'Interpreter', 'none');
                    
                    %RCond{subj,subcond}.mask = ft_selectdata(struct('latency',RCond{subj,subcond}.time(1),'frequency',RCond{subj,subcond}.freq(1)),PCond{subj,subcond});
                    %RCond{subj,subcond}.mask = RCond{subj,subcond}.mask.powspctrm;
                    
                    Crosscfg.clim = 'maxmin';
                    Crosscfg.maskparameter ='mask';
                    
                    ft_topoplotER(Crosscfg,ft_selectdata(struct('latency',RCond{subj,subcond}.time(1),'frequency',RCond{subj,subcond}.freq(1)),RCond{subj,subcond}));
                    ctopo(subj,subcond).UserData = {RCond{subj,subcond},Crosscfg};
                end
                
                if params.Square
                    
                    set(0, 'CurrentFigure', Corrsquare(subj) )
                    Corrsquare(subj).Visible = 'on';
                    csquare(subj,subcond)    =  subplot(length(Deci.Plot.Draw{cond}),1,subcond);
                    
                    Crosscfg =[];
                    Crosscfg.layout = Deci.Layout.Noeye;
                    Crosscfg.choi = 1;
                    
                    Crosscfg.clim = 'maxmin';
                    Crosscfg.maskparameter ='mask';
                    
                    title([Deci.SubjectList{subj} ' Cond '  num2str(cond)],'Interpreter', 'none');
                    
                    ft_singleplotTFR(Crosscfg,ft_selectdata(struct('channel',RCond{subj,subcond}.label(1)),RCond{subj,subcond}));
                    
                    csquare(subj,subcond).UserData = {RCond{subj,subcond},Crosscfg};
                    colorbar;
                end
                
            end
            
            
            if params.Topo
                
                set(0, 'CurrentFigure', Corrtopo(subj) )
                
                text = uicontrol('style','text','position',[225 75 100 25],'String',['Time of Interest: '  num2str(RCond{subj,subcond}.time(1))]);
                uicontrol('style','pushbutton','position',[175 75 45 25],'String','<','callback',{@ChangeDim,ctopo(subj,:),-1,'toi',text,'Time of Interest: ','Topo',params.Freq })
                uicontrol('style','pushbutton','position',[325 75 45 25],'String','>','callback',{@ChangeDim,ctopo(subj,:),+1,'toi',text,'Time of Interest: ','Topo',params.Freq})
                
                
                text = uicontrol('style','text','position',[225+100+25+50+50 75 100 25],'String',['Freq of Interest: '  num2str(RCond{subj,subcond}.freq(1))]);
                uicontrol('style','pushbutton','position',[175+100+25+50+50 75 45 25],'String','<','callback',{@ChangeDim,ctopo(subj,:),-1,'foi',text,'Freq of Interest: ','Topo',params.Freq})
                uicontrol('style','pushbutton','position',[325+100+25+50+50 75 45 25],'String','>','callback',{@ChangeDim,ctopo(subj,:),+1,'foi',text,'Freq of Interest: ','Topo',params.Freq})
                
                ChangeDim([],[],ctopo(subj,:),-1,'toi',text,'Time of Interest: ','Topo',params.Freq)
            end
            
            
            if params.Square
                
                set(0, 'CurrentFigure', Corrsquare(subj) )
                text = uicontrol('style','pushbutton','position',[225 75 125 25],'String',['Channel of Interest: '  RCond{subj,subcond}.label{1}],'callback',{@ChangeDim,csquare(subj,:),0,'choi',text,'Channel of Interest: ','Square',params.Freq});
                
                ChangeDim([],[],csquare(subj,:),0,'choi',text,'Channel of Interest: ','Square',params.Freq)
            end
            
        end
        
    end
    
end

    function ChangeDim(popup,event,Axes,Change,Dim,TextUI,Text,Type,FreqType)
        
        if strcmpi(Dim,'choi')
            if ~isempty(popup)
                fakeUI = figure;
                fakeUI.UserData = Axes(1).UserData{1}.label(Axes(1).UserData{2}.choi);
                fakeUI.Visible =  'off';
                select_labels(fakeUI,[],Axes(1).UserData{1}.label);
                waitfor(findall(0,'Name','Select Labels'),'BeingDeleted','on');
                choi = find(ismember(Axes(1).UserData{1}.label,fakeUI.UserData));
                close(fakeUI);
            else
                choi = 1;
            end
            
        end
        
        for Axe =  1:length(Axes)
            set(0, 'CurrentFigure', Axes(Axe).Parent )
            set(Axes(Axe).Parent, 'currentaxes', Axes(Axe))
            
            NewCrossCfg = Axes(Axe).UserData{2};
            
            switch Dim
                
                case 'toi'
                    NewCrossCfg.toi = NewCrossCfg.toi + Change;
                    if NewCrossCfg.toi < 1 || NewCrossCfg.toi > length(Axes(Axe).UserData{1}.time)
                        break
                    end
                    Axes(Axe).UserData{2}.toi = Axes(Axe).UserData{2}.toi + Change;
                    TextUI.String = [Text num2str(Axes(Axe).UserData{1}.time(NewCrossCfg.toi) )];
                    
                    
                case 'foi'
                    NewCrossCfg.foi = NewCrossCfg.foi + Change;
                    if NewCrossCfg.foi < 1 || NewCrossCfg.foi > length(Axes(Axe).UserData{1}.freq)
                        break
                    end
                    Axes(Axe).UserData{2}.foi = Axes(Axe).UserData{2}.foi + Change;
                    TextUI.String = [Text num2str(Axes(Axe).UserData{1}.freq(NewCrossCfg.foi) )];
                case 'choi'
                    NewCrossCfg.choi = choi;
                    Axes(Axe).UserData{2}.choi = NewCrossCfg.choi;
                    popup.String = [Text Axes(Axe).UserData{1}.label{NewCrossCfg.choi}];
            end
            
            switch Type
                case 'Topo'
                    ft_topoplotTFR(NewCrossCfg,ft_selectdata(struct('latency',Axes(Axe).UserData{1}.time(NewCrossCfg.toi),'frequency',Axes(Axe).UserData{1}.freq(NewCrossCfg.foi)),Axes(Axe).UserData{1}));
                case 'Square'
                    ft_singleplotTFR(NewCrossCfg,ft_selectdata(struct('channel',Axes(Axe).UserData{1}.label(NewCrossCfg.choi)),Axes(Axe).UserData{1}));
            end
        end
        
        for Axe =  1:length(Axes)
            
            switch Type
                case 'Topo'
                    
                    if strcmpi(FreqType,'Magnitude')
                        Axes(Axe).CLim = [-1*max(arrayfun(@(c) nanmax(nanmax(abs(c.Children(end).CData))),Axes,'UniformOutput',1)) max(arrayfun(@(c) nanmax(nanmax(abs(c.Children(end).CData))),Axes,'UniformOutput',1))];
                    else
                        Axes(Axe).CLim = [0 max(arrayfun(@(c) nanmax(nanmax(abs(c.Children(end).CData))),Axes,'UniformOutput',1))];
                    end
                    
                case 'Square'
                    if strcmpi(FreqType,'Magnitude')
                        Axes(Axe).CLim = [-1*max(arrayfun(@(c) nanmax(nanmax(abs(c.Children.CData))),Axes,'UniformOutput',1)) max(arrayfun(@(c) nanmax(nanmax(abs(c.Children.CData))),Axes,'UniformOutput',1)) ];
                    else
                        Axes(Axe).CLim = [0  max(arrayfun(@(c) nanmax(nanmax(abs(c.Children.CData))),Axes,'UniformOutput',1)) ];
                    end
                    
            end
            
            
        end
        
    end

    function pmask(PushButton, EventData)
        
        Axes = PushButton.Parent.Children.findobj('Type','Axes');
        Axes = Axes(arrayfun(@(c) ~isempty(c.String), [Axes.Title]));
        
        for a = 1:length(Axes)
            
            imag = Axes(a).Children.findobj('Type','Image');
            
            if isempty(imag)
                imag =  Axes(a).Children.findobj('Type','Surface');
                
            end
            
            if isempty(imag.UserData)
                imag.UserData = logical(~isnan(imag.CData));
            end
            
            placeholder = imag.UserData;
            imag.UserData = imag.AlphaData;
            imag.AlphaData = placeholder;
        end
    end

end